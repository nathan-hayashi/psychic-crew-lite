---
name: confluence-docs
class: standard
---
# confluence-docs — documentation review pack (P1a · P2a · P3a, under R-SP-1)

Reviews operator-exported documents and returns **proposals**. It never reaches Confluence, holds no
credentials, and publishes nothing.

## The three constraints, before the work

- **P1a — file-based intake only.** The operator exports a document and drops it in `inbox/`. There
  is no API call, no fetch, no crawl. If a document is not in `inbox/`, it does not exist.
- **P2a — no credentials, by construction.** The pack has nothing to authenticate with, so it cannot
  reach a live space even if instructed to. This is not a policy the pack obeys; it is a capability
  it lacks.
- **P3a — proposals only.** Every output is a file for a human to read and act on. Publishing is a
  manual step the operator performs in Confluence, from the routing line the pack writes.

**This repository is PUBLIC.** `inbox/`, `work/` and `out/` are gitignored on the pack root glob, so
a second pack inherits the protection on the day it is created. Never quote document content into a
tracked file — not into a ledger, not into a commit message, not as an example in this file. A
finding cites a location and describes the problem; it does not reproduce the text.

## Accepted inputs

Confluence storage-format export (`.html`/`.xml`), Google-Docs export (`.docx`/`.html`/`.md`), or
Markdown. Anything else: stop and say so, rather than guessing at a format.

## For EACH document in `inbox/`, produce four artifacts

1. **`work/<slug>.normalised.md`** — one working copy in Markdown. Headings, lists, tables and code
   blocks preserved; export cruft removed. Record what was dropped, so a reader can tell
   normalisation from editing.
2. **`out/<slug>.proposal.md`** — findings against `doc-standards.md`, grouped under **structure ·
   clarity · completeness · consistency**. Every finding carries a **severity** and a **concrete
   rewrite** — the replacement sentence or heading, not "consider clarifying". A finding without a
   rewrite is an opinion; a rewrite is a proposal.
3. **`out/<slug>.draft.md`** — the finalised draft with the accepted rewrites applied. This is what
   the operator would paste back, and it must stand alone.
4. **`out/<slug>.routing.md`** — exactly **one** line of:
   `ROUTE: INTERNAL-IT — <one-line justification>` or
   `ROUTE: EXTERNAL-PUBLIC — <one-line justification>`
   Choose one. Never both, never neither, never "either". The justification is the audience test the
   operator can disagree with; the routing is a proposal they act on manually.

## Severity vocabulary

`crit` · `high` · `med` · `low`, **the same four tokens `.claude/rules/security.md` defines**, with
the meanings adapted to documentation: `crit` a statement that is wrong or would cause harm if
followed; `high` a gap that blocks the reader's task; `med` friction that costs time; `low` polish.
No second scale — a pack inventing its own severity words makes two vocabularies that drift apart.

## Audit

Append one line per processed document to `logs/pack-confluence-docs.jsonl`:
`{ts, doc_slug, source_format, findings_by_severity, route, pack}`. It records the slug and counts,
**never document content**.

**That log is RUNTIME, not durable.** It is gitignored, lives on one machine, and does not travel to
a clone — the same split the continuity layer draws. If a record of pack activity ever needs to
survive, it goes through the durable checkpoint path, carrying counts and never text.

## Uncertainty

Below 0.6 on a load-bearing judgement, or an input whose format you cannot identify: return a
FALLBACK per `.claude/rules/fallback-protocol.md`. Do not guess at a document's audience — routing
is the one output where a wrong confident answer is worse than an admitted gap.
