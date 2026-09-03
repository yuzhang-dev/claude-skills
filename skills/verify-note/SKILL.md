---
name: verify-note
description: Verify and clean up markdown notes (paper notes or study notes) using a three-agent verification pipeline.
---

You are verifying and cleaning up a note. The user input is: `$ARGUMENTS`

## Setup

Before doing anything, read the following files from the skill directory:

1. **Rules:** `${CLAUDE_SKILL_DIR}/rules.md`
2. **Contract:** `${CLAUDE_SKILL_DIR}/contract.md`
3. **Evidence handling:** `${CLAUDE_SKILL_DIR}/evidence.md`

Then follow the contract to process the note. The contract will route you to the appropriate sub-contract based on note type (paper note or study note).

## Input

The user provides a path to either:
- A **zip file** (Notion export containing markdown + images)
- A **markdown file**

An optional `--fast` flag requests the **LOW** risk tier (proposer only, one read). It is
gated by the contract's *Read depth* table: refused on paper notes, and reserved for
conceptual / index / reading-list notes with few hard claims.

Token efficiency is **not** a mode. `evidence.md` applies on every run at every tier: read
sources as text rather than page images, stage the text once in the main context, run the
three roles as sub-agents that persist findings to disk. Savings come from *how* evidence is
read, never from skipping verification.

## Output

All output (processed markdown, images, zips) goes back to the **same directory** as the input file. Do not create a separate output folder.

## Key Principles

- **Accuracy over speed.** Verify every claim against sources before correcting.
- **Quality is never traded for tokens.** Savings come from how evidence is read, not from skipping a read.
- **Preserve the author's voice.** Fix errors, don't rewrite.
- **A finding is a proposal, not a verdict.** The three-agent pipeline (proposer → challenger → judge) exists as much to kill the proposer's false positives as to confirm real errors. Only confirmed corrections are applied; `flag_for_user` items are never auto-applied.
