# claude-skills

A personal collection of Claude Code skills. Each skill lives under `skills/<name>/`. Currently:

- **verify-note** — verify and clean up markdown notes. Supports paper notes (academic papers) and study notes (general learning topics).

## Installation

Skills install as symlinks (edits in this repo go live immediately — no re-copy). From the repo root:

```bash
./install.sh                       # user-level: ~/.claude/skills (all skills)
./install.sh verify-note           # user-level, a single skill
./install.sh --project             # project-level: ./.claude/skills (current dir)
./install.sh --project <proj-dir>  # project-level at a given project
```

Override the destination with `CLAUDE_SKILLS_DIR`. After installing, restart Claude Code (or run `/skills`).

## Usage

```
/verify-note path/to/note.md
/verify-note path/to/note.zip
/verify-note --fast path/to/note.md   # token-saving Fast Mode
```

## Workflow

1. **Generate initial notes** — write them yourself, find them on the web, or generate them with an LLM (ChatGPT, Claude, etc.).
2. **Verify and clean up** with `/verify-note` — runs a three-agent verification pipeline (proposer → challenger → judge).
3. Output goes back to the same directory as the input.

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
