# Handoff document format

Copy this structure verbatim. Section order is fixed — the `pickup` skill reads it in this order.

```markdown
---
slug: parser-rewrite
seq: 2
previous: 2026-08-15-1720-parser-rewrite.md
date: 2026-08-16 14:30
head: a3f91c2
branch: main
---

# Handoff — <one line naming the work, not the session>

## Goal

What the user is trying to achieve, in their framing. One short paragraph.
Include the acceptance condition: how we will know this is done.

## Where we are

Current state in 3–6 bullets. Concrete: what works, what is half-built, what is
untouched. Point at files with `path:line`.

- `src/parser/lexer.py:88` — new token table wired up, tests pass
- `src/parser/ast.py` — rewritten, NOT yet called by anything
- integration tests still on the old path, untouched

## What we tried that did not work

The most valuable section. One bullet per attempt: what, why it failed, the
actual error. Write `none` only if genuinely nothing was abandoned.

- Reusing `LegacyNode` as the base class — circular import between `ast.py` and
  `visitor.py`; import moves did not break it, the cycle is structural
- `pytest -k parser` for the fast loop — misses `tests/integration/`, gave a
  false green twice; use `pytest tests/ -k parser` instead

## Key decisions

Decision, and the reason that made it win. Include options rejected and why —
otherwise the next session relitigates them.

- Hand-written recursive descent over a generator — grammar is small and the
  error messages matter more than the generality
- Kept the old parser importable behind `USE_LEGACY_PARSER` until integration
  tests are ported; do not delete it yet

## Blocked / open questions

Things needing a decision or an external unblock. Empty is fine — write `none`.

- Should `parse()` raise or return a Result? User leaned toward raising, not confirmed.

## Next step

ONE concrete action, with the command or file to start from. Not a plan — the
single next thing.

Port `tests/integration/test_parse.py` to the new AST, starting at the
`test_nested_calls` case. Run: `pytest tests/ -k parser`

## Quick start

A self-contained prompt the next session could act on with nothing else read.
3–5 lines, absolute meaning, no references to "we" or "earlier".
```

## Rules

- Frontmatter fields are all required. `previous: none` and `seq: 1` for a first handoff. Omit `head`/`branch` only outside a git repo.
- The title names the work (`Handoff — parser rewrite, integration tests pending`), not the event (`Handoff — session 3`).
- Every claim about the codebase is a path, ideally with a line number. "The config file" is a defect.
- Never delete a heading. `none` is an answer; a missing section reads as an oversight.
- Dates and hashes come from `date` and `git`, never from memory.
