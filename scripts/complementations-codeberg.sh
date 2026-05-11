#!/bin/bash
# Complementations crawler — Codeberg edition
# Finds AI-assisted open source contributors on Codeberg via Forgejo API.
# Sibling to complementations-crawler-v2.sh (GitHub). Same output format.
#
# Usage: bash scripts/complementations-codeberg.sh
# Requires: curl, jq, python3

set -euo pipefail

API="https://codeberg.org/api/v1"
RAW="complementations-codeberg-raw.jsonl"
OUT="data/complementations-codeberg.jsonl"
SEEN_FILE="/tmp/complementations-codeberg-seen.txt"

mkdir -p data

# Seed repos — Codeberg projects where external contributors can land real fixes
SEED_REPOS=(
  "forgejo/forgejo"
  "forgejo/runner"
  "Codeberg/pages-server"
  "Codeberg/Documentation"
  "woodpecker-ci/woodpecker"
  "tenacityteam/tenacity"
  "Freeyourgadget/Gadgetbridge"
  "gitnex/GitNex"
  "dnkl/foot"
  "dnkl/fuzzel"
  "crowdsecurity/crowdsec"
  "calckey/calckey"
  "Kbin/kbin-core"
)

> "$SEEN_FILE"
> "$RAW"
echo "Starting Codeberg crawl."

is_seen() {
  grep -qxF "$1" "$SEEN_FILE" 2>/dev/null
}

mark_seen() {
  echo "$1" >> "$SEEN_FILE"
}

# Stage 1: Pull recent merged PRs from seed repos
echo "Stage 1: Pulling merged PRs from Codeberg seed repos..."

for repo in "${SEED_REPOS[@]}"; do
  echo "  Scanning: $repo"
  owner="${repo%%/*}"

  page=1
  while true; do
    result=$(curl -sf "${API}/repos/${repo}/pulls?state=closed&sort=updated&limit=50&page=${page}" 2>/dev/null || echo '[]')

    if ! echo "$result" | jq -e '.[0]' >/dev/null 2>&1; then
      break
    fi

    echo "$result" | jq -c '.[] | select(.merged == true)' 2>/dev/null | while read -r pr; do
      author=$(echo "$pr" | jq -r '.user.login // empty')
      repo_owner="$owner"

      [[ "$author" == "$repo_owner" ]] && continue
      case "$author" in
        *bot*|*Bot*|dependabot*|renovate*|"") continue ;;
      esac

      # Normalize to match GitHub output shape
      echo "$pr" | jq -c '{
        author: {login: .user.login},
        title: .title,
        body: .body,
        number: .number,
        additions: .additions,
        deletions: .deletions,
        changedFiles: .changed_files,
        url: .html_url,
        createdAt: .created_at,
        mergedAt: .merged,
        comments: {totalCount: .comments},
        labels: {nodes: [.labels[]? | {name: .name}]},
        repository: {nameWithOwner: "'"$repo"'", owner: {login: "'"$owner"'"}},
        source: "codeberg"
      }' >> "$RAW"
    done

    count=$(echo "$result" | jq 'length')
    [[ "$count" -lt 50 ]] && break
    page=$((page + 1))
    [[ $page -gt 5 ]] && break
    sleep 1
  done

  sleep 1
done

echo "Stage 1 complete. $(wc -l < "$RAW" | tr -d ' ') raw PR records."

# Stage 2: Score PR depth + detect AI tells
echo "Stage 2: Scoring depth + AI tells..."

python3 << 'SCORE_EOF'
import json, re

depth_keywords_high = [
    r'\bregression\b', r'\bbenchmark\b', r'\bprofil', r'\bbisect',
    r'\broot.cause\b', r'\breproducer\b', r'\breproduc', r'\bfailing test',
    r'\bperformance\b', r'\bspeedup\b', r'\blatency\b', r'\bthroughput\b',
    r'\bfix.*crash\b', r'\bsegfault\b', r'\brace condition\b', r'\bdeadlock\b',
    r'\bmemory leak\b', r'\buse.after.free\b', r'\bbuffer overflow\b'
]
depth_keywords_low = [
    r'\breadme\b', r'\btypo\b', r'\bdoc[s]?\b', r'\bbump\b',
    r'\badd.*site\b', r'\badd.*link\b', r'\bformatting\b',
    r'\bchore\b', r'\bdeps?\b', r'\bupdate.*version\b'
]
skip_labels = {
    'bounty', 'sponsored', 'hacktoberfest', 'hacktoberfest-accepted',
    'good first issue', 'paid', 'funding'
}
ai_prose_patterns = [
    (r'^this (?:pr|change|commit|patch|mr) ', 'opener'),
    (r'^this (?:implements|adds|fixes|updates|resolves|addresses|introduces|refactors|removes) ', 'opener'),
    (r'\bproperly (?:handle|implement|address|set|initialize|validate|parse)', 'hedge'),
    (r'\bcorrectly (?:handle|implement|set|resolve)', 'hedge'),
    (r'\bensures? that\b', 'hedge'),
    (r'^## (?:summary|changes|description|motivation|context|testing|test plan)\b', 'structure'),
    (r'^### (?:before|after|problem|solution)\b', 'structure'),
    (r"\bi'?d be happy to\b", 'polite'),
    (r'\bfeel free to\b', 'polite'),
    (r'\bplease let me know\b', 'polite'),
    (r'\bhappy to (?:adjust|update|change|address|make)\b', 'polite'),
    (r'generated (?:with|by) (?:claude|cursor|copilot|aider|gpt|chatgpt)', 'explicit'),
    (r'co-authored-by:.*(?:claude|cursor|copilot|aider|chatgpt)', 'explicit'),
    (r'\b(?:claude code|cursor|aider|copilot chat)\b', 'explicit'),
    (r'[✅🔧📝🚀🐛⚡🔨🎨💡🔥]{2,}', 'emoji'),
    (r'(?:^|\n)\s*[-*]\s*[✅🔧📝🚀🐛⚡]', 'emoji'),
]

def score_text(text):
    text = text.lower()
    high = any(re.search(pat, text) for pat in depth_keywords_high)
    low = any(re.search(pat, text) for pat in depth_keywords_low)
    return high, low

def detect_ai_tells(body):
    if not body:
        return [], 0
    body_lower = body.lower()
    hits = set()
    for pat, category in ai_prose_patterns:
        if re.search(pat, body_lower, re.MULTILINE):
            hits.add(category)
    return list(hits), len(hits)

def score_pr(pr):
    title = (pr.get('title') or '')
    body = (pr.get('body') or '')[:3000]
    additions = pr.get('additions', 0) or 0
    deletions = pr.get('deletions', 0) or 0
    labels = {n.get('name', '').lower() for n in pr.get('labels', {}).get('nodes', [])}

    if labels & skip_labels:
        return 0, True, [], 0

    score = 1

    title_high, title_low = score_text(title)
    body_high, body_low = score_text(body)

    if title_high or body_high:
        score += 3
    if title_low and not title_high and not body_high:
        score -= 1

    if 0 < additions + deletions < 50:
        score += 1
    if deletions > additions:
        score += 1

    ai_categories, ai_count = detect_ai_tells(body)
    return score, False, ai_categories, ai_count

seen_urls = set()
scores = {}
with open('complementations-codeberg-raw.jsonl') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            pr = json.loads(line)
        except json.JSONDecodeError:
            continue

        url = pr.get('url', '')
        if url in seen_urls:
            continue
        seen_urls.add(url)

        author = pr.get('author', {}).get('login', '')
        if not author:
            continue

        repo = pr.get('repository', {}).get('nameWithOwner', '')

        score, skippable, ai_cats, ai_count = score_pr(pr)
        if skippable:
            continue

        if author not in scores:
            scores[author] = {
                'total': 0, 'repos': set(), 'prs': 0,
                'best_pr': None, 'best_score': 0,
                'ai_tell_categories': set(), 'ai_tell_prs': 0, 'ai_tell_total': 0,
            }
        scores[author]['total'] += score
        scores[author]['repos'].add(repo)
        scores[author]['prs'] += 1
        if score > scores[author]['best_score']:
            scores[author]['best_score'] = score
            scores[author]['best_pr'] = url
        if ai_count > 0:
            scores[author]['ai_tell_prs'] += 1
            scores[author]['ai_tell_total'] += ai_count
            scores[author]['ai_tell_categories'].update(ai_cats)

# Fetch profiles and write output
import subprocess

with open('data/complementations-codeberg.jsonl', 'w') as f:
    for author, data in sorted(scores.items(), key=lambda x: -x[1]['total']):
        repos = list(data['repos'])
        if len(repos) < 2 and data['prs'] < 3:
            continue
        if data['total'] < 3:
            continue

        # Fetch Codeberg profile
        try:
            result = subprocess.run(
                ['curl', '-sf', f'https://codeberg.org/api/v1/users/{author}'],
                capture_output=True, text=True, timeout=10
            )
            profile = json.loads(result.stdout) if result.stdout else {}
        except Exception:
            profile = {}

        tell_rate = round(data['ai_tell_prs'] / data['prs'], 2) if data['prs'] else 0
        tell_cats = sorted(data['ai_tell_categories'])
        has_explicit = 'explicit' in tell_cats

        entry = {
            'username': author,
            'name': profile.get('full_name', ''),
            'blog': profile.get('website', '') or None,
            'bio': profile.get('description', ''),
            'followers': profile.get('followers_count', 0),
            'depth_score': data['total'],
            'verified_depth_score': data['total'],
            'verified_external_repos': repos,
            'verified_external_repo_count': len(repos),
            'verified_pr_count': data['prs'],
            'verified_best_pr': data['best_pr'],
            'has_blog': bool(profile.get('website', '')),
            'ai_evidence': {
                'body_tell_rate': tell_rate,
                'body_tell_categories': tell_cats,
                'prs_with_tells': data['ai_tell_prs'],
                'automation_signal': (
                    'strong' if (has_explicit or tell_rate >= 0.6) else
                    'moderate' if tell_rate >= 0.3 else
                    'weak' if tell_rate > 0 else
                    'none'
                ),
            },
            'source': 'codeberg',
        }
        f.write(json.dumps(entry) + '\n')

count = sum(1 for _ in open('data/complementations-codeberg.jsonl'))
print(f"Stage 2 complete. {count} candidates.")
SCORE_EOF

# Summary
total=$(wc -l < "$OUT" | tr -d ' ')
echo ""
echo "=== Complementations — Codeberg ==="
echo "Total candidates: $total"
if [[ "$total" -gt 0 ]]; then
  with_blog=$(jq -r 'select(.has_blog == true) | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')
  multi=$(jq -r 'select(.verified_external_repo_count >= 2) | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')
  strong=$(jq -r 'select(.ai_evidence.automation_signal == "strong") | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')
  echo "With blog/site: $with_blog"
  echo "Multi-repo (2+): $multi"
  echo "AI signal strong: $strong"
  echo ""
  echo "Top 15:"
  head -15 "$OUT" | jq -r '[.username, .ai_evidence.automation_signal, ("score:" + (.verified_depth_score | tostring)), ((.verified_external_repo_count | tostring) + " repos"), ("tells:" + (.ai_evidence.body_tell_rate | tostring)), (.blog // "no blog")] | join(" | ")'
fi
