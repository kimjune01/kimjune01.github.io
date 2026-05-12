---
name: em-dash
description: Eliminate em-dashes (—), double en-dashes (––), and double hyphens (--) from prose. Deterministic grep for detection, subagent picks replacement punctuation and applies edits, reports reversal candidates for user review. Sister skill to /not-but.
argument-hint: <file_path>
allowed-tools: Read, Grep, Bash, Edit, Agent
---

# Em-dash: Auto-Replace with Reversal Prompts

Em-dash overuse is a top LLM tell, second only to negative parallelism in how reliably it betrays AI prose. The same tic surfaces in three forms: `—` (em-dash, U+2014), `––` (double en-dash, two U+2013), and `--` (double hyphen, what models substitute when told to avoid em-dashes). This skill **eliminates all three from prose** by default, replacing each with the punctuation that fits (comma, period, colon, semicolon, parens). Edits are applied immediately. The user is prompted only for **reversals**: cases where the original dash served a structural / typographic purpose (list separator, attribution, definition entry) and the user can decide to put it back.

**Scope: prose only.** Run this on blog posts, essays, and articles — not on technical docs, READMEs, code-heavy Markdown, or anywhere `--` legitimately appears inline as a CLI flag. The prose-only assumption is what lets the `--` rule stay strict.

**Apply-first, reverse-on-request.** Matches the copyedit-apply-first pattern: the user reads a diff and reverses anything they want kept, instead of approving each cut individually. Sister skill to `/not-but`.

## Process

1. Read the file at the given path. Note word count and total em-dash + double en-dash count.

2. **Detect (deterministic).** Run **three greps**, one per dash form, so each gets its own count even when others are zero:

   ```bash
   FILE="<file_path>"

   # Em-dashes (U+2014)
   grep -nE '—' "$FILE"

   # Double en-dashes (two U+2013 in a row)
   grep -nE '––' "$FILE"

   # Double hyphens (two ASCII hyphens) — the model's em-dash workaround
   grep -nE '\-\-' "$FILE"
   ```

   Skip hits inside fenced code blocks, tables (lines starting with `|`), HTML tags, frontmatter, and inline code spans. Treat all three forms the same in triage and replacement.

   **`--` rule: code blocks are the only exception.** Any `--` outside a fenced code block is treated as an em-dash workaround and replaced. CLI examples, flag references, HTML comment openers belong inside code fences; if they appear inline in prose, they get replaced like any other dash.

3. **Replace (subagent).** Dispatch to the `general-purpose` agent (or a registered `em-dash` agent if one exists). Pass:
   - The file path
   - The deduplicated list of hits with line numbers and matched lines
   - The replacement rubric below

   For each hit the subagent picks the best replacement punctuation (comma / period / colon / semicolon / parens) based on sentence rhythm and **applies the edit via Edit**. Every prose em-dash is replaced — the subagent does not skip "earned" cases. Each replacement is classified as either **clear-cut** (don't surface) or **reversal candidate** (surface for user review).

   **Reversal candidate categories** (apply replacement, then surface — structural / non-prose uses only):
   - List item description separator (label — description)
   - Attribution dash before a quote source
   - Parenthetical fencing in reference / technical contexts (definition lists, glossaries, tables of terms)

   **Clear-cut categories** (apply silently, never surface):
   - Any em-dash in narrative prose: soft pauses, abrupt breaks, comma replacements, setup-and-pivot, conversational connectors, hedging glue
   - Two em-dashes in one sentence doing different jobs
   - Em-dash density >1 per 200 words (the cumulative rhythm reads AI even when individual cases look defensible)
   - Any double en-dash (no legitimate use case — `––` is always an AI tic or encoding accident)

   **Rule of thumb:** if the dash sits inside a flowing sentence, it goes silently. Reversals are reserved for dashes doing typographic/structural work the reader expects to see (list labels, attributions, definition entries).

4. **Reversal report.** Numbered list of replacements the user might want to undo:

   ```
   {file}: replaced {N_em} em-dashes, {N_dee} double en-dashes, {N_dh} double hyphens ({total_density} per 1000 words)

   Reversal candidates ({count}):
   1. L{line}: was: "{original sentence with — / –– / --}"
              now: "{replaced sentence}"
      reverse if: {one-line reason the dash served a structural purpose}

   Clear-cut replacements applied silently: {N}
   ```

   Clear-cut replacements aren't itemized; they're in the diff but not in the report. The user scans the reversal candidates and decides which (if any) to put back.

5. **Postcondition (mandatory).** After all replacements, re-run the three greps. Filter out hits inside fenced code blocks, tables, HTML tags, frontmatter, and inline code. The remaining prose hit count must be **zero** for all three forms. If any prose hit survives, it is a bug — locate it, replace it, and re-verify before completing. The skill does not return until the postcondition holds.

## Composability

- **Standalone**: `/em-dash <file>` for any prose file.
- **Inside `/humanize`**: /humanize defers to this skill for all three dash forms (`—`, `––`, `--`) the way it defers to /not-but for negative parallelism. Both apply by default; the user reverses what they want kept.
- **Pairs with `/not-but`**: setup-and-pivot dashes ("X — not Y", "X -- not Y", "X –– not Y") often surface in both. Run /not-but first; remaining hits are easier to handle once the pivot cases are gone.

## Why apply-first

Em-dash overuse is a corrigible AI tic, and apply-first has consistently beaten propose-first across the copyedit family. The user reads the diff in a fraction of the time it takes to per-item-approve a flag list, and the rare earned dash is easier to add back than to wade through dozens of "do you want to cut this?" prompts. The reversal report keeps the surface area for genuine judgment small — only cases where the dash plausibly earned its keep get the user's attention.

## Why deterministic detection

Em-dashes are visually obvious to humans but blend into the LLM's training distribution. A regex has no aesthetic preference. False positives (earned cases auto-replaced) are recoverable via the reversal report; false negatives (missed em-dashes) defeat the skill's purpose, and grep has none.
