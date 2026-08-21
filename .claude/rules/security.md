---
paths: ["**/*"]
---
# Security Rules (binding) — ADAPTED from the parent at L1

**Why this stopped being MIRRORED.** Through L0 this file was byte-identical to the parent's, which
meant it shipped references to machinery that does not exist here: an `arbiter` that recalibrates
severity, a `validate-crew.sh`, and a gate in the parent's own history. A public reader met that
contradiction three files from `release-protocol.md`, which says there is no arbiter. Byte-identity
is the wrong relation for a file whose content names its host.

**What survived the reclassification.** The severity table below is still byte-identical to the
parent's, and `scripts/check-sync.sh` asserts exactly that. Two builds that disagree about what
`crit` means cannot exchange findings, so the vocabulary is pinned even though the file is not.

## Severity definitions
Every FINDINGS entry carries exactly one. These are not adjustable per reviewer — the releasing
party recalibrates against this table before releasing.

| Severity | Definition |
|---|---|
| `crit` | Secret exposure, or widening of destructive capability — a new path by which data or infrastructure can be destroyed. |
| `high` | Weakening of a permission boundary or deny-list: anything that lets a previously blocked operation through. |
| `med` | Injection-adjacent — untrusted input reaching a position where it can influence control flow, without a demonstrated exploit. |
| `low` | Hygiene: naming, dead configuration, inconsistency with no security consequence. |

## Standing prohibitions
- **No absolute machine paths in tracked files.** Resolve through `$HOME` or `$CLAUDE_PROJECT_DIR`.
  `scripts/validate-lite.sh` substring-matches tracked files for an absolute home-directory prefix
  and is high-recall, low-precision on purpose. Consequence: do not write that literal token in
  tracked prose either — not even to document this rule. Describe it instead. The parent burned two
  red gates on exactly that mistake, which is why the rule is inherited rather than rediscovered.
- **No new allow-rules without a gate.** Any addition to `permissions.allow` in
  `.claude/settings.json` is a permission-boundary change: it needs operator approval at a gate,
  never a quiet commit.
- **Secrets never enter the repo.** `.env`, `secrets/` and `.ssh/` are blocked by
  `hooks/sensitive-guard.sh` and covered by `.gitignore`. A guard is not a substitute for not
  writing them in the first place.
- **A denial must leave a record.** Blocking without an audit line is a silent control. `deny()`
  writes a `PreToolUse.deny` entry carrying tool, target, reason and phase to
  `logs/deny-audit.jsonl`, and `validate-lite.sh` asserts that denials actually produced records.
  The parent's equivalent gate produced six live denials and zero records before this was enforced.

## Dismissal standard
A reviewer may dismiss a suspected issue only with a mitigation it has located and READ. "The
framework escapes it" or "the caller validates it" remains an assumption, and the finding stands.
