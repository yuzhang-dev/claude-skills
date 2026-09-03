# claude-skills

A personal collection of Claude Code skills. Each skill lives under `skills/<name>/`. Currently:

- **verify** — multi-agent verification (3 agents, or 5 in two opposed tracks) over any target. Ships the mechanism; each project declares its own protocol in a `VERIFY-PROTOCOL.md`.
- **tldr** — terse, information-dense output mode. Explicit invocation only.
- **handoff** — write a session handoff document before `/clear`.
- **pickup** — restore a handoff document in a fresh session and continue.

## Installation

Skills install as symlinks (edits in this repo go live immediately — no re-copy). From the repo root:

```bash
./install.sh                       # user-level: ~/.claude/skills (all skills)
./install.sh verify                # user-level, a single skill
./install.sh --project             # project-level: ./.claude/skills (current dir)
./install.sh --project <proj-dir>  # project-level at a given project
```

Override the destination with `CLAUDE_SKILLS_DIR`. After installing, restart Claude Code (or run `/skills`).

## Usage

```
/verify <target>                      # 3 roles, mode a, project's default protocol
/verify 5 <target>                    # 5 roles: two opposed tracks + shared judge
/verify 3 <protocol> <target>         # a named protocol from the project
/verify 3 s <protocol> <target>       # execution mode: a (agent) / s (sequential) / r (role)

/handoff        # write a handoff doc to .claude/handoff/, then /clear
/pickup         # in the fresh session: restore it and continue
```

## verify: mechanism here, policy in the project

The skill ships two files — `SKILL.md` (parse args, find the protocol, route) and `method.md` (agent wiring, evidence reading, findings discipline). It does **not** ship taxonomies of what to verify.

Each project declares its own protocols in `VERIFY-PROTOCOL.md`, under whichever of `docs/`, `contracts/` or the repo root it keeps process documents in (fallbacks: `.claude/verify-protocol.md`, or a `## Verify` section in the project's CLAUDE.md). One `## <name>` per protocol, plus a `Default: <name>` line. A protocol sets the target kind, sources of truth, agent count and execution mode, how many roles read the source independently, per-role models, verdict vocabulary, output location, project traps, and stop rules. It cannot weaken `method.md`.

With no protocol document the skill still runs, but **reports findings without editing anything**.

This repo ships **no protocols**. A protocol belongs to the repo it governs and is written by reading what that repo already does, not by importing a taxonomy from here. Keep it that way: no project names, paths, or domain specifics in this repo.

The shape that works, for a protocol document anywhere: one `## <name>` per protocol, and under each one the target kind, the sources of truth **in the order to try them**, the role count and execution mode, where output goes, and the traps that project has actually been bitten by. The traps are the most valuable part and the part a general skill can never supply.

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
      "Bash(pdftotext:*)",
      "Bash(pdftoppm:*)",
      "Bash(/usr/bin/convert:*)",
      "WebFetch(domain:arxiv.org)",
      "WebFetch(domain:ar5iv.labs.arxiv.org)"
    ]
  }
}
```
