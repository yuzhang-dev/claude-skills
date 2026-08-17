# handoff

A **pure markdown rule-based skill** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It writes a session handoff document before you `/clear`. Its counterpart, [`pickup`](../pickup), reads that document back in the fresh session.

No hooks, no scripts, no background automation — you invoke both halves yourself.

## Why this exists

Claude Code's own continuity mechanisms cover the easy cases: `/resume` and `--continue` restore a session verbatim, and auto-compaction keeps a long session alive. None of them help when you deliberately start clean — a new machine, a new day, or a context that has drifted far enough that clearing is cheaper than compacting.

What survives that gap has to be a document, and the document has to be written on purpose. Handoffs earn their keep exactly when the session's value is not in the diff: the approaches that failed, the reason an obvious-looking alternative was rejected, the flag that took twenty minutes to find.

## The loop

```
/handoff              # end of session: writes .claude/handoff/<stamp>-<slug>.md
/clear
/pickup               # fresh session: reads it back, checks drift, continues
```

`/handoff` takes an optional hint (`/handoff focus on the parser bug`). `/pickup` takes an optional slug or instruction — see [its README](../pickup).

## Where handoffs live

`.claude/handoff/` in the current project, one file per handoff, named `<date>-<time>-<slug>.md`. `pickup` reads the newest (`ls -t`).

Most projects gitignore `.claude/`, which is usually right — handoffs are working state, not repo content. Ask for `docs/handoff/` instead if you want them committed and shared across machines; both skills look there too.

Handoffs chain: each records `previous:` and a `seq:`, and reuses the slug of the work stream it continues, so a multi-day thread stays readable in order.

## Document structure

Fixed sections, defined in [`template.md`](template.md):

| Section | Holds |
|---|---|
| Goal | What the user wants, in their framing, plus the acceptance condition |
| Where we are | Concrete state — what works, what is half-built, at `path:line` |
| **What we tried that did not work** | Each abandoned approach with its actual error |
| Key decisions | The choice *and* the reason, including rejected alternatives |
| Blocked / open questions | Anything needing a decision or an external unblock |
| Next step | One concrete action, with the command to run |
| Quick start | A self-contained prompt that works with nothing else read |

The failed-attempts section is the one that earns the document's keep, and the skill is told never to drop it for length. Everything else is recoverable from the code or the git log; a dead end is not recorded anywhere except in the session that hit it.

## What the skill refuses to do

- **Invent state.** If context was compacted and something is unrecoverable, the slot says `unknown — not recoverable from this session`. A flagged blank costs the next session a question; a plausible guess costs it an hour.
- **Narrate.** Anything `git log` or `git diff` already says gets cut in favor of a commit hash as an anchor. The target is 60–150 lines.
- **Keep working after writing.** You are about to `/clear`; the skill reports the path and stops.

## Skill structure

```
handoff/
├── SKILL.md      # Entry point — gather → judge what survives → write → report
└── template.md   # Document format and rules
```

## Installation

From the repo root, run `./install.sh handoff pickup` (or `./install.sh` for everything). See the [root README](../../README.md) for user- vs project-level options.

## Recommended permissions

Add to `.claude/settings.local.json` to avoid prompts on the read-only inspection commands:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git rev-parse:*)",
      "Bash(git branch:*)",
      "Bash(date:*)",
      "Bash(ls:*)",
      "Bash(mkdir:*)"
    ]
  }
}
```

## Prior art

The design borrows from several existing handoff skills, which independently converged on the same core ideas — failed attempts as a first-class section, save and restore as separate commands, and the document written as a prompt rather than a report:

- [REMvisual/claude-handoff](https://github.com/REMvisual/claude-handoff) — chain-linked handoffs, PreCompact hook
- [thepushkarp/handoff](https://github.com/thepushkarp/handoff) — timestamped log in `docs/handoff/`, compaction hooks
- [392fyc/claude-handoff](https://github.com/392fyc/claude-handoff) — handoff as a self-contained starting prompt
- [chadthornton/reheat](https://github.com/chadthornton/reheat) — agent-agnostic, emphasis on documenting what failed

This pair differs in being manual-only by design, in splitting save and restore into two independently installable skills, and in treating drift detection on restore as a required step rather than an optional one.
