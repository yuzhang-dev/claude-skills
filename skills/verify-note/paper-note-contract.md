# Paper Note Contract

See `${CLAUDE_SKILL_DIR}/templates/paper-note.md` for the full template.

## Required Sections

- **Declaration block** (`---` block with Description, Notion Note ID, Created, Updated, License)
- **1. Paper Information** (Title, Authors, Paper link with conference/venue name if published, Code link)
- **2. Summary**
- **3. Key Contributions**
- **4. Background & Related Work**
- **5. Method Details & Key Equations**
- **Conclusions & Future Work** (numbering may shift based on optional sections)

## Optional Sections (add based on the paper)

- **Training Setup & Datasets** — add for ML/AI papers
- **Main Experiments & Quantitative Results** — add when the note covers experiments
- **Ablations, Limitations & Practical Pointers** — add when relevant

## Workflow

### Step 1: Read the note

Understand its scope. Identify the paper (title, arXiv ID, authors).

### Step 2: Obtain the paper for verification

Try the following in order:
1. **Local PDF**: Check if the user provided a PDF path alongside the note, or if a PDF exists in the same directory.
2. **arXiv fetch**: If the note contains an arXiv ID, fetch the PDF from `https://arxiv.org/pdf/XXXX.XXXXX` (arxiv.org is a pre-approved domain).
3. **Ask the user**: If neither is available, ask the user to provide the paper (PDF path or URL).

Once obtained, read it per `${CLAUDE_SKILL_DIR}/evidence.md`:

- **Prefer text over page images.** Descend the fallback chain: ar5iv -> native arXiv HTML
  -> `pdftotext -layout` -> `pdftoppm` single-page render for figures only. `Read`-ing a
  whole PDF renders every page as an image and costs roughly 10x the tokens of the same
  text; it is the last resort, not the first move.
- **Stage the text once in the main context** (`pdftotext` is bash, near-free) and hand
  sub-agents the local `.txt` path, so all agents read identical text.
- Run the pipeline roles as sub-agents, each persisting its findings to disk before
  returning.

### Step 3: Run the Three-Agent Verification Pipeline

Follow the **Three-Agent Verification Pipeline** in `${CLAUDE_SKILL_DIR}/contract.md` (at the risk tier chosen per its *Read depth* table; `--fast` requests the LOW tier and is refused where that table forbids it). The agents should use the fetched paper PDF as their primary evidence source. Specifically, the **Proposer** agent should check:

- **Paper metadata**: title, authors, arXiv ID, code link. **Diff the author byline
  against the real author list, character by character** — this is the single highest-yield
  check in the whole pipeline (see `rules.md`, High-Risk Error Patterns). Content-focused
  reads skip the byline, so fabricated authors survive pass after pass.
- **Summary & contributions**: against the paper's actual claims.
- **Method & equations**: every equation, reconstruct broken LaTeX.
- **Experimental results**: numbers against paper tables/figures. Re-read any table a
  finding depends on at a text rung (`pdftotext -layout`) — misreading a per-sequence cell
  as the average, or quoting a best-case oracle row as the end-to-end result, are the two
  classic false findings.
- **Missing content**: key concepts/steps the note omits.

### Step 4: Apply confirmed corrections, improve, and add figures

After the pipeline produces the final list of confirmed errors:

- Apply all confirmed corrections to the note.
- Present flagged items to the user for decision.
- **Figures**: extract or reference key figures/tables from the paper. Save in the note's image subfolder (e.g., `note-name/image.png`, `note-name/image 1.png`).
- **Extracting figures/tables from PDFs:** Use `pdftoppm` to render the relevant page as PNG, then crop with `/usr/bin/convert` (ImageMagick — use full path, as `/usr/local/bin/convert` may shadow it). Example: `pdftoppm -png -f 12 -l 12 -r 200 paper.pdf output_prefix` then `/usr/bin/convert output.png -crop WxH+X+Y +repage "image N.png"`. Verify the crop visually with the `Read` tool before including.
- **Writing**: make the note more concise where verbose. Ensure consistent section numbering per template.

### Step 5: Produce the verification log

See `${CLAUDE_SKILL_DIR}/contract.md` for the common verification log format. Only include confirmed errors from the judge.

### Step 6: Apply and report

See `${CLAUDE_SKILL_DIR}/contract.md` for the common final step.
