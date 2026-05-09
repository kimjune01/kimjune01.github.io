#!/bin/bash
# Complementations crawler
# Finds AI-assisted open source contributors via PR rejection comments
# Output: complementations.jsonl (deduped by GitHub username)
#
# Usage: bash scripts/complementations-crawler.sh [--resume]
# Requires: gh (authenticated), jq
#
# LLM checkpoint: the script appends to complementations-raw.jsonl as it goes.
# On --resume, it skips usernames already in the output file.

set -euo pipefail

RAW="complementations-raw.jsonl"
OUT="complementations.jsonl"
SEEN_FILE="/tmp/complementations-seen.txt"

# Search terms that indicate AI-rejection in PR comments
QUERIES=(
  '"AI slop"'
  '"do not use AI"'
  '"AI generated"'
  '"written by AI"'
  '"LLM generated"'
  '"ChatGPT"'
  '"stop with AI"'
  '"AI PR"'
  '"low quality PR" AI'
)

# Resume support: load already-seen usernames
if [[ "${1:-}" == "--resume" ]] && [[ -f "$OUT" ]]; then
  jq -r '.username' "$OUT" 2>/dev/null | sort -u > "$SEEN_FILE"
  echo "Resuming. $(wc -l < "$SEEN_FILE" | tr -d ' ') users already processed."
else
  > "$SEEN_FILE"
  echo "Starting fresh."
fi

is_seen() {
  grep -qxF "$1" "$SEEN_FILE" 2>/dev/null
}

mark_seen() {
  echo "$1" >> "$SEEN_FILE"
}

# Phase 1: Find PRs with AI-rejection language in comments
echo "Phase 1: Searching for AI-rejected PRs..."

for query in "${QUERIES[@]}"; do
  echo "  Searching: $query"

  gh search prs \
    --state closed \
    --limit 100 \
    --json repository,number,author,title,url \
    --jq '.[] | @json' \
    -- "$query in:comments" 2>/dev/null | while read -r pr_json; do

    author=$(echo "$pr_json" | jq -r '.author.login')
    repo=$(echo "$pr_json" | jq -r '.repository.nameWithOwner')
    number=$(echo "$pr_json" | jq -r '.number')
    title=$(echo "$pr_json" | jq -r '.title')
    url=$(echo "$pr_json" | jq -r '.url')

    # Skip bots
    case "$author" in
      *bot*|*Bot*|dependabot*|renovate*|github-actions*) continue ;;
    esac

    # Skip if already seen
    if is_seen "$author"; then
      continue
    fi

    echo "    Found: $author on $repo #$number"

    # Check if CI passed on this PR
    ci_status=$(gh pr view "$number" --repo "$repo" \
      --json statusCheckRollup \
      --jq '[.statusCheckRollup[]? | select(.status == "COMPLETED" and .conclusion == "SUCCESS")] | length' \
      2>/dev/null || echo "0")

    # Append raw hit
    jq -n \
      --arg author "$author" \
      --arg repo "$repo" \
      --argjson number "$number" \
      --arg title "$title" \
      --arg url "$url" \
      --argjson ci_passed "$ci_status" \
      --arg query "$query" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{ts: $ts, username: $author, repo: $repo, pr_number: $number, title: $title, url: $url, ci_checks_passed: $ci_passed, search_query: $query}' \
      >> "$RAW"

    mark_seen "$author"

    # Rate limit courtesy
    sleep 0.5

  done || true

  sleep 2
done

echo "Phase 1 complete. $(wc -l < "$RAW" | tr -d ' ') raw hits."

# Phase 2: Enrich each unique author with profile + contribution breadth
echo "Phase 2: Enriching author profiles..."

jq -r '.username' "$RAW" | sort -u | while read -r username; do

  # Skip if already in final output
  if [[ -f "$OUT" ]] && jq -e --arg u "$username" 'select(.username == $u)' "$OUT" >/dev/null 2>&1; then
    continue
  fi

  echo "  Enriching: $username"

  # Profile
  profile=$(gh api "users/$username" --jq '{
    name: .name,
    blog: .blog,
    bio: .bio,
    company: .company,
    public_repos: .public_repos,
    followers: .followers,
    created_at: .created_at
  }' 2>/dev/null || echo '{}')

  blog=$(echo "$profile" | jq -r '.blog // empty')
  bio=$(echo "$profile" | jq -r '.bio // empty')
  name=$(echo "$profile" | jq -r '.name // empty')

  # Contribution breadth: repos they've PR'd to (not their own)
  contrib_repos=$(gh search prs \
    --author "$username" \
    --state all \
    --limit 50 \
    --json repository \
    --jq '[.[].repository.nameWithOwner] | unique | map(select(startswith("'"$username"'/") | not))' \
    2>/dev/null || echo '[]')

  contrib_count=$(echo "$contrib_repos" | jq 'length')

  # All rejection PRs for this user (from raw)
  rejection_repos=$(jq -r --arg u "$username" 'select(.username == $u) | .repo' "$RAW" | sort -u | jq -R -s 'split("\n") | map(select(. != ""))')

  # Build entry
  jq -n \
    --arg username "$username" \
    --arg name "$name" \
    --arg blog "$blog" \
    --arg bio "$bio" \
    --argjson contrib_count "$contrib_count" \
    --argjson contrib_repos "$contrib_repos" \
    --argjson rejection_repos "$rejection_repos" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      ts: $ts,
      username: $username,
      name: $name,
      blog: (if $blog == "" then null else $blog end),
      bio: (if $bio == "" then null else $bio end),
      contrib_repos_count: $contrib_count,
      contrib_repos: ($contrib_repos | .[0:10]),
      rejection_repos: $rejection_repos,
      has_blog: ($blog != ""),
      multi_repo: ($contrib_count >= 2),
      proof_of_work: ($contrib_count >= 2)
    }' >> "$OUT"

  sleep 1

done

# Phase 3: Dedupe final output
echo "Phase 3: Deduping..."

if [[ -f "$OUT" ]]; then
  # Last entry wins per username
  python3 -c "
import json, sys
by_user = {}
with open('$OUT') as f:
    for line in f:
        line = line.strip()
        if not line: continue
        entry = json.loads(line)
        by_user[entry['username']] = entry
with open('$OUT', 'w') as f:
    for entry in sorted(by_user.values(), key=lambda e: e['contrib_repos_count'], reverse=True):
        f.write(json.dumps(entry) + '\n')
print(f'Deduped to {len(by_user)} unique contributors')
"
fi

# Summary
total=$(wc -l < "$OUT" | tr -d ' ')
with_blog=$(jq -r 'select(.has_blog == true) | .username' "$OUT" | wc -l | tr -d ' ')
multi=$(jq -r 'select(.multi_repo == true) | .username' "$OUT" | wc -l | tr -d ' ')

echo ""
echo "=== Complementations ==="
echo "Total unique contributors: $total"
echo "With blog/site: $with_blog"
echo "Multi-repo contributors: $multi"
echo ""
echo "Top 10 by contribution breadth:"
head -10 "$OUT" | jq -r '[.username, (.contrib_repos_count | tostring), (.blog // "no blog")] | join(" | ")'
