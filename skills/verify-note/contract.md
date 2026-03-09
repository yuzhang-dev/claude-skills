# Note Processing Contract

This is the main entry point for processing notes. Read this file to determine the note type and follow the appropriate contract.

## Input Handling

The user provides either a **zip file** or a **markdown file**. All output goes to the **same directory** as the input file.

If the arguments include the `--fast` flag, run the token-saving **Fast Mode** variant of the verification pipeline (see below) instead of the default thorough pipeline.

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

**Agent 1 — Proposer.** A rigorous reviewer who scrutinizes the note for errors and proposes a list of potential corrections. For each potential error found, the proposer must:
- State exactly what is wrong and where (quote the original text).
- Provide supporting evidence from a verified source: cite the specific page/section/table from the paper (for paper notes), or link to official documentation / authoritative reference (for study notes).
- Classify confidence: **high** (clear contradiction with source), **medium** (likely wrong but source is indirect), or **low** (suspicious but not confirmed).

**Agent 2 — Challenger.** A skeptical adversary who receives the proposer's error list and tries to refute each one. For each claimed error, the challenger must:
- First, independently verify whether the error is real — re-check the cited evidence and look for additional sources that support or contradict the claim.
- Challenge errors that are ambiguous, poorly supported, or based on misreadings. Provide counter-evidence where applicable.
- Mark each error as: **agree** (error is real), **dispute** (error is likely false or overstated, with reasons), or **needs more evidence**.

**Agent 3 — Judge.** A neutral arbiter who receives both the proposer's findings and the challenger's responses. For each disputed or uncertain error, the judge must:
- Re-verify the evidence from both sides independently.
- Render a final verdict: **confirmed error** (apply the correction), **false alarm** (keep the original text), or **flag for user** (genuinely ambiguous — present both sides to the user).
- Produce the final list of confirmed errors to be applied to the note.

Only **confirmed errors** from the judge are applied to the note and recorded in the verification log. **False alarms** are discarded. **Flagged items** are presented to the user for a decision.

### Fast Mode (`--fast`)

If the user's arguments include the `--fast` flag, run this token-saving variant instead of the pipeline above. It keeps all three roles but minimizes token use:

1. **Read sources once.** Read the paper PDF / fetch references a single time and extract the relevant evidence (quoted text, table values, equations) into a compact evidence list. All three agents work from this shared list — they do **not** re-read the full PDF or re-fetch sources.
2. **One batched pass per role.** Run each role exactly once over the whole set of findings (not per-finding, not per-section): the Proposer produces all candidates with quoted evidence and confidence; the Challenger reviews the entire list at once; the Judge renders all verdicts at once.
3. **Escalate only the uncertain.** High-confidence findings backed by a direct quoted contradiction may be confirmed without challenge; route only **medium/low**-confidence findings through the full Challenger + Judge exchange.

**Tradeoff:** Fast Mode does less independent re-verification, so it is cheaper but slightly more likely to miss a subtle error or let a borderline correction through. Use the default (thorough) pipeline when correctness is critical; use `--fast` for quick cleanups or short sources.

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

Always append a `## Verification Log` table at the end of the note:

| # | Issue | Original | Corrected | Evidence |
|---|-------|----------|-----------|----------|

- Each row: issue number, what was wrong, original text, corrected text, evidence (source link/reference).
- Do NOT list typos here.

### Final Step: Apply and Report

After processing is complete:
1. **Auto-apply** all confirmed corrections from the judge to the note. Do not wait for user confirmation — corrections backed by verified evidence are applied immediately.
2. Update the verification log with all new confirmed errors.
3. Update the "Updated" date in the declaration block.
4. Show the user a summary of all changes applied and any flagged items that need their input.
