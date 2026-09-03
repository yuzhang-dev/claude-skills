# Note Processing Contract

This is the main entry point for processing notes. Read this file to determine the note type and follow the appropriate contract.

## Input Handling

The user provides either a **zip file** or a **markdown file**. All output goes to the **same directory** as the input file.

Before verifying anything, read `${CLAUDE_SKILL_DIR}/evidence.md` — it defines how sources
are obtained and read. Its token-efficient procedure is **always in force**, at every risk
tier; it is not a mode the user opts into.

The `--fast` flag requests the **LOW** risk tier (see *Read depth — risk tiers* below). It is
gated: it is refused on paper notes and on anything with a meaningful density of hard claims.

### Zip Input (typical Notion export)

1. Unzip into the same directory as the input zip.
2. Locate the markdown file inside.
3. Identify the note type (see below).
4. Process per the appropriate contract.
5. Organize images into a subfolder named after the note (e.g., `note-name/image.png`).
6. Re-zip the final result (markdown + images folder) in the same directory.

### Markdown Input

1. Read the markdown from its location.
2. Identify the note type (see below).
3. Process per the appropriate contract.
4. Write the cleaned markdown back to the same location (overwrite the original).

## Note Type Detection

After reading the note, classify it as one of:

### Paper Note

The note is about a **specific academic paper**. Indicators:
- Contains a paper title, authors, arXiv ID, or DOI
- Has sections like "Summary", "Key Contributions", "Method Details", "Experiments", "Conclusions"
- References a single paper as its primary subject
- Contains equations, experimental results, or method descriptions tied to a paper

**Follow:** `${CLAUDE_SKILL_DIR}/paper-note-contract.md`

### Study Note

The note is a **general learning note** on a topic. Indicators:
- Covers a broad topic (e.g., C++ templates, system design, algorithms, a library/tool)
- Not centered on a single paper
- May include code snippets, tutorials, concept explanations
- References multiple sources rather than one primary paper

**Follow:** `${CLAUDE_SKILL_DIR}/study-note-contract.md`

### Ambiguous Cases

If uncertain, check:
1. Does the note mention a specific paper title or arXiv ID? → Paper note.
2. Is the content organized around explaining a topic rather than summarizing a paper? → Study note.
3. Still unclear? Ask the user.

## Common Steps (both note types)

### Three-Agent Verification Pipeline

The note may or may not contain errors. The goal is to find real errors and avoid introducing false corrections. After the note-type-specific research/fetching step is done, run three sub-agents **in sequence**:

**Agent 1 — Proposer (researcher).** A rigorous reviewer who scrutinizes the note for errors and proposes a list of potential corrections. For each potential error found, the proposer must:
- State exactly what is wrong and where (quote the original text).
- Provide supporting evidence from a verified source: cite the specific page/section/table from the paper (for paper notes), or link to official documentation / authoritative reference (for study notes).
- Classify confidence: **high** (clear contradiction with source), **medium** (likely wrong but source is indirect), or **low** (suspicious but not confirmed).
- Flag TECHNICAL / FACTUAL errors only — never style. Style is handled by `rules.md`, not by the pipeline.

**Agent 2 — Challenger.** A skeptical adversary who receives the proposer's error list. The challenger has **two jobs, both mandatory**:
- **Re-verify the majority of the proposer's items**, not merely the ones that look contested. A challenger that only pushes on disputes is too gentle, and its most valuable output is killing proposer **false positives** — findings that quote a misread table cell, or a number the source never states at all. Without a second independent read those wrong "fixes" get applied.
- **Adversarially re-read the whole note for what the proposer MISSED.** This is where "clean" verdicts get caught out; misattributions and omissions surface here far more often than in the proposer's pass.

Mark each item **agree** / **dispute** / **needs more evidence**, with counter-evidence.

**Agent 3 — Judge.** A neutral arbiter who receives both the proposer's findings and the challenger's responses. For each disputed or uncertain item, plus every new high-confidence finding the challenger raised, the judge must:
- Re-verify the evidence from both sides independently against the source. **Confirm that cited evidence actually exists** — a fabricated or imagined citation is itself a finding.
- Render a final verdict: **confirmed error** (apply the correction), **false alarm** (keep the original text), or **flag for user** (genuinely ambiguous — present both sides to the user).
- For each confirmed error, emit an exact verbatim `old_string` + `new_string`. The judge produces edits; it does not apply them.

A finding is a **proposal, not a verdict.** Nothing is written to the note until the challenger and the judge have re-checked it against the source.

Only **confirmed errors** from the judge are applied to the note and recorded in the verification log. **False alarms** are discarded. **Flagged items** are presented to the user for a decision.

### Read depth — risk tiers

How many agents **independently read the source** is set by the note's risk tier, not
by a wish to spend fewer tokens. Token savings come from `evidence.md` (read text, not
page images; stage once; run in sub-agents) and are already in force at every tier.
**Never trade away a read to save tokens.**

| Tier | Reads | Models | Batching |
|---|---|---|---|
| **HIGH** | Proposer and challenger each **independently read the full source, two passes**, comparing line by line against the note as strictly as possible. Judge re-checks every contested and every high-confidence item against the source. | all `opus` | one note at a time |
| **MID** (default) | **All three read the source**: proposer reads; challenger independently re-reads and rebuts the majority; judge reads the relevant sections to arbitrate. | proposer `sonnet`, challenger + judge `opus` | one note at a time |
| **LOW** (`--fast`) | **Proposer only, one read.** Escalate to the full pipeline the moment it surfaces any medium/high-confidence suspicion. | proposer `sonnet` | may batch same-source notes into one agent |

**Tier gating — these are hard rules, not defaults:**

- **Paper notes are always MID or HIGH. Never LOW**, and `--fast` on a paper note is
  refused: say so and run MID instead.
- **HIGH** for notes with easy-to-mis-transcribe constants, notes drafted without the
  full source text in hand, or any note where a previous pass found a fabrication.
- **Study notes get the full three-agent pipeline too.** They are *not* the safe tier —
  see `rules.md` for why they are empirically the higher-risk kind.
- **LOW / `--fast` is reserved for conceptual, index, or reading-list notes with few
  hard claims.** If the note does not obviously fit that description, do not use it.

### Token budget and stopping

- Between notes in a batch, check remaining context. **≥ 40% free → continue to the
  next note; < 40% free → stop cleanly**, after finishing and persisting the current
  note. Next session resumes from the ledger.
- No readable context percentage → conservative fallback: at most 5 notes per session.
- Never leave a note half-applied. Persist findings and apply the judge's edits for the
  current note before stopping.

### Declaration Block

Every note must have a declaration block at the top:

```
---
Description: <brief description>
Notion Note ID: <ID or empty>
Created: <date>
Updated: <date>
License: <license or empty>
---
```

### Verification Log

Default: append a `## Verification Log` table at the end of the note.

**Placement is overridable per project.** Published notes (a website body, a Notion page)
often want the log suppressed and kept **external** — one findings file per note in the
scratch/state directory, with the summary reported in chat instead. If the project's own
CLAUDE.md or workflow doc says so, follow it; that override outranks this default.

The table format:

| # | Issue | Original | Corrected | Evidence |
|---|-------|----------|-----------|----------|

- Each row: issue number, what was wrong, original text, corrected text, evidence (source link/reference).
- Do NOT list typos here.

### Final Step: Apply and Report

After processing is complete:

1. **Auto-apply** all confirmed corrections from the judge to the note, idempotently (see
   `evidence.md` §4). Do not wait for user confirmation — corrections backed by verified
   evidence are applied immediately.
2. **Never auto-apply `flag_for_user` items.** Report them for the human, with both sides.
3. **Re-verify after substantive edits.** If the corrections touched math, physics, a
   formula, or any factual chain, run the **full pipeline again on the corrected note**
   (persist as `.v2` findings files). This catches "fixed one place, left the related
   inconsistency" — in the campaign this procedure came from, **7 of ~40 applied fixes
   were themselves wrong**. Also re-run the full pipeline on any note where a fabrication
   was found: fabrications cluster, and one pass rarely catches them all.
4. Update the verification log with all new confirmed errors.
5. Update the "Updated" date in the declaration block.
6. Show the user a summary of all changes applied, which evidence rung was used, and any
   flagged items that need their input.
