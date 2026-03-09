# Study Note Contract

See `${CLAUDE_SKILL_DIR}/templates/study-note.md` for the full template.

For general learning notes (e.g., C++ templates, system design, algorithms). These notes don't follow a fixed section structure like paper notes.

## Required Sections

- **Declaration block** (`---` block with Description, Notion Note ID, Created, Updated, License)
- **References** section at the end (links to sources, documentation, books, etc.)
- **Verification Log** at the very end

## Content Sections

Free-form — organized however makes sense for the topic. No mandatory numbered sections.

## Workflow

### Step 1: Read the note

Understand the topic and scope.

### Step 2: Gather reference material

Before verification, gather authoritative sources for the topic:
- Use `WebSearch` or `WebFetch` to find official documentation, authoritative references, and tutorials.
- Verify code examples compile/run correctly if possible.

### Step 3: Run the Three-Agent Verification Pipeline

Follow the **Three-Agent Verification Pipeline** in `${CLAUDE_SKILL_DIR}/contract.md` (or its **Fast Mode** variant if `--fast` was requested). The agents should use official documentation and authoritative references as their primary evidence sources. Specifically, the **Proposer** agent should check:

- Claims, code snippets, and explanations against official docs.
- Code correctness (syntax, API usage, deprecated features).
- Conceptual accuracy and completeness.

### Step 4: Apply confirmed corrections and improve

After the pipeline produces the final list of confirmed errors:

- Apply all confirmed corrections to the note.
- Present flagged items to the user for decision.
- Make the note more concise where verbose. Add missing key concepts or steps.
- Ensure code snippets have language identifiers on fenced blocks.
- **Inline references**: for each important point verified as correct, attach one or two reference links (e.g., official docs, cppreference, MDN, authoritative tutorials) near the relevant sentence or section.

### Step 5: Produce the verification log

See `${CLAUDE_SKILL_DIR}/contract.md` for the common verification log format. Evidence column should link to documentation or authoritative sources. Only include confirmed errors from the judge.

### Step 6: Apply and report

See `${CLAUDE_SKILL_DIR}/contract.md` for the common final step.
