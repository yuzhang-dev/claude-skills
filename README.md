# claude-skills

A personal collection of skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Each skill lives under [`skills/`](skills/) and installs as a **symlink**, so edits in this repo go live immediately — no re-copy needed.

## Skills

| Skill | What it does |
|-------|--------------|
| [verify](skills/verify) | Run a multi-agent verification over a target — a claim, a result table, code, a document, a note. Three agents (proposer → challenger → judge) by default, five (two opposed tracks + shared judge) on request. Ships the mechanism only: *what* gets verified and against what evidence is declared by a protocol document inside the project being worked on. |
| [tldr](skills/tldr) | Switch responses to terse, information-dense output (keeps code, numbers, and technical terms exact). Explicit-invocation only — run `/tldr`. |
| [handoff](skills/handoff) | Write a session handoff document before `/clear` — goal, current state, failed attempts, decisions, next step — so a fresh session can pick the work up. |
| [pickup](skills/pickup) | The counterpart to `handoff`: restore that document in a new session, check whether the repo moved since it was written, and continue. |

## Install

```bash
git clone https://github.com/<you>/claude-skills.git
cd claude-skills

./install.sh                       # user-level: ~/.claude/skills (all skills)
./install.sh verify                # user-level, a single skill
./install.sh --project             # project-level: ./.claude/skills (current dir)
./install.sh --project /path/proj  # project-level at a given project
```

The installer symlinks each `skills/<name>/` into the destination, replacing any existing entry. Set `CLAUDE_SKILLS_DIR` to override the destination entirely. After installing, restart Claude Code (or run `/skills`) and invoke a skill as `/<skill-name>`.

## Adding a skill

1. Create `skills/<name>/` with a `SKILL.md` entry point (plus any contracts, rules, templates it needs).
2. Add a row to the table above.
3. Re-run `./install.sh` (or `./install.sh <name>`).

## License

[MIT](LICENSE)
