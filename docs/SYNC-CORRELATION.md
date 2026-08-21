# SYNC-CORRELATION.md — parent ↔ Lite (plan §7.1)

Lite is a separate repository that must not silently drift from psychic-crew. This map is the
mechanism, and `scripts/check-sync.sh` is what stops it becoming documentation that rots.

## Relations

| Relation | Meaning | Enforcement |
| --- | --- | --- |
| `MIRRORED` | must stay byte-identical | content hash compared; **divergence FAILS** |
| `ADAPTED` | Lite deliberately differs | parent path must exist; a change upstream raises a **review obligation**, not a failure |
| `DROPPED` | considered absence | parent path must exist; recorded so nobody re-adds it by accident |

**Direction is one-way by default: parent → Lite.** The parent is the mature build; Lite inherits.
A Lite-first change is permitted but must be back-ported or reclassified `ADAPTED`, never left as
undeclared drift.

The parent repo is located via `$PSYCHIC_CREW_PARENT`, defaulting to `$HOME/projects/psychic-crew`.
No absolute machine path appears in this file or in the check — the parent build burned two red
gates on exactly that.

## The map

Tab-separated. `scripts/check-sync.sh` extracts and exercises this block, so it is data, not
decoration — change a row and the check changes with it.

```text
# SYNC-MAP v1
MIRRORED	.claude/rules/security.md	.claude/rules/security.md
MIRRORED	.claude/rules/fallback-protocol.md	.claude/rules/fallback-protocol.md
MIRRORED	.gitattributes	.gitattributes
ADAPTED	.claude/rules/model-policy.md	.claude/rules/model-policy.md
ADAPTED	scripts/apply-models.sh	scripts/apply-models.sh
ADAPTED	.claude/agents/lead-executor.md	.claude/agents/session-orchestrator.md
ADAPTED	.claude/agents/fixer.md	.claude/agents/builder.md
ADAPTED	.claude/agents/test-runner.md	.claude/agents/verifier.md
ADAPTED	.claude/agents/security-reviewer.md	.claude/agents/security.md
DROPPED	.claude/agents/arbiter.md	—
DROPPED	.claude/agents/lead-planner.md	—
DROPPED	.claude/agents/quality-reviewer.md	—
DROPPED	.claude/agents/integration-runner.md	—
DROPPED	.claude/rules/arbiter-protocol.md	—
```

## Why each DROPPED row is a decision, not an omission

- **`arbiter.md` / `arbiter-protocol.md`** — four agents leave no spare body for a broker. Replaced
  by cross-release (`.claude/rules/release-protocol.md`): neither producer releases its own output.
- **`lead-planner.md`** — Lite is plan-driven from a document the operator approves, so there is no
  in-crew planning agent. The parent's planner was also its thinnest contract until PR-F1.
- **`quality-reviewer.md`** — the second lens is now `security`'s **second blind pass** rather than
  a separate agent, which is what ruling B1a's roster and the operator's §8 answer combine to.
- **`integration-runner.md`** — `verifier` absorbs end-to-end runs; at four agents a dedicated
  runner is a hop, not a boundary.

## Not yet mapped

`hooks/`, `scripts/validate-crew.sh`, `scripts/run-crew-tests.sh`, `scripts/save-context.sh` and
`.claude/skills/intake/` are **L1 and later**. They are absent from the map on purpose — a map row
for a file Lite does not have yet would fail the check for the wrong reason. Add the row and the
file in the same phase.
