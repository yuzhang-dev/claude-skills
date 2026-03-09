# claude-skills

A personal collection of skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Each skill lives under [`skills/`](skills/) and installs as a **symlink**, so edits in this repo go live immediately — no re-copy needed.

## Skills

| Skill | What it does |
|-------|--------------|
| [verify-note](skills/verify-note) | Verify and clean up markdown notes (paper or study notes) by cross-checking claims, equations, and numbers against sources via a three-agent pipeline (proposer → challenger → judge). Supports a `--fast` token-saving mode. |

## Install

```bash
git clone https://github.com/<you>/claude-skills.git
cd claude-skills

./install.sh                       # user-level: ~/.claude/skills (all skills)
./install.sh verify-note           # user-level, a single skill
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
