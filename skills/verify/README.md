# verify

A **pure markdown rule-based skill** for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It runs a multi-agent verification over a target — a claim, a result table, code, a document, a note — and applies only what survives.

The skill ships the **mechanism** and nothing else. What gets verified, against what evidence, and where the output goes is the **project's** business, declared in a protocol document inside the project.

## Usage

```
/verify <target>                      # 3 agents, project default protocol
/verify 5 <target>                    # 5 agents: two opposed tracks + shared judge
/verify 3 <protocol> <target>         # a named protocol from the project
```

Bare words before the target configure the run and may appear in any order: `3` or `5` sets the agent count (default `3`), any other bare word names a protocol, everything else is the target.

```
/verify docs/paper_full.md §3.7
/verify 5 ib_3dgs/encoder.py
/verify 3 results results/aggregated/round1a_scene0494.md
/verify judgment "Opacity Crush should replace GA"
```

## The protocol lives in the project

The skill looks for, in order:

1. `docs/VERIFY-PROTOCOL.md`
2. `.claude/verify-protocol.md`
3. a `## Verify` section in the project's `CLAUDE.md`

Each `## <name>` inside is one protocol; a `Default: <name>` line picks the one used when the invocation names none.

A protocol sets: the target kind, the sources of truth and the order to try them, how many roles independently read the source, which model each role uses, the verdict vocabulary, where output is written, the project's known traps, and batching and stop rules. It cannot weaken the discipline in [`method.md`](method.md).

**With no protocol document**, the skill still runs — it verifies against whatever source of truth it can identify and **reports findings without editing anything**. Applying edits requires a protocol that says to.

## Three agents, and why the challenger matters

1. **Proposer** — finds candidate errors, each with quoted evidence from the source and a confidence rating.
2. **Challenger** — re-verifies the **majority** of the proposer's items, not just the contested ones, *and* adversarially re-reads the whole target for what the proposer missed. Killing the proposer's false positives matters as much as confirming real errors: without a second independent read, a misread table cell becomes an applied "fix".
3. **Judge** — re-checks both sides against the source, confirms the cited evidence actually exists, and rules confirmed / false alarm / flag-for-user. It emits verbatim edits but never applies them.

How isolated the roles are from each other is the **execution mode**:

| Mode | How it runs | Isolation | Cost |
|---|---|---|---|
| `isolated` (default) | one sub-agent per role, in sequence; each gets the target plus the previous stage's findings file, never the previous agent's reasoning | full | N spawns, main session orchestrates |
| `nested` | the main session spawns one agent that runs the whole pipeline, spawning the role agents itself; main context sees only the verdict | full between roles | needs sub-agents to be able to spawn sub-agents — test before relying on it |
| `solo` | one sub-agent plays every role in sequence in one context | none | cheapest |

A sub-agent cannot clear its own context, so "one agent that resets between roles" is not available; `isolated` is its working equivalent — fresh agent per stage, only the findings file carried across.

`solo` produces the *appearance* of adversarial review: the roles share one context, one set of blind spots, and the challenger reads the proposer's reasoning rather than only its conclusions. It is allowed where an external ground truth (a number, a table cell, a test result) is what every role must return to anyway. **Never for a judgement target** — with nothing external to re-read, isolation is the only thing generating the opposition.

## Five agents

Two opposed tracks — one starting from "this is correct", one from "this is wrong", each with its own challenger — then a single judge over all four. The opposing priors are *assigned* rather than left to emerge, which is what makes the method work on targets with no external ground truth to re-read: a design decision, a proposed theorem, a value or feasibility call.

Order: both proposers in parallel -> both challengers in parallel -> judge alone.

## Token efficiency is not a mode

It applies to every run. The savings come from *how* evidence is read, never from skipping a read:

- **Read text, not page images.** `Read`-ing a PDF renders every page as an image, roughly 10x the tokens of the same text. Fallback chain: ar5iv -> native arXiv HTML -> `pdftotext -layout` -> `pdftoppm` single-page render for figures only.
- **Stage the source once in the main context.** `cp` + `pdftotext` are bash and near-free; sub-agents get a local path, so all roles read identical text and nobody re-fetches.
- **Every role is a sub-agent that persists its findings to disk.** Source reads stay in its context, the main loop sees only verdicts, and a crashed batch resumes from the JSON.
- **Per-role models.** A cheaper model for the proposer, the strongest for challenger and judge, is a common split — but the protocol decides.

How many roles independently read the source is the one knob that is never turned down to save tokens.

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
