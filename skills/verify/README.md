# verify

A **pure markdown rule-based skill** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It runs a multi-agent verification over a target — a claim, a result table, code, a document, a note — and applies only what survives.

The skill ships the **mechanism** and nothing else. What gets verified, against what evidence, and where the output goes is the **project's** business, declared in a protocol document inside the project.

## Usage

```
/verify <target>                      # 3 roles, mode a, project default protocol
/verify 5 <target>                    # 5 roles: two opposed tracks + shared judge
/verify 3 <protocol> <target>         # a named protocol from the project
/verify 3 s <protocol> <target>       # sequential mode: one fresh agent per stage
```

Bare words before the target configure the run and may appear in any order: `3` or `5` sets the agent count (default `3`); `a` / `s` / `r` (or `agent` / `sequential` / `role`) sets the execution mode (default `a`); any other bare word names a protocol; everything else is the target. The reserved words cannot be protocol names.

```
/verify docs/spec.md §3.7
/verify 5 src/encoder.py
/verify 3 tables results/summary.md
/verify 3 s claims docs/design.md
/verify 3 r tables results/summary.md
/verify claims "the new sampler should replace the old one"
```

## The protocol lives in the project

The skill looks for, in order:

1. `VERIFY-PROTOCOL.md` in `docs/`, `contracts/`, or the repo root — wherever the project keeps its process documents
2. `.claude/verify-protocol.md`
3. a `## Verify` section in the project's `CLAUDE.md`

Each `## <name>` inside is one protocol; a `Default: <name>` line picks the one used when the invocation names none.

A protocol sets: the target kind, the sources of truth and the order to try them, how many roles independently read the source, which model each role uses, the verdict vocabulary, where output is written, the project's known traps, and batching and stop rules. It cannot weaken the discipline in [`method.md`](method.md).

**With no protocol document**, the skill still runs — it verifies against whatever source of truth it can identify and **reports findings without editing anything**. Applying edits requires a protocol that says to.

### Writing one

```markdown
Default: <name>

## <name>

**Target:** what this protocol verifies.
**Roles:** 3 or 5, and the execution mode, with the reason.
**Sources of truth, in order:** the artifacts a role must open, most authoritative first.
**Traps:** the mistakes this project has actually made, and what to check because of them.
**Output:** where the verdict goes, and where per-role findings go.
```

The traps section is the most valuable part and the part a general skill can never supply — it is written from what the project got wrong before, not from what a verifier should do in principle. Two rules of thumb: name the *frozen* copy of a config rather than the editable one, and where a target is a judgement call with nothing to re-open, forbid mode `r` explicitly.

## Three agents, and why the challenger matters

1. **Proposer** — finds candidate errors, each with quoted evidence from the source and a confidence rating.
2. **Challenger** — re-verifies the **majority** of the proposer's items, not just the contested ones, *and* adversarially re-reads the whole target for what the proposer missed. Killing the proposer's false positives matters as much as confirming real errors: without a second independent read, a misread table cell becomes an applied "fix".
3. **Judge** — re-checks both sides against the source, confirms the cited evidence actually exists, and rules confirmed / false alarm / flag-for-user. It emits verbatim edits but never applies them.

The order never changes: proposer alone, then challenger on the proposer's finished output, then judge on both. A mode changes only how isolated the stages are, never their order — the only thing that ever overlaps is the two independent tracks of a 5-agent run.

How isolated the roles are from each other is the **execution mode**:

| Mode | Contexts | Carried across a stage | Parallel | Isolation |
|---|---|---|---|---|
| `agent` / `a` (default) | one sub-agent per role | the previous stage's findings | the two tracks of a `5` run only | full |
| `sequential` / `s` | one agent alive at a time, spawned fresh per stage | the findings **file path**, nothing else | nothing, ever | full, and enforced |
| `role` / `r` | one sub-agent, one context, roles rotate | everything | n/a | none |

A sub-agent cannot clear its own context — there is no such tool — so `s` is the working form of "reset between roles": a fresh spawn per stage, seeded with the target and a file path and nothing else, so no stage can lean on a predecessor's paraphrase. Lowest peak context of the isolated forms, slowest, since nothing overlaps.

`r` produces the *appearance* of adversarial review: the roles share one context, one set of blind spots, and the challenger reads the proposer's reasoning rather than only its conclusions. It is allowed where an external ground truth (a number, a table cell, a test result) is what every role must return to anyway. **Never for a judgement target** — with nothing external to re-read, isolation is the only thing generating the opposition.

## Five agents

Two opposed tracks — one starting from "this is correct", one from "this is wrong", each with its own challenger — then a single judge over all four. The opposing priors are *assigned* rather than left to emerge, which is what makes the method work on targets with no external ground truth to re-read: a design decision, a proposed theorem, a value or feasibility call.

Order: both proposers in parallel -> both challengers in parallel -> judge alone.

## Token efficiency is not a mode

It applies to every run. The savings come from *how* evidence is read, never from skipping a read:

- **Read text, not page images.** `Read`-ing a PDF renders every page as an image, roughly 10x the tokens of the same text. Fallback chain: ar5iv -> native arXiv HTML -> `pdftotext -layout` -> `pdftoppm` single-page render for figures only.
- **Stage the source once in the main context.** `cp` + `pdftotext` are bash and near-free; sub-agents get a local path, so all roles read identical text and nobody re-fetches.
- **Every role is a sub-agent that persists as it goes.** Source reads stay in its context and the main loop sees only verdicts — and an agent that dies mid-pass loses nothing, because it has been appending since its first record.
- **Per-role models.** A cheaper model for the proposer, the strongest for challenger and judge, is a common split — but the protocol decides.

How many roles independently read the source is the one knob that is never turned down to save tokens.

## Surviving a dead sub-agent

A sub-agent that runs out of budget mid-pass returns nothing, and everything it read is gone. So findings are written **incrementally, from the first record**, as JSONL (a truncated object is unparseable; a truncated JSONL loses one line) — and alongside the findings, a **coverage record per unit checked**, including the clean ones. Without coverage a resume cannot tell "checked and fine" from "never reached", so it redoes the clean parts, which are most of them.

Output goes to `<state-dir>/verify/<key>.<stage>.jsonl` — state directory set by the protocol, defaulting to `.claude/verify/` in the project root, never the session scratchpad, since surviving into the next session is the whole point. A `<key>.status.json` records which stage is running and when it last checkpointed, so a dead stage is visible as dead rather than as never-run. Every role is told to read its own partial output first and continue from the last coverage record.

## Skill structure

```
verify/
├── SKILL.md    # Entry point: parse args, find the project protocol, route
└── method.md   # The mechanism: agent wiring, evidence reading, findings discipline
```

## Installation

From the repo root, run `./install.sh` (or `./install.sh verify`). See the [root README](../../README.md) for user- vs project-level options.

## Recommended permissions

```json
{
  "permissions": {
    "allow": [
      "Bash(pdftotext:*)",
      "Bash(pdftoppm:*)",
      "Bash(unzip:*)",
      "Bash(zip:*)",
      "WebFetch(domain:arxiv.org)",
      "WebFetch(domain:ar5iv.labs.arxiv.org)"
    ]
  }
}
```

## Security: review URLs before allowing fetches

Verification fetches sources. Claude Code prompts before fetching any URL not on your pre-approved list — do not blindly approve. Check the URL points at a legitimate source, be cautious with URLs found *inside* the target being verified, and deny anything suspicious rather than letting it into the evidence chain.
