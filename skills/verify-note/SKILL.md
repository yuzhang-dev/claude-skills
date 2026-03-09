---
name: verify-note
description: Verify and clean up markdown notes (paper notes or study notes) using a three-agent verification pipeline.
---

You are verifying and cleaning up a note. The user input is: `$ARGUMENTS`

## Setup

Before doing anything, read the following files from the skill directory:

1. **Rules:** `${CLAUDE_SKILL_DIR}/rules.md`
2. **Contract:** `${CLAUDE_SKILL_DIR}/contract.md`

Then follow the contract to process the note. The contract will route you to the appropriate sub-contract based on note type (paper note or study note).

## Input

The user provides a path to either:
- A **zip file** (Notion export containing markdown + images)
- A **markdown file**

An optional `--fast` flag selects the token-saving Fast Mode pipeline (see the contract). Without it, the default thorough pipeline runs.

## Output

All output (processed markdown, images, zips) goes back to the **same directory** as the input file. Do not create a separate output folder.

## Key Principles

- **Accuracy over speed.** Verify every claim against sources before correcting.
- **Preserve the author's voice.** Fix errors, don't rewrite.
- **Only apply confirmed corrections.** The three-agent pipeline (proposer → challenger → judge) ensures no false corrections.
