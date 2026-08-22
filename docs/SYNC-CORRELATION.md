# SYNC-CORRELATION.md — parent ↔ Lite (plan §7.1)

Lite is a separate repository that must not silently drift from psychic-crew. This map is the
mechanism, and `scripts/check-sync.sh` is what stops it becoming documentation that rots.

## Relations

| Relation | Meaning | Enforcement |
| --- | --- | --- |
| `MIRRORED` | must stay byte-identical | content hash compared; **divergence FAILS** |
| `ADAPTED` | Lite deliberately differs | parent path must exist; a change upstream raises a **review obligation**, not a failure |
| `DROPPED` | considered absence | parent path must exist; recorded so nobody re-adds it by accident |
| `ADDED` | Lite-only, no parent counterpart | lite path must exist; recorded so a Lite-first artifact is declared rather than invisible |

**Direction is one-way by default: parent → Lite.** The parent is the mature build; Lite inherits.
A Lite-first change is permitted but must be declared `ADDED`, never left as undeclared drift.

`ADDED` was introduced at L1 because the map had a hole its own rule forbade: every relation
required a parent path, so a Lite-only artifact could not have a row at all. `release-protocol.md`
had been sitting outside the map since L0 for exactly that reason — declared nowhere, by a map whose
purpose is that nothing is undeclared.

The parent repo is located via `$PSYCHIC_CREW_PARENT`, defaulting to `$HOME/projects/psychic-crew`.
No absolute machine path appears in this file or in the check — the parent build burned two red
gates on exactly that.

## The map

Tab-separated. `scripts/check-sync.sh` extracts and exercises this block, so it is data, not
decoration — change a row and the check changes with it.

```text
# SYNC-MAP v1
ADAPTED	.claude/rules/security.md	.claude/rules/security.md
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
ADAPTED	hooks/_common.sh	hooks/_common.sh
ADAPTED	hooks/bash-blocker.sh	hooks/bash-blocker.sh
ADAPTED	hooks/model-guard.sh	hooks/model-guard.sh
ADAPTED	hooks/sensitive-guard.sh	hooks/sensitive-guard.sh
ADAPTED	hooks/stop.sh	hooks/stop.sh
ADAPTED	hooks/session-start.sh	hooks/session-start.sh
ADAPTED	.claude/settings.json	.claude/settings.json
ADAPTED	scripts/validate-crew.sh	scripts/validate-lite.sh
ADDED	—	.claude/rules/release-protocol.md
ADDED	—	hooks/release-guard.sh
ADDED	—	scripts/check-sync.sh
ADDED	—	docs/SYNC-CORRELATION.md
ADDED	—	scripts/check-witness.sh
ADDED	—	scripts/verify.sh
ADDED	—	docs/WITNESS-MANIFEST.md
ADDED	—	docs/verification-history.jsonl
ADAPTED	hooks/pre-compact-checkpoint.sh	hooks/pre-compact-checkpoint.sh
ADAPTED	scripts/restore-context.sh	scripts/restore-context.sh
ADAPTED	scripts/save-context.sh	scripts/distill.sh
ADAPTED	context/session-summary.md	context/session-summary.md
ADDED	—	scripts/continuity.sh
ADDED	—	context/CLAIMS.md
ADAPTED	stress-project/README.md	stress/DEFECTS.md
ADDED	—	scripts/stress.sh
ADDED	—	stress/normalize.sh
DROPPED	hooks/audit-logger.sh	—
DROPPED	hooks/auto-format.sh	—
DROPPED	hooks/provenance-flag.sh	—
DROPPED	hooks/notify.sh	—
DROPPED	hooks/error-recovery.sh	—
DROPPED	hooks/reference-cap.sh	—
DROPPED	hooks/subagent-start.sh	—
DROPPED	hooks/pre-compact-checkpoint.sh	—
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

`hooks/` and `scripts/validate-crew.sh` **arrived at L1** and are mapped above.

**L2 added four Lite-first artifacts**, all `ADDED`: the witness manifest and its checker
(verification layer 2), the three-layer entry point, and the temporal history (layer 3). None has a
parent counterpart — the parent has layers 1 and a hand-rolled 2, and no layer 3 at all.

**L3 mapped the continuity layer.** `save-context.sh` is ADAPTED to `distill.sh` — same role,
but bindings are declared rather than hand-written, so an unbound claim fails. `continuity.sh` and
`context/CLAIMS.md` are ADDED: the parent has no stall detection, no watched watchdog and no
Seance.

Still absent on purpose: `scripts/run-crew-tests.sh` and `.claude/skills/intake/`. A map row for a file Lite does not have yet would fail the check for the
wrong reason. Add the row and the file in the same phase.

### Why eight parent hooks are DROPPED

`audit-logger` · `auto-format` · `provenance-flag` · `notify` · `error-recovery` · `reference-cap` ·
`subagent-start` · `pre-compact-checkpoint`. The first four are convenience rather than enforcement.
`reference-cap` and `subagent-start` police a dispatch topology Lite does not have — there is no
arbiter to bypass and no broker to cap. `pre-compact-checkpoint` belongs with the continuity layer
at L3 and is a deferral, not a rejection; it is recorded here so it is decided rather than
forgotten.
