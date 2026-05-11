#!/bin/bash
# Complementations crawler v2
# Finds AI-assisted open source contributors via merged external PRs with depth signals.
# Starts from repos, not people. Scores depth, excludes employer work, treats AI evidence as secondary.
#
# Usage: bash scripts/complementations-crawler-v2.sh [--resume]
# Requires: gh (authenticated), jq, python3

set -euo pipefail

RAW="complementations-v2-raw.jsonl"
OUT="data/complementations-v2.jsonl"
SCORES="/tmp/complementations-scores.jsonl"
SEEN_FILE="/tmp/complementations-v2-seen.txt"
PREV_OUT="/tmp/complementations-v2-prev.jsonl"

mkdir -p data

# Stage 1: Seed repos — projects where external contributors can land real fixes
SEED_REPOS=(
  "astral-sh/uv"
  "astral-sh/ruff"
  "servo/servo"
  "denoland/deno"
  "biomejs/biome"
  "oven-sh/bun"
  "fastify/fastify"
  "pydantic/pydantic"
  "vllm-project/vllm"
  "triton-lang/triton"
  "tinygrad/tinygrad"
  "uutils/coreutils"
  "helix-editor/helix"
  "fish-shell/fish-shell"
  "zed-industries/zed"
  "charmbracelet/bubbletea"
  "clap-rs/clap"
  "modelcontextprotocol/servers"
  "langchain-ai/langchain"
  "huggingface/transformers"
  "pytorch/pytorch"
  "celo-org/celo-kona"
  "steipete/oracle"
  "pinojs/pino"
  "microsoft/agent-governance-toolkit"
)

# Resume support
if [[ "${1:-}" == "--resume" ]] && [[ -f "$OUT" ]]; then
  cp "$OUT" "$PREV_OUT"
  jq -r '.username' "$OUT" 2>/dev/null | sort -u > "$SEEN_FILE"
  echo "Resuming. $(wc -l < "$SEEN_FILE" | tr -d ' ') users already processed."
else
  > "$SEEN_FILE"
  > "$RAW"
  > "$SCORES"
  > "$PREV_OUT"
  echo "Starting fresh."
fi

is_seen() {
  grep -qxF "$1" "$SEEN_FILE" 2>/dev/null
}

mark_seen() {
  echo "$1" >> "$SEEN_FILE"
}

# Stage 2: Pull recent merged PRs from non-members via GraphQL
echo "Stage 2: Pulling merged external PRs from seed repos..."

GQL_QUERY='query($q: String!, $cursor: String) {
  search(query: $q, type: ISSUE, first: 100, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on PullRequest {
        author { login }
        title
        body
        number
        additions
        deletions
        changedFiles
        url
        createdAt
        mergedAt
        reviews(first: 5) {
          nodes { author { login } state body }
        }
        comments { totalCount }
        labels(first: 10) { nodes { name } }
        repository { nameWithOwner owner { login } }
      }
    }
  }
}'

for repo in "${SEED_REPOS[@]}"; do
  echo "  Scanning: $repo"
  owner="${repo%%/*}"

  query="is:pr is:merged repo:$repo created:>2026-01-01"

  cursor=""
  page=0
  while true; do
    page=$((page + 1))
    if [[ -z "$cursor" ]]; then
      result=$(gh api graphql -f query="$GQL_QUERY" -f q="$query" 2>/dev/null || echo '{}')
    else
      result=$(gh api graphql -f query="$GQL_QUERY" -f q="$query" -f cursor="$cursor" 2>/dev/null || echo '{}')
    fi

    if echo "$result" | jq -e '.data.search.nodes' >/dev/null 2>&1; then
      echo "$result" | jq -c '.data.search.nodes[]?' 2>/dev/null | while read -r node; do
        author=$(echo "$node" | jq -r '.author.login // empty')
        repo_owner=$(echo "$node" | jq -r '.repository.owner.login // empty')

        # Skip if author owns the repo
        [[ "$author" == "$repo_owner" ]] && continue
        # Skip bots
        case "$author" in
          *bot*|*Bot*|dependabot*|renovate*|github-actions*|"") continue ;;
        esac

        echo "$node" >> "$RAW"
      done
    fi

    has_next=$(echo "$result" | jq -r '.data.search.pageInfo.hasNextPage // false' 2>/dev/null || echo "false")
    cursor=$(echo "$result" | jq -r '.data.search.pageInfo.endCursor // empty' 2>/dev/null || echo "")

    [[ "$has_next" != "true" ]] && break
    [[ $page -ge 3 ]] && break  # cap at 300 PRs per repo
    sleep 1
  done

  sleep 2
done

echo "Stage 2 complete. $(wc -l < "$RAW" | tr -d ' ') raw PR records."

# Stage 3: Praise-language search (feeds into RAW before scoring)
echo "Stage 3: Acceptance-language search..."

for phrase in "good catch" "nice investigation" "thanks for the fix" "thanks for the reproduction" "great writeup"; do
  echo "  Searching: \"$phrase\""

  praise_result=$(gh api graphql -f query="$GQL_QUERY" \
    -f q="is:pr is:merged \"$phrase\" in:comments created:>2026-03-01" \
    2>/dev/null || echo '{}')

  if echo "$praise_result" | jq -e '.data.search.nodes' >/dev/null 2>&1; then
    echo "$praise_result" | jq -c '.data.search.nodes[]?' 2>/dev/null | while read -r node; do
      author=$(echo "$node" | jq -r '.author.login // empty')
      repo_owner=$(echo "$node" | jq -r '.repository.owner.login // empty')

      [[ "$author" == "$repo_owner" ]] && continue
      case "$author" in
        *bot*|*Bot*|dependabot*|renovate*|github-actions*|"") continue ;;
      esac

      echo "$node" >> "$RAW"
    done
  fi

  sleep 3
done

echo "Stage 3 complete. $(wc -l < "$RAW" | tr -d ' ') total raw PR records (repo + praise)."

# Stage 4: Score PR depth
echo "Stage 4: Scoring PR depth..."

python3 << 'SCORE_EOF'
import json, re, sys

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
    # opener formulae — AI starts descriptions the same way every time
    (r'^this (?:pr|change|commit|patch|mr) ', 'opener'),
    (r'^this (?:implements|adds|fixes|updates|resolves|addresses|introduces|refactors|removes) ', 'opener'),
    # hedge verbs — humans say "fix X", AI says "properly handle X"
    (r'\bproperly (?:handle|implement|address|set|initialize|validate|parse)', 'hedge'),
    (r'\bcorrectly (?:handle|implement|set|resolve)', 'hedge'),
    (r'\bensures? that\b', 'hedge'),
    # over-structured — markdown headers for a 10-line diff
    (r'^## (?:summary|changes|description|motivation|context|testing|test plan)\b', 'structure'),
    (r'^### (?:before|after|problem|solution)\b', 'structure'),
    # politeness boilerplate
    (r"\bi'?d be happy to\b", 'polite'),
    (r'\bfeel free to\b', 'polite'),
    (r'\bplease let me know\b', 'polite'),
    (r'\bhappy to (?:adjust|update|change|address|make)\b', 'polite'),
    # explicit AI footprints
    (r'generated (?:with|by) (?:claude|cursor|copilot|aider|gpt|chatgpt)', 'explicit'),
    (r'co-authored-by:.*(?:claude|cursor|copilot|aider|chatgpt)', 'explicit'),
    (r'\b(?:claude code|cursor|aider|copilot chat)\b', 'explicit'),
    # emoji soup — ✅ 🔧 📝 🚀 in structured lists
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
    reviews = pr.get('reviews', {}).get('nodes', [])
    labels = {n.get('name', '').lower() for n in pr.get('labels', {}).get('nodes', [])}

    if labels & skip_labels:
        return 0, True, [], 0

    score = 1  # base: merged external PR

    # depth signals in title + body
    title_high, title_low = score_text(title)
    body_high, body_low = score_text(body)

    if title_high or body_high:
        score += 3
    if title_low and not title_high and not body_high:
        score -= 1

    # surgical change bonus
    if 0 < additions + deletions < 50:
        score += 1
    # net-negative bonus
    if deletions > additions:
        score += 1

    # review engagement
    if any(r.get('state') == 'CHANGES_REQUESTED' for r in reviews):
        if any(r.get('state') == 'APPROVED' for r in reviews):
            score += 2  # survived review iteration

    ai_categories, ai_count = detect_ai_tells(body)
    return score, False, ai_categories, ai_count

# Dedupe PRs by URL before scoring
seen_urls = set()
scores = {}
with open('complementations-v2-raw.jsonl') as f:
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
                'best_pr': None, 'best_score': 0, 'pr_scores': [],
                'ai_tell_categories': set(), 'ai_tell_prs': 0, 'ai_tell_total': 0,
            }
        scores[author]['total'] += score
        scores[author]['repos'].add(repo)
        scores[author]['prs'] += 1
        scores[author]['pr_scores'].append({'repo': repo, 'url': url, 'score': score})
        if score > scores[author]['best_score']:
            scores[author]['best_score'] = score
            scores[author]['best_pr'] = url
        if ai_count > 0:
            scores[author]['ai_tell_prs'] += 1
            scores[author]['ai_tell_total'] += ai_count
            scores[author]['ai_tell_categories'].update(ai_cats)

with open('/tmp/complementations-scores.jsonl', 'w') as f:
    for author, data in sorted(scores.items(), key=lambda x: -x[1]['total']):
        repos = list(data['repos'])
        if len(repos) < 2 and data['prs'] < 3:
            continue
        if data['total'] < 3:
            continue
        f.write(json.dumps({
            'username': author,
            'depth_score': data['total'],
            'external_repos': repos,
            'external_repo_count': len(repos),
            'pr_count': data['prs'],
            'best_pr': data['best_pr'],
            'pr_scores': data['pr_scores'],
            'ai_body_tells': {
                'prs_with_tells': data['ai_tell_prs'],
                'total_hits': data['ai_tell_total'],
                'categories': sorted(data['ai_tell_categories']),
                'rate': round(data['ai_tell_prs'] / data['prs'], 2) if data['prs'] else 0,
            },
        }) + '\n')

count = sum(1 for _ in open('/tmp/complementations-scores.jsonl'))
print(f"Stage 4 complete. {count} candidates after depth scoring.")
SCORE_EOF

# Stage 5: Employer exclusion + score recomputation
echo "Stage 5: Employer/org exclusion..."

cp "$PREV_OUT" "$OUT"

while read -r candidate; do
  username=$(echo "$candidate" | jq -r '.username')

  if is_seen "$username"; then
    continue
  fi

  # Get profile
  profile=$(gh api "users/$username" --jq '{
    name: .name,
    blog: .blog,
    bio: .bio,
    company: .company,
    followers: .followers,
    public_repos: .public_repos
  }' 2>/dev/null || echo '{}')

  company_raw=$(echo "$profile" | jq -r '.company // ""' 2>/dev/null || echo "")
  company_tokens=$(echo "$company_raw" | tr '[:upper:]' '[:lower:]' | sed 's/@//g; s/,/ /g; s/[^a-z0-9 ]/ /g' | tr -s ' ')
  blog=$(echo "$profile" | jq -r '.blog // ""' 2>/dev/null || echo "")
  name=$(echo "$profile" | jq -r '.name // ""' 2>/dev/null || echo "")
  followers=$(echo "$profile" | jq -r '.followers // 0' 2>/dev/null || echo "0")
  [[ -z "$followers" ]] && followers=0

  # Check org membership against PR target repos
  external_repos=$(echo "$candidate" | jq -r '.external_repos[]')
  is_employer=false
  clean_list=()
  employer_repos=()

  for repo in $external_repos; do
    repo_owner="${repo%%/*}"

    # Skip if repo owner matches username
    if [[ "$repo_owner" == "$username" ]]; then
      employer_repos+=("$repo")
      continue
    fi

    # Skip if repo owner matches any company token
    repo_owner_lower=$(echo "$repo_owner" | tr '[:upper:]' '[:lower:]')
    if [[ -n "$company_tokens" ]]; then
      is_company_match=false
      for token in $company_tokens; do
        [[ ${#token} -lt 3 ]] && continue
        [[ "$repo_owner_lower" == "$token" ]] && is_company_match=true && break
      done
      if [[ "$is_company_match" == "true" ]]; then
        is_employer=true
        employer_repos+=("$repo")
        continue
      fi
    fi

    # Check org membership
    member_check=$(gh api "orgs/$repo_owner/members/$username" 2>/dev/null && echo "member" || echo "not_member")
    if [[ "$member_check" == "member" ]]; then
      is_employer=true
      employer_repos+=("$repo")
      continue
    fi

    clean_list+=("$repo")
    sleep 0.3
  done

  # Skip if all repos are employer/own
  if [[ ${#clean_list[@]} -eq 0 ]]; then
    mark_seen "$username"
    continue
  fi

  clean_repos=$(printf '%s\n' "${clean_list[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')

  # Recompute depth score from only verified external repos
  if [[ ${#employer_repos[@]} -gt 0 ]]; then
    employer_json=$(printf '%s\n' "${employer_repos[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')
  else
    employer_json='[]'
  fi
  recomputed=$(echo "$candidate" | jq \
    --argjson clean_repos "$clean_repos" \
    --argjson employer_repos "$employer_json" \
    '[.pr_scores[] | select(.repo as $r | $clean_repos | index($r))] | {
      verified_depth_score: (map(.score) | add // 0),
      verified_pr_count: length,
      verified_best_pr: (sort_by(-.score) | .[0].url // null)
    }')

  verified_score=$(echo "$recomputed" | jq -r '.verified_depth_score' 2>/dev/null || echo "0")
  verified_pr_count=$(echo "$recomputed" | jq -r '.verified_pr_count' 2>/dev/null || echo "0")
  verified_best_pr=$(echo "$recomputed" | jq -r '.verified_best_pr // empty' 2>/dev/null || echo "")
  [[ -z "$verified_score" || "$verified_score" == "null" ]] && verified_score=0
  [[ -z "$verified_pr_count" || "$verified_pr_count" == "null" ]] && verified_pr_count=0

  # Enforce: multi-repo or deep-in-one after cleanup
  if [[ ${#clean_list[@]} -lt 2 ]] && [[ "$verified_pr_count" -lt 3 ]]; then
    mark_seen "$username"
    continue
  fi
  if [[ "$verified_score" -lt 3 ]]; then
    mark_seen "$username"
    continue
  fi

  # Merge into output — guard argjson values
  [[ -z "$followers" || "$followers" == "null" ]] && followers=0
  [[ -z "$verified_score" || "$verified_score" == "null" ]] && verified_score=0
  [[ -z "$verified_pr_count" || "$verified_pr_count" == "null" ]] && verified_pr_count=0
  if ! echo "$candidate" | jq -c \
    --arg name "$name" \
    --arg blog "$blog" \
    --arg company "$company_raw" \
    --argjson followers "${followers:-0}" \
    --argjson clean_repos "$clean_repos" \
    --argjson is_employer "$is_employer" \
    --argjson verified_score "${verified_score:-0}" \
    --argjson verified_pr_count "${verified_pr_count:-0}" \
    --arg verified_best_pr "${verified_best_pr:-null}" \
    '. + {
      name: $name,
      blog: (if $blog == "" then null else $blog end),
      company: (if $company == "" then null else $company end),
      followers: $followers,
      verified_external_repos: $clean_repos,
      verified_external_repo_count: ($clean_repos | length),
      verified_depth_score: $verified_score,
      verified_pr_count: $verified_pr_count,
      verified_best_pr: (if $verified_best_pr == "null" then null else $verified_best_pr end),
      has_employer_repos: $is_employer,
      has_blog: ($blog != ""),
      ts: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    } | del(.pr_scores)' >> "$OUT" 2>/dev/null; then
    echo "  WARN: skipping $username (jq merge failed)" >&2
  fi

  mark_seen "$username"
  sleep 0.5

done < "$SCORES"

echo "Stage 5 complete."

# Stage 6: AI-evidence enrichment (secondary — noted, not filtered)
echo "Stage 6: AI-evidence enrichment..."

python3 << 'AI_EOF'
import json, subprocess, time

entries = []
with open('data/complementations-v2.jsonl') as f:
    for line in f:
        entries.append(json.loads(line.strip()))

for entry in entries:
    user = entry['username']

    try:
        result = subprocess.run(
            ['gh', 'api', 'graphql', '-f',
             f'query={{ search(query: "is:pr author:{user} \\"Generated with Claude Code\\" OR \\"Co-authored-by: Claude\\" OR \\"Cursor\\" OR \\"Aider\\"", type: ISSUE, first: 5) {{ issueCount }} }}'],
            capture_output=True, text=True, timeout=15
        )
        data = json.loads(result.stdout)
        ai_pr_count = data.get('data', {}).get('search', {}).get('issueCount', 0)
    except Exception:
        ai_pr_count = 0

    body_tells = entry.get('ai_body_tells', {})
    tell_rate = body_tells.get('rate', 0)
    tell_cats = body_tells.get('categories', [])
    has_explicit = 'explicit' in tell_cats

    entry['ai_evidence'] = {
        'github_search_hits': ai_pr_count,
        'body_tell_rate': tell_rate,
        'body_tell_categories': tell_cats,
        'prs_with_tells': body_tells.get('prs_with_tells', 0),
        'automation_signal': (
            'strong' if (has_explicit or ai_pr_count >= 3 or tell_rate >= 0.6) else
            'moderate' if (ai_pr_count >= 1 or tell_rate >= 0.3) else
            'weak' if tell_rate > 0 else
            'none'
        ),
    }
    del entry['ai_body_tells']
    time.sleep(0.5)

with open('data/complementations-v2.jsonl', 'w') as f:
    for entry in sorted(entries, key=lambda e: (
        {'strong': 0, 'moderate': 1, 'weak': 2, 'none': 3}[e['ai_evidence']['automation_signal']],
        -e['verified_depth_score']
    )):
        f.write(json.dumps(entry) + '\n')

ai_counts = {}
for e in entries:
    s = e['ai_evidence']['automation_signal']
    ai_counts[s] = ai_counts.get(s, 0) + 1
print(f"Stage 6 complete. {len(entries)} entries enriched.")
print(f"  AI signals: {ai_counts}")
AI_EOF

# Summary
total=$(wc -l < "$OUT" | tr -d ' ')
with_blog=$(jq -r 'select(.has_blog == true) | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')
multi=$(jq -r 'select(.verified_external_repo_count >= 2) | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')

strong=$(jq -r 'select(.ai_evidence.automation_signal == "strong") | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')
moderate=$(jq -r 'select(.ai_evidence.automation_signal == "moderate") | .username' "$OUT" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "=== Complementations v2 ==="
echo "Total candidates: $total"
echo "With blog/site: $with_blog"
echo "Multi-repo (2+): $multi"
echo "AI signal strong: $strong"
echo "AI signal moderate: $moderate"
echo ""
echo "Top 15 (sorted by AI signal, then depth):"
head -15 "$OUT" | jq -r '[.username, .ai_evidence.automation_signal, ("score:" + (.verified_depth_score | tostring)), ((.verified_external_repo_count | tostring) + " repos"), (.blog // "no blog")] | join(" | ")'
