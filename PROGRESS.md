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

## [L2|2026-08-22T21:31:30Z] L2 VERIFICATION COMPLETE — awaiting the closing token
- **Corrected first:** my L1 closure note said L2 was continuity. Plan §3 says L2 is verification, L3 is continuity. Disk is the authority; caught by re-grounding before acting.
- **Layer 2:** `docs/WITNESS-MANIFEST.md` + `check-witness.sh` — **16 attested corrections**, markers searched in comment-stripped code, each pinned to a file hash. STALE (exit 2) is distinct from FAIL (exit 1).
- **Layer 3:** `docs/verification-history.jsonl` + `verify.sh --record` — tracked, append-only, commit-stamped, rolling median over 5 runs with a stated signal threshold.
- **Also closed:** map completeness — every tracked file under `hooks/ scripts/ .claude/` must be declared (21 files).
- **Verified:** verify.sh reports layer1 **24/1/0** · sync **41/0** · layer2 **17/0/0** · no signal.
- **Controls:** 10 external (5 layer-2, 4 layer-3, 1 completeness) plus the in-suite behavioural set. All fired.
- **Next action:** await `APPROVE GATE-L2` to close L2. L3 is continuity: ledgers, distillation, checkpoint/restore, stall detection (§6), including `pre-compact-checkpoint` which L1 recorded as a deferral to here.

## [L2|2026-08-22T21:42:42Z] GATE-L2 CLOSED — APPROVED, condition satisfied
- **Token was conditional** and was held until every named defect was corrected. Four resolved, each with an executed control.
- **Verified at close:** verify.sh layer1 **24/1/0** · sync **41/0** · layer2 **17/0/0** · no signal. Parent unchanged and green at 165 / 43+1SKIP.
- **Swept, negative result:** the `grep -c` fallback idiom is not present in the parent; its `wc -l` lookalikes are not the same defect. Both demonstrated, not reasoned.
- **Next action:** L3 — continuity (§6): ledgers, distillation, checkpoint/restore, stall detection, the watchdog that is itself watched, and Seance. `pre-compact-checkpoint` is the deferral L1 recorded to here.

## [L3|2026-08-22T22:10:36Z] L3 CONTINUITY COMPLETE — awaiting the closing token
- **Built:** `pre-compact-checkpoint.sh` (the L1 deferral), `restore-context.sh`, `distill.sh` + `context/CLAIMS.md`, `continuity.sh` (heartbeat · stalls · orient · seance).
- **Verified:** verify.sh layer1 **31/1/0** · sync **47/0** · distill **11/0** · layer2 **23/0/0** · no signal.
- **Controls:** stall reachable and suppressed on the same input; three fidelity controls; four checkpoint assertions; the orchestrator refused its own stall check.
- **Found and fixed in-flight:** store 2 observed store 1, making STALL unreachable; a full-width bar in an extractor; a stray quote from a triple-quote boundary; an over-strict completeness matcher.
- **Next action:** await `APPROVE GATE-L3` to close L3. L4 is the stress phase — one end-to-end build across all four agents and the cross-release law, and the first real traffic in `logs/release-audit.jsonl`.

## [L3|2026-08-22T22:13:56Z] GATE-L3 CLOSED — APPROVED
- **Token:** `APPROVE GATE-L3` @ 2026-08-22T22:13:56Z, against work that exists.
- **Verified at close:** verify.sh layer1 **31/1/0** · sync **47/0** · distill **11/0** · layer2 **23/0/0** · no signal. Phase moved L2 -> L3 on the approved row alone; orientation reports it without being told.
- **Delivered:** checkpoint/restore, declared-binding distillation, stall detection that needs two stores, the watched watchdog, Seance, orientation.
- **Next action:** L4 — the stress phase. One end-to-end build across all four agents exercising the cross-release law, and the first real traffic in `logs/release-audit.jsonl`. This is the first LIVE test of the release law: until now it has been guarded and asserted, never run.

## [L4|2026-08-22T22:23:47Z] L4 STRESS COMPLETE — awaiting the closing token
- **Ran:** `scripts/stress.sh` — **14 PASS / 0 FAIL** across four roles, two blind security passes, two seeded defects, answer key fixed pre-run.
- **Verified:** verify.sh layer1 **31/1/0** · sync **50/0** · distill **11/0** · stress **14/0** · layer2 **28/0/0** · no signal.
- **Controls:** 4 against the harness (blindness breach, broken ordering, duplicate finding, guard bypassed) plus the live self-release refusal inside the run. All fired.
- **Two defects of my own:** the harness truncated the LIVE release trail (C-13); fixing that exposed a vacuous PASS on an empty trail in the check guarding the release law. Both fixed and controlled; the trail clearing is recorded, not silent.
- **Stated limit:** the four agents are not dispatched as subagents here — this session's project directory is the parent repo. The harness stands in and says so.
- **Next action:** await `APPROVE GATE-L4` to close L4 and the Lite build.

## [L4|2026-08-22T22:38:32Z] GATE-L4 CLOSED — APPROVED. The Lite build is complete.
- **Precondition first:** the operator required C-14's generalisation before the token. Done in the parent and registered as **C-27** — C-14 had recurred on a second trail; **5,817 of 6,177 denial records (94%) were fixture-generated**. Fixtures isolated, 5,860 redacted with the redaction recorded, canary generalised to every trail.
- **Two more found by that work:** the count binding ran before an assertion added after it, and covered one instance of a claim while an identical claim sat stale. Both the same shape as C-27; both fixed.
- **Verified at close:** Lite verify.sh layer1 31/1/0 · sync 50/0 · distill 11/0 · stress 14/0 · layer2 28/0/0, no signal. Parent 43+1SKIP · **166** · 23 · PORTABLE.
- **Phase:** L3 -> L4 on the approved row alone.
- **Next action:** the Lite build is closed at L4. No phase is open. Remaining parent items: port the declared-binding distillation (finishes CR-034), and CR-024's extension to `hooks/` which needs an operator plan re-export (C-26).

## [POST-L4|2026-08-23T00:01:12Z] Durability resolved — heartbeat split, seance labelled
- **Answered:** the L3 `proposed` item. Raw heartbeat log stays runtime/gitignored; a recorded checkpoint is durable in `docs/session-history.jsonl` (tracked, append-only, commit-stamped).
- **Carried forward:** `record` refuses fixture roots (C-14 pre-empted) and confirms its line landed (the L2 defect).
- **Seance labels its stores** — `[durable: survives a clone]` vs `[runtime: this machine only]` — and says outright when an answer will not travel.
- **Verified:** validate-lite **37 PASS / 1 SKIP / 0 FAIL** · sync 51/0 · distill 11/0 · stress 14/0 · layer2 **32/0/0** · no signal. 41 tracked.
- **Next action:** no phase or gate open. Remaining operator decision: whether skill-packs open under the §7.1 correlation.
