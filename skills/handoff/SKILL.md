---
name: handoff
description: Write a session handoff document before /clear, so a fresh session can pick the work up. Restoring one is the separate `pickup` skill. Explicit-invocation only — do NOT auto-activate when the user merely mentions "handoff", "continue later", or ends a session.
---

You are writing a handoff document for this session. The user input is: `$ARGUMENTS` — if non-empty, it is a hint about what to emphasize (e.g. `/handoff focus on the parser bug`), not a file path.

Read `${CLAUDE_SKILL_DIR}/template.md` for the document format, then follow the steps below.

The reader of what you write is a fresh session with an empty context, restoring it via the `pickup` skill.

## 1. Gather

Run these in one batch — they are independent:

```bash
date +%Y-%m-%d-%H%M
git rev-parse --short HEAD 2>/dev/null
git branch --show-current 2>/dev/null
git status --short 2>/dev/null
git diff --stat 2>/dev/null
git log --oneline -10 2>/dev/null
ls -t .claude/handoff/*.md 2>/dev/null | head -3
```

Not a git repo? Skip the git fields and say so in the document — do not fabricate a HEAD.

Then read the conversation itself. That is the primary source; git only tells you what landed on disk, not what was decided, rejected, or discovered. Pull out:

- What the user actually asked for, in their words, including scope changes mid-session.
- Decisions and their reasons — especially ones that took discussion to reach.
- Approaches tried that failed, with the concrete error or reason.
- Anything the user corrected you on. These are the highest-value lines in the whole document.
- Open questions you were about to ask.

If prior handoffs exist, read the newest one. This handoff continues that chain: reuse its slug, set `previous:` to its filename, and increment `seq`. Do not repeat its content — carry forward only what is still live, and mark what has since been resolved.

## 2. Judge what survives

The test for every line: **would the next session do something different for not knowing this?** If no, cut it.

Cut aggressively:

- Anything `git log` / `git diff` already says. Record the commit hash as an anchor instead.
- Narration of work that succeeded and is now settled. The code is the record.
- Restating the project's stack, conventions, or layout — CLAUDE.md and the repo cover that.

Keep even when it feels obvious:

- Failed approaches and their errors.
- Why a plausible-looking alternative was rejected.
- Environment facts that cost time to discover (a flag, a port, a service that must be running, a test that is flaky).
- The exact command to reproduce whatever you were mid-way through.

## 3. Write

Follow `template.md` exactly. Fill every section; write `none` or `unknown — not recoverable from this session` rather than deleting a heading.

Write to `.claude/handoff/<stamp>-<slug>.md`, creating the directory if needed. The stamp comes from `date +%Y-%m-%d-%H%M` — never guess it. The slug is 2–4 kebab-case words naming the work stream, reused across a chain so related handoffs sort together.

Many projects gitignore `.claude/`. That is usually what you want — handoffs are working state, not repo content. If the user asks for handoffs to be committed and shared, use `docs/handoff/` instead and tell them you switched.

Aim for 60–150 lines. If you are over, you are narrating instead of handing off — cut settled work, not failed attempts.

## 4. Report

Show the user:

- The path written.
- A 3–6 line summary of what the handoff says the next step is.
- The line to paste in the new session after `/clear`: `/pickup`

Then stop. Do not start new work — the user is about to clear. If something important is genuinely missing from the handoff, say so now rather than acting on it.

## Non-negotiables

- **Never invent state.** If the conversation was compacted and you cannot recover something, write `unknown — not recoverable from this session`. A blank you flagged is useful; a plausible guess is a trap that costs the next session an hour.
- **Failed attempts are the most valuable section.** Never drop it to save space.
- **Write for a reader with zero context.** No "as discussed", no "the file we were editing". Concrete paths, `file.py:42`.
