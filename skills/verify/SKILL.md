---
name: verify
description: Run a multi-agent verification over a target — a claim, a result table, code, a document, a note. Three agents (proposer -> challenger -> judge) by default, five (two opposed tracks plus a shared judge) on request. Uses the project's own verification protocol when it defines one. Explicit-invocation only — do NOT auto-activate when the user merely says "verify", "check this", or "is this right".
---

You are running a multi-agent verification. The user input is: `$ARGUMENTS`

## 1. Parse the arguments

Bare words before the target select how the run is configured. Order does not matter.

- **`3` or `5`** — how many agents. Default `3` when neither appears.
- **`agent`/`a`, `sequential`/`s`, `role`/`r`** — execution mode (see `method.md` §3).
  Default `a`; the protocol may set a different default.
- **any other bare word** — the name of a protocol, whatever the project called it.
  Matched against the protocol document found in step 2. The words above are reserved and
  cannot be protocol names.
- **everything else** — the target: a path, a section reference, or a quoted proposition.

```
/verify docs/spec.md §3.7
/verify 5 src/encoder.py
/verify 3 tables results/summary.md
/verify 3 s claims docs/design.md
/verify 3 r tables results/summary.md
/verify claims "the new sampler should replace the old one"
```

If a bare word matches no protocol, do not guess — say which names are available and ask.

## 2. Find the protocol

The protocol says **what this project verifies, against what evidence, and where the
output goes**. It is the project's, not this skill's. Look in order, stop at the first hit:

1. `VERIFY-PROTOCOL.md`, in whichever of these the project actually uses for its process
   documents: `docs/`, `contracts/`, or the repo root.
2. `.claude/verify-protocol.md`
3. a `## Verify` section in the project's `CLAUDE.md`

One `ls` over those three directories settles it; do not guess from the repo's name or
language which one it will be.

Inside it, each `## <name>` is one protocol. A `Default: <name>` line names the one to use
when the invocation gives no name. If the document exists but has no matching section and
no default, list the available names and ask.

**No protocol document at all** — say so in one line, then run on the mechanism in
`method.md` alone: identify the source of truth, run the pipeline, and **report the
findings without editing anything.** Applying edits requires a protocol that says to.

A protocol may set: the target kind, the sources of truth and the order to try them, how
many agents and which execution mode, how many roles independently read the source, which
model each role uses, the verdict vocabulary, where the output is written, the project's
known traps, and the batching and stop rules. It may not weaken the discipline in `method.md` — that part is the mechanism.

## 3. Read the mechanism

Read `${CLAUDE_SKILL_DIR}/method.md` and follow it. It defines the agent wiring, how
evidence is read, and what happens to findings. It applies to every run.

## 4. Run, then report

Report: what was verified, which protocol, how many agents and in which execution mode,
which evidence rung was used, what was confirmed, what was dismissed as a false alarm, what is flagged for the
user, and where the findings were written.
