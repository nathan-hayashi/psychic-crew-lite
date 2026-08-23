# doc-standards.md — the checklist the pack reviews against

The reviewable ground truth. If a finding does not trace to a line here, it is a preference, and the
pack says so rather than dressing it as a standard.

## Structure
- One H1, stating what the document is for, not what it is called.
- Headings describe content, not ceremony ("Rolling back a failed deploy", not "Section 3").
- Prerequisites appear before steps, not inside them.
- A procedure's steps are numbered, and each step is one action a reader can complete and verify.

## Clarity
- The audience is identifiable from the first paragraph.
- Every acronym is expanded once, on first use.
- Instructions use the imperative and name the actor when it is not the reader.
- No sentence carries two instructions joined by "and" where a reader could do one and stop.

## Completeness
- Every procedure states its expected outcome and how to tell it failed.
- Access, permissions and prerequisites are named before they are needed.
- Every external reference resolves, and is named rather than pasted as a bare URL.
- Anything deliberately out of scope is stated, so absence reads as a decision.

## Consistency
- One term per concept throughout; synonyms are the enemy of search.
- Formatting of commands, paths and UI labels is uniform.
- Tense and person do not switch mid-document.
- Version and date claims agree with each other and with the document's own history.

## Findings
Each finding carries: the checklist line it traces to, a **severity**
(`crit` · `high` · `med` · `low`, defined in `.claude/rules/security.md` and adapted in `PACK.md`),
a **location** (heading or step number — never a quotation of internal content), and a **concrete
rewrite**. A finding with no rewrite is not a finding.
