# Sweep Graph (2026-05-09)

## Cross-repo findings
- client:only dead imports: withastro/astro#16634 (closed, Vite approach) → withastro/compiler#1162 (open, compiler approach). Same bug, different fix layer. Clean handoff.

## Punch list

### READY TO SHIP (after changeset)
- **withastro/compiler #1162** — strip dead imports for client:only (score 8). Add changeset, ping maintainer ~May 14.

### NO ACTION
- **withastro/astro #16634** — closed by author in favor of compiler fix. Done.

## Per-repo summaries

### withastro/astro
1 item (PR #16634). Self-closed. No further action.

### withastro/compiler
1 item (PR #1162). Open, stalled on process gates:
1. Missing changeset (author-fixable)
2. CI awaiting first-time contributor approval (maintainer-side)
3. No reviews (expected — slow cadence, ping ~May 14)
