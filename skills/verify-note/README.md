# verify-note

A **pure markdown rule-based skill** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It verifies and cleans up markdown notes using a three-agent verification pipeline.

This skill is **pure markdown** — no executable code, just rules, contracts, and templates that guide Claude Code's behavior through structured prompts. Its main purpose is to clean up notes and verify terminology, equations, numbers, and claims against authoritative sources.

## Why this exists

LLMs are great at generating structured notes from papers or topics, but they hallucinate — wrong numbers, garbled equations, invented claims. Manual fact-checking is tedious. This skill automates the verification by pitting three sub-agents against each other so that only confirmed errors get corrected.

## Two note types

- **Paper notes** — structured summaries of academic papers following a fixed template ([`templates/paper-note.md`](templates/paper-note.md)): paper info, summary, contributions, method details with LaTeX equations, experiments, and conclusions. The skill fetches the actual paper PDF (from arXiv or locally) and cross-checks every claim, equation, and number against it. It also extracts key figures and tables from the PDF using `pdftoppm` + ImageMagick.

- **Study notes** — free-form learning notes on any topic ([`templates/study-note.md`](templates/study-note.md)). The skill searches for official documentation and authoritative references, then verifies claims, code snippets, and explanations against them. Inline references are added to back up key points.

## How the three-agent pipeline works

The core of this skill is a sequential three-agent verification pipeline defined in [`contract.md`](contract.md):

1. **Proposer** — scrutinizes the note for errors. For each potential error, states exactly what is wrong, quotes the original text, provides evidence from a verified source (paper PDF, official docs), and classifies confidence as high/medium/low.

2. **Challenger** — a skeptical adversary who receives the proposer's error list and tries to refute each one. Independently re-checks the evidence, provides counter-evidence where applicable, and marks each error as agree/dispute/needs more evidence.

3. **Judge** — a neutral arbiter who reviews both sides. Re-verifies the evidence independently and renders a final verdict: confirmed error (apply correction), false alarm (keep original), or flag for user (genuinely ambiguous).

Only **confirmed errors** from the judge are applied. False alarms are discarded. Flagged items are presented to the user for a decision. All corrections are recorded in a verification log table appended to the note.

## Usage

Pass the note to the skill in Claude Code. You can provide either a **markdown file** or a **zip file** (e.g., a Notion export containing markdown + images):

```
/verify-note path/to/note.md
/verify-note path/to/note.zip
/verify-note --fast path/to/note.md   # token-saving Fast Mode
```

The skill will:
1. Detect whether it's a paper note or study note.
2. For paper notes: locate the paper PDF (local file, arXiv fetch, or ask you). For study notes: search for authoritative references.
3. Run the three-agent pipeline (proposer → challenger → judge).
4. Auto-apply all confirmed corrections.
5. For paper notes: extract key figures/tables from the PDF and add them to the note.
6. Clean up formatting artifacts (broken LaTeX, excess blank lines, HTML tags, etc.).
7. Append a verification log and present a summary of changes.

Output goes back to the same directory as the input.

### Fast Mode (`--fast`)

A token-saving variant of the pipeline: sources are read once and shared as extracted evidence across all three roles (no re-reading the full PDF per agent), each role runs as a single batched pass, and only uncertain findings are escalated through the full challenger + judge exchange. Cheaper, but does less independent re-verification — use the default pipeline when correctness is critical.

## Skill structure

```
verify-note/
├── SKILL.md                  # Entry point (Claude Code reads this)
├── contract.md               # Main processing contract & three-agent pipeline
├── rules.md                  # Formatting, content, and safety rules
├── paper-note-contract.md    # Paper note specific workflow
├── study-note-contract.md    # Study note specific workflow
└── templates/
    ├── paper-note.md         # Paper note template
    └── study-note.md         # Study note template
```

## Installation

From the repo root, run `./install.sh` (or `./install.sh verify-note`). See the [root README](../../README.md) for user- vs project-level options.

## Recommended permissions

Add to `.claude/settings.local.json` for smoother operation:

```json
{
  "permissions": {
    "allow": [
      "Bash(unzip:*)",
      "Bash(zip:*)",
      "Bash(mkdir:*)",
      "Bash(ls:*)",
      "Bash(pdftoppm:*)",
      "Bash(/usr/bin/convert:*)",
      "WebFetch(domain:arxiv.org)"
    ]
  }
}
```

## Security: review URLs before allowing fetches

During verification, the skill may fetch URLs — downloading papers from arXiv, searching for documentation, etc. Claude Code will prompt you for permission before fetching any URL not in your pre-approved list.

**Do not blindly approve all fetch requests.** Before allowing a fetch:
- Check that the URL points to a legitimate source (e.g., `arxiv.org`, official documentation sites).
- Be cautious with URLs found inside notes — they may be outdated, broken, or point to unexpected destinations.
- If a URL looks suspicious, deny the request and provide the correct source manually.

The recommended permissions above only pre-approve `arxiv.org`. All other domains will require your explicit approval each time, which is intentional.
