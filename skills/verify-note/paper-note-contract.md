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

Once obtained:
- Read the PDF with the `Read` tool (up to 20 pages per request, read in chunks).
- Use sub-agents (Agent tool) to parallelize verification of different sections when the paper is large.

### Step 3: Run the Three-Agent Verification Pipeline

Follow the **Three-Agent Verification Pipeline** in `${CLAUDE_SKILL_DIR}/contract.md` (or its **Fast Mode** variant if `--fast` was requested). The agents should use the fetched paper PDF as their primary evidence source. Specifically, the **Proposer** agent should check:

- **Paper metadata**: title, authors, arXiv ID, code link.
- **Summary & contributions**: against the paper's actual claims.
- **Method & equations**: every equation, reconstruct broken LaTeX.
- **Experimental results**: numbers against paper tables/figures.
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
