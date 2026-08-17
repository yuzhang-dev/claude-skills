# pickup

A **pure markdown rule-based skill** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It restores a handoff document written by [`handoff`](../handoff) into a fresh session, checks whether the repo has moved since, and continues the work.

```
/handoff              # previous session: writes the document
/clear
/pickup               # here: reads it back and continues
```

Named `pickup` rather than `resume` deliberately: Claude Code's built-in `/resume` restores a past session verbatim from a list. This restores a *document* into a clean context — a different mental model, so it gets a different verb.

## Usage

```
/pickup                                    # newest handoff in this project
/pickup parser-rewrite                     # a specific work stream, by slug or filename
/pickup actually let's fix the tests first # restore, then override the next step
```

## What it does

1. **Locate** — newest file in `.claude/handoff/`, falling back to `docs/handoff/`. If none exists it says so and stops; it will not reconstruct a plausible-looking state from `git log`.
2. **Check drift** — compares the handoff's recorded `head` against the current one. If commits landed since, it reads that log range and reports what changed before touching anything, because some of the recorded "next steps" may already be done. If files named in the handoff are gone, it treats the document as history rather than instructions.
3. **Orient** — under ~20 lines: where we were, what changed since, known dead ends, the next step, and any open question the previous session left for you. Open questions get asked before work starts, not after.
4. **Continue** — starts on the next step, without re-deriving recorded decisions or silently retrying a listed failed approach.

Step 2 is the part most handoff tooling skips. A handoff is a claim about the repo at a past moment; between then and now you may have committed, rebased, or checked out a different branch, and acting on a stale document is worse than starting cold.

## Installed independently

This skill reads a documented file format — it does not import anything from `handoff/`, so installing it alone works fine (useful if one machine only ever restores). It expects the sections `handoff` writes: Goal · Where we are · What we tried that did not work · Key decisions · Blocked / open questions · Next step · Quick start.

## Installation

From the repo root, run `./install.sh handoff pickup` (or `./install.sh` for everything). See the [root README](../../README.md) for user- vs project-level options.

Recommended permissions are the same read-only git commands listed in the [handoff README](../handoff/README.md#recommended-permissions).
