---
name: pickup
description: Restore the previous session's handoff document in a fresh context and continue the work. The counterpart to the `handoff` skill, run after /clear. Explicit-invocation only — do NOT auto-activate when the user says "continue", "pick up where we left off", or starts a session.
---

You are restoring a previous session's working state into this fresh context. The user input is: `$ARGUMENTS` — optionally a slug or filename to load a specific handoff, and/or an instruction that overrides the handoff's next step.

## 1. Locate

```bash
ls -t .claude/handoff/*.md 2>/dev/null | head -5
ls -t docs/handoff/*.md 2>/dev/null | head -5
```

- Nothing in either? Tell the user no handoff exists in this project and stop. Do not guess at what they were doing, and do not reconstruct from `git log` — a guess presented as restored state is worse than nothing.
- Otherwise read the newest file in full.
- If `$ARGUMENTS` names a file or a slug (`/pickup parser-rewrite`), read that one instead.

Handoffs are chained: frontmatter carries `slug`, `seq`, `previous`, `date`, `head`, `branch`. If the newest one references decisions you cannot follow, read one more link back via `previous:`. Two is almost always enough — do not walk the whole chain.

Expect these sections: Goal · Where we are · In flight · What we tried that did not work · Key decisions · Blocked / open questions · Next step · Quick start. A section reading `none` or `unknown — not recoverable from this session` is deliberate, not damage.

## 2. Check for drift

The handoff describes the repo as it was. Confirm that is still true:

```bash
git rev-parse --short HEAD 2>/dev/null
git status --short 2>/dev/null
git log --oneline <recorded-head>..HEAD 2>/dev/null
```

Three cases:

- **HEAD unchanged, working tree matches** — the handoff is live, proceed.
- **HEAD moved** — commits landed since it was written. Read that log range and tell the user what changed before doing anything; some of the "next steps" may already be done.
- **Files named in the handoff no longer exist, or the recorded HEAD is unknown to git** — say so plainly. Treat the handoff as history, not as instructions.

Verify before trusting: if the handoff says a file is mid-edit, open it and confirm. A handoff written before a crash or a `git checkout` can be wrong.

### Live work is drift too

Git sees the disk, not what is still running. The handoff's **In flight** section
names subagents, background tasks and remote jobs; check them before anything
else, because a stale one is burning tokens right now:

```
ListAgents
```

- **Still `busy`, started before the handoff** — it has been running unread ever
  since. Ask the user whether to collect the result (`SendMessage`) or stop it
  (`TaskStop`). Do not silently leave it running.
- **Not listed** — it finished, died, or is not addressable from this session.
  Absence is not delivery: say which you think it is, and never report its
  result as if you had it.
- **`In flight` says `none` but the prose mentions a pending result** — the
  handoff predates this section, or its author forgot. Check anyway.

`ListAgents` covers peer sessions and this session's own subagents. One spawned
by a context that has since been cleared can still be alive without appearing
there — when the handoff names a runner the listing does not show, fall back to
`ps aux | grep -i claude` before concluding it is gone.

## 3. Orient the user

Report back, briefly:

- **Where we were** — the goal and current state, 2–4 lines.
- **What changed since** — drift from step 2, or "nothing changed since the handoff".
- **Still running** — anything from **In flight** that is alive, and what you propose doing with it. Omit the line only when there was nothing.
- **Known dead ends** — the failed-attempts list, compressed to one line each. State these explicitly; they are the reason to read the handoff at all.
- **Next step** — the single concrete action the handoff points at, and the command or file to start with.
- **Open questions** — anything the previous session left for the user to decide. Ask these now, before working.

Keep this under ~20 lines. It orients; it is not a re-read of the document.

## 4. Continue

Unless the user asked for something else, start on the next step. Do not re-derive decisions the handoff already records, and do not retry a listed failed approach without saying why this time is different.

If `$ARGUMENTS` carries an instruction (`/pickup actually let's fix the tests first`), it wins over the handoff's next step.
