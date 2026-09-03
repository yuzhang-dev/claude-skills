# Evidence Handling

Applies to **every** run, thorough or fast. The governing principle:

> **Quality is never traded for tokens.** The savings come from *how* evidence is
> read, not from skipping verification.

## 1. Read text, not page images

Reading a PDF with the `Read` tool renders every page as an **image** — roughly an
order of magnitude more tokens than the same content as text. But never skip reading
the original just because no HTML render exists.

**Fallback chain.** Descend until one rung works. Record which one was used in the
report (and in the verification log's evidence column):

1. **ar5iv** — `https://ar5iv.labs.arxiv.org/html/<arxiv-id>`. Full text, equations,
   numbers and tables as plain text. First choice for anything on arXiv.
2. **Native arXiv HTML** — `https://arxiv.org/html/<arxiv-id>`, for Dec-2023+ papers
   where ar5iv failed to convert.
3. **`pdftotext` — the workhorse for non-arXiv papers.** Get the PDF (local copy, or
   a mirror: university page, publisher, Semantic Scholar) and convert:
   ```bash
   pdftotext -layout paper.pdf paper.txt   # -layout keeps table columns aligned
   ```
   Body, equations and tables all come out as text, as cheap to read as HTML.
4. **`pdftoppm` single-page render** — only for figures, or for math/tables that
   `pdftotext` garbled. Render just the page that needs eyes, then `Read` that PNG:
   ```bash
   pdftoppm -png -r 150 -f 5 -l 5 paper.pdf page   # page 5 only
   ```
   Still far cheaper than `Read`-ing the whole PDF.

A table that matters should be re-read at rung 3 even if rung 1 produced something:
ar5iv garbles table cells often enough that a `pdftotext -layout` cross-check has
already overturned real findings.

## 2. Stage the text once, in the main context

`cp` and `pdftotext` are bash — near-zero model tokens. Convert **once** in the main
context, write to a scratch file (e.g. `<scratch>/verify-txt/<note-slug>.txt`), and
hand sub-agents that local path. This avoids each agent re-fetching over a flaky
network and guarantees all of them read the exact same published text.

## 3. Run the agents as sub-agents; persist findings to disk

- **All three roles run as sub-agents** (Agent tool). PDF/HTML reads and web fetches
  stay in *their* context; the main loop receives only the structured verdicts. This
  is what keeps the main context flat across a multi-note batch.
- **Each agent writes its findings to a file before returning** —
  `<scratch>/verify/<note-slug>.<stage>.json`, stage ∈ {researcher, challenger, judge}.
  Terminals crash; persisted findings make a wave resumable without re-reading anything.
  Keys containing `/` become `__` in the filename (flat directory).
- **The judge's output carries the edits, but the judge never edits files.** For each
  confirmed error it emits an exact `old_string` (verbatim, unique in the note) plus
  `new_string`, in `{confirmed, false_alarms, flag_for_user}`.
- **Per-agent model override** is available on the Agent tool (`model`) and on
  Workflow `agent()` (`opts.model`) — it is not limited to `/model`. See the tiers below.
- When handing sub-agents a list of work, pass **explicit keys/paths, never index
  ranges** into a shared file. Agents mis-count ranges, which produces duplicated and
  skipped items.

## 4. Apply edits idempotently

Apply the judge's edits by counting occurrences of `old_string`:

- exactly 1 → replace;
- 0 occurrences but `new_string` already present → already applied, skip;
- anything else → report `MISSING` / `AMBIGUOUS` and resolve by hand.

Safe to re-run after a crash.

## 5. Batches run in waves

Do not fan out 60 notes at once. Run a few per wave, report, then the next wave. Keep
per-note tier and status in a ledger JSON so a fresh session resumes from it alone.
