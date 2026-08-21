# PROGRESS.md — compaction-safe checkpoints

## [L0|2026-08-21T15:06:29Z] L0 SCAFFOLD COMPLETE
- **Repo created** at a sibling path, branch `dev`, per §8 Q1 (separate repo).
- **Config:** `models.config.json` with capability classes (deep/standard/economy) resolving to aliases — CR-029 folded in as ruled. `apply-models.sh` follows all three hops and scans the RESOLVED value.
- **Four agent bodies**, 22–36 lines each, at contract parity with the parent's best.
- **Rules:** `security.md` and `fallback-protocol.md` MIRRORED byte-identical; `model-policy.md` ADAPTED for classes; `release-protocol.md` NEW, replacing the parent's arbiter protocol.
- **Sync correlation** map and its check — 15 PASS / 0 FAIL, both directions controlled.
- **Next action:** await `APPROVE GATE-L0` to close L0. L1 is enforcement: hooks, deny-list, model guard, secrets guard, release-audit trail.

## [L0|2026-08-21T15:30:47Z] GATE-L0 CLOSED — APPROVED
- **Token:** `APPROVE GATE-L0` received @ 2026-08-21T15:30:47Z, against work that exists. The earlier issuance opened L0 per the corrected §9 grammar.
- **Published:** github.com/nathan-hayashi/psychic-crew-lite — PUBLIC, default dev, no main, settings read off the parent and matched.
- **Verified at close:** apply-models 4 agents stamped · check-sync 15 PASS / 0 FAIL · all scripts parse · 18 files read end to end, nothing sensitive · parent repo green and unchanged at 158 PASS / 0 FAIL.
- **Open, registered at L0:** `.claude/rules/security.md` is MIRRORED and names an arbiter Lite does not have. L1 decides: reclassify ADAPTED, or keep MIRRORED and accept it.
- **Next action:** L1 — enforcement. Hooks, deny-list, model guard, secrets guard, and the release-audit trail that release-protocol.md already specifies. Lite's own stop hook must resolve L-series gate tokens, since the parent's matches F-series only.

## [L1|2026-08-21T16:03:52Z] L1 ENFORCEMENT COMPLETE — awaiting the closing token
- **Built:** 6 wired hooks + `_common.sh`, `.claude/settings.json`, `scripts/validate-lite.sh`. Sync map 14 -> 34 rows with a new `ADDED` relation.
- **Verified:** validate-lite **24 PASS / 1 SKIP / 0 FAIL** · check-sync **36 PASS / 0 FAIL** · apply-models 4 stamped · all scripts parse.
- **Controls:** 8 in-suite behavioural + 4 external, all fired. The one that mattered caught a vacuous LC-2 scan of my own.
- **Decided:** `security.md` MIRRORED -> ADAPTED, severity table pinned byte-identical. The L0 register framed this as a binary; it was not.
- **Open for L2:** continuity layer (checkpoint hook, distillation), the release trail itself, and `pre-compact-checkpoint` deferred to L3.
- **Next action:** await `APPROVE GATE-L1` to close L1.

## [L1|2026-08-21T21:55:44Z] GATE-L1 CLOSED — APPROVED
- **Token:** `APPROVE GATE-L1` @ 2026-08-21T21:55:44Z, against work that exists.
- **Verified at close:** validate-lite 24 PASS / 1 SKIP / 0 FAIL · check-sync 36 PASS / 0 FAIL · apply-models 4 stamped · phase derivation moved L0 -> L1 on the approved row alone · pending-gate toast correctly silent.
- **Closed from L0's register:** Lite's own stop hook (resolves L-series tokens, demonstrated both firing and falling silent) and the `security.md` relation question (ADAPTED, severity table pinned).
- **Next action:** L2 — the continuity layer and the release trail. Checkpoint hook, distillation, and `logs/release-audit.jsonl` actually written by a dispatch rather than only guarded. `pre-compact-checkpoint` is recorded DROPPED-as-deferral and belongs to L3.
