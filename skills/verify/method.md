# Method

The mechanism of a verification run: how the agents are wired, how evidence is read, and
what happens to a finding. It holds for every target and every protocol. The project's
protocol decides *what* is verified and against what; this file decides *how*.

Governing principle:

> **Quality is never traded for tokens.** The savings come from *how* evidence is read,
> not from skipping verification.

---

## 1. Three agents (default)

Three roles, **in sequence**. How isolated they are from each other is the execution mode
(§3); the default gives each its own context. A single agent writing three sections in one
context shares one set of blind spots — it is a real option, but the weak one, and §3 says
when it is allowed.

**Proposer.** Scrutinizes the target and proposes findings. For each one:
- State exactly what is wrong and where. Quote the original.
- Give evidence from the source of truth: the specific section, table, equation, line, or
  committed artifact. A finding with no locatable evidence is not a finding.
- Rate confidence **high** (direct contradiction with the source), **medium** (likely
  wrong, source indirect), or **low** (suspicious, unconfirmed).
- Technical and factual errors only. Style is not this pipeline's business.

**Challenger.** Receives the proposer's list. Two jobs, **both mandatory**:
- **Re-verify the majority of the items**, not only the contested-looking ones. A
  challenger that pushes only where the proposer hedged is too gentle. Its most valuable
  output is killing proposer **false positives** — a misread table cell, a number the
  source never states. Without a second independent read those wrong "fixes" get applied.
- **Adversarially re-read the whole target for what the proposer MISSED.** This is where
  "clean" verdicts get caught out. Omissions and misattributions surface here far more
  often than in the proposer's pass.

Mark each item **agree** / **dispute** / **needs more evidence**, with counter-evidence.

**Judge.** Receives both. For every disputed or uncertain item, plus every new
high-confidence finding the challenger raised:
- Re-verify the evidence from both sides independently against the source. **Confirm the
  cited evidence actually exists** — a fabricated or misdescribed citation is itself a
  finding, and a citation that inverts the argument it is used for is the common case.
- Rule: **confirmed** / **false alarm** / **flag for user**.
- For each confirmed item emit an exact verbatim `old_string` (unique in the file) plus
  `new_string`. The judge produces edits; it does not apply them.

A finding is a **proposal, not a verdict.** Nothing is written until the challenger and
the judge have re-checked it against the source.

## 2. Five agents (`5`)

Two opposed tracks run in parallel, then a single judge. Use it where the target has no
external ground truth to re-read — a design decision, a proposed theorem, a value or
feasibility judgement — because there the three-agent chain inherits the proposer's
framing and has nothing to check it against. It is also worth the cost on anything the
project is about to build on.

**Forward track** (starts from "this is correct"):
1. *Forward proposer* — assume every part of the target is correct; produce the evidence
   for each claim (tests, cited sections, committed numbers).
2. *Forward challenger* — assume it is all wrong; wait for the forward proposer, then
   rebut systematically and hunt for evidence-backed defects.

**Reverse track** (starts from "this is wrong"):
1. *Reverse proposer* — assume every part contains errors; search systematically. The
   more evidence-backed defects found, the better.
2. *Reverse challenger* — assume it is all correct; wait for the reverse proposer, then
   rebut each claimed error with counter-evidence, or concede it.

**Judge** — runs last, after all four. Independently verifies the evidence from all four
and rules on each disputed point.

**Order:** the two proposers run in parallel; when both finish, the two challengers run in
parallel; when both finish, the judge runs alone.

The point of the two tracks is that the opposing **priors** are assigned, not left to
emerge. That is what makes the method work when there is no data to re-read.

## 3. Execution modes

*How many* agents is `3` or `5`. *How they are run* is the execution mode. The protocol
picks one; an invocation can override it with a bare word. Default: **isolated**.

### `isolated` (default)

One sub-agent per role, spawned in sequence by the main session. Each receives the target
and the **previous stage's findings file** — not the previous agent's reasoning, not the
conversation. Strongest isolation: the challenger cannot inherit the proposer's framing
because it never sees it, only its conclusions and cited evidence.

Cost: N agent spawns, and the main session carries the orchestration.

### `nested`

The main session spawns **one** agent that runs the whole pipeline, itself spawning the
role agents. The main context sees only the final verdict, which keeps it flat across a
long batch.

Same isolation as `isolated` between the roles, cheaper for the main session, but it
depends on a sub-agent being able to spawn sub-agents. **Test that before a protocol
relies on it**; if nested delegation is unavailable, fall back to `isolated` and say so
rather than silently collapsing to `solo`.

### `solo`

One sub-agent plays every role in sequence in a single context, switching roles as it
goes. Cheapest by a wide margin, and the weakest form of the method: the roles share one
context, one set of blind spots, and one framing. The challenger sees the proposer's
reasoning rather than only its conclusions, so it tends to argue within it.

`solo` produces the *appearance* of adversarial review. Use it only where the target has
an external ground truth that every role must go back to anyway (a number, a table cell, a
test result), so the source, not the challenger's independence, does the work.

**Never `solo` for a judgement target** — a design decision, a proposed theorem, a value
or feasibility call. With nothing external to re-read, isolation is the only thing
generating the opposition, and removing it leaves a single opinion in three voices. The
known compensation for a `solo` run is a re-run by a **fresh agent with no prior context**
that replays all roles independently; if a protocol uses `solo` for anything consequential
it should require that second pass.

## 4. Evidence: read text, not page images

Reading a PDF with the `Read` tool renders every page as an **image**, roughly an order of
magnitude more tokens than the same content as text. But never skip reading the original
because no text render exists.

**Fallback chain.** Descend until one rung works; record which one in the report:

1. **ar5iv** — `https://ar5iv.labs.arxiv.org/html/<arxiv-id>`. Full text, equations,
   numbers, tables as plain text. First choice for anything on arXiv.
2. **Native arXiv HTML** — `https://arxiv.org/html/<arxiv-id>` (Dec-2023+ papers) when
   ar5iv failed to convert.
3. **`pdftotext` — the workhorse for everything not on arXiv:**
   ```bash
   pdftotext -layout paper.pdf paper.txt   # -layout keeps table columns aligned
   ```
   Body, equations and tables all come out as text, as cheap to read as HTML.
4. **`pdftoppm` single-page render** — only for figures, or math a text extraction
   garbled. Render just the page that needs eyes, then `Read` that PNG:
   ```bash
   pdftoppm -png -r 150 -f 5 -l 5 paper.pdf page   # page 5 only
   ```

**Stage it once, in the main context.** `cp` and `pdftotext` are bash, near-zero model
tokens. Convert once, write to a scratch file, and hand sub-agents that local path. No
agent re-fetches over a flaky network, and all of them read the identical text.

For a non-document target the same rule holds in its own terms: read the committed
artifact, not a summary of it. The JSON that produced the table, the test that proves the
behaviour, the config that was actually used.

## 5. Running the agents

- **Roles run in sub-agents, per the execution mode (§3).** Source reads and fetches stay
  in *their* context; the main loop receives only the structured verdicts. This is what
  keeps the main context flat across a batch.
- **Each agent writes its findings to a file before returning** —
  `<scratch>/verify/<key>.<stage>.json`. Terminals crash; persisted findings make a batch
  resumable without re-reading anything. Keys containing `/` become `__` in the filename.
- **Per-role model override** is available on the Agent tool (`model`) and on Workflow
  `agent()` (`opts.model`); it is not limited to `/model`. A common split is a cheaper
  model for the proposer and the strongest one for challenger and judge, but the protocol
  decides.
- **How many roles independently read the source is set by the protocol**, and it is the
  one knob that must never be turned down to save tokens. If the protocol is silent, all
  three read it.
- When handing sub-agents a list of work, pass **explicit keys and paths, never index
  ranges** into a shared file. Agents mis-count ranges, which duplicates and skips items.

## 6. What happens to a finding

- **Only confirmed items are applied.** False alarms are discarded.
- **`flag_for_user` is never auto-applied.** Report it with both sides and let the human rule.
- **Apply edits idempotently.** Count occurrences of `old_string`: exactly 1 -> replace;
  0 but `new_string` already present -> already applied, skip; anything else -> report
  `MISSING` / `AMBIGUOUS` and resolve by hand. Safe to re-run after a crash.
- **Re-verify after substantive edits.** If the corrections touched math, a formula, or a
  factual chain, run the full pipeline again on the corrected target (persist as `.v2`).
  This catches "fixed one place, left the related inconsistency": in the campaign this
  procedure came from, **7 of ~40 applied fixes were themselves wrong**.
- **A fabrication triggers a full re-run.** Fabrications cluster; one pass rarely catches
  them all.

### Recurring false findings — check these before applying

- **Tables are the misreading hotspot.** A per-sequence cell read as the average, or a
  best-case oracle row quoted as the end-to-end result. Re-read the table at a text rung
  before applying anything derived from it.
- **A citation used to invert its own argument.** Verify citations first-hand: quote the
  abstract or the numbered section, never a paraphrase.
- **"Wrong" versus "true but not from this source".** A correct fact that the source
  simply does not state is not a fabrication. The judge decides keep-versus-soften; it is
  never auto-deleted.
- **A pre-registered result outranks a post-hoc proxy.** If the claim has a committed
  pre-registration or an existing test, grep for it and read the result before arguing
  from anything derived.

## 7. Batches

- Run **a few per wave**, report, then the next wave. Do not fan out dozens at once.
- Keep per-item status in a ledger file so a fresh session resumes from it alone.
- **Between items, check remaining context.** Comfortably free -> continue; running low ->
  stop cleanly after finishing and persisting the current item. Never leave one
  half-applied. The protocol may set the exact threshold; absent one, stop at roughly 40%
  free, or after 5 items if no percentage is readable.
