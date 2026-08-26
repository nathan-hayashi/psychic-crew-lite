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

## [LITE-SYNC-1|2026-08-23T00:41:37Z] R-SD-1 mirrored + class assertion — awaiting the closing token
- **Mirrored:** `.claude/rules/shell-discipline.md` byte-identical from the parent, declared §7.1 MIRRORED. One-byte divergence control FAILs by name.
- **Class assertion found 2 live violations** in `continuity.sh` (:155, :190) from the durability work — safe on a missing file, wrong on a present-but-empty one. Fixed to capture-then-validate via `sh_count`.
- **Controls 3/3** plus the mirror control. Allowlist empty.
- **Counts, attributed:** validate-lite 37 → **40** (+3 R-SD-1) · sync 51 → **52** (+1 MIRRORED row) · layer2 32 → **35** (+3 witness) · tracked 41 → **42**. distill 11 and stress 14 unchanged.
- **STEP 3 SKIPPED:** no R-SP-1 ruling line was pasted; v3.3's D18 says it is ratified. Conflict reported, not resolved unilaterally.
- **Next action:** await `APPROVE LITE-SYNC-1`.

## [LITE-SYNC-2|2026-08-23T08:42:53Z] R-SD-1 v2 mirrored + class swept — token still owed
- **Committed early at c8bb4c4 — a gate violation.** The block required STOP for the token before committing. Recorded, not smoothed over.
- **Re-mirrored** byte-identical; the §7.1 row proven to still enforce via a one-byte divergence.
- **Census 9 → 0.** A naive stripper reported 4; the accurate one found 9 — this repo's own idiom hid five of nine.
- **Counts:** validate-lite 40 → **41** (+1 rule-5) · layer2 35 → **38** (+3 witness) · sync 52, distill 11, stress 14, tracked 42 unchanged.
- **Next action:** await `APPROVE LITE-SYNC-2` to close the gate record.

## [LITE-SYNC-2|2026-08-23T08:44:40Z] GATE-LITE-SYNC-2 CLOSED — APPROVED
- **Token:** `APPROVE LITE-SYNC-2` @ 2026-08-23T08:44:40Z. The row records that the work commit preceded it; the approval closes the record rather than retroactively authorising the order.
- **Verified at close:** verify.sh layer1 **41/1/0** · sync **52/0** · distill **11/0** · stress **14/0** · layer2 **38/0/0** · no signal. 42 tracked, clean.
- **R-SD-1 v2 now enforced in both builds** with byte-identical rule text and two class assertions each; census zero in both.
- **Next action:** none open. Operator's AFTER step: replace `MASTER_FIFO_PLAN_CLAUDE.md` with v3.4 (DIRECTORY_GUIDE unchanged this revision).

## [R-SP-1|2026-08-23T08:59:27Z] Skill-pack class guard built — awaiting the closing token
- **Ratified explicitly** by the operator; the LITE-SYNC-2 skip is resolved.
- **Built:** `PACK` relation, path convention `.claude/skills/packs/<pack-name>/`, disk→map class guard, `docs/RULINGS.md`, and a logic-reading detector.
- **Verified:** verify.sh layer1 **47/1/0** · sync **54/0** · distill 11/0 · stress 14/0 · layer2 **42/0/0** · no signal.
- **Counts:** validate-lite 41 → **47** (+6 R-SP-1 detector) · sync 52 → **54** (+PACK guard, +RULINGS row) · layer2 38 → **42** (+4 witness) · tracked 42 → **43**.
- **Controls 7/7.** A4a stands: declaring a pack grants no credentials.
- **NOT COMMITTED — awaiting `APPROVE R-SP-1`.** Last block I committed before the token; not repeating that.

## [R-SP-1|2026-08-23T09:02:07Z] GATE R-SP-1 CLOSED — APPROVED
- **Token:** `APPROVE R-SP-1` @ 2026-08-23T09:02:07Z, against work that exists and was not committed before it.
- **Verified at close:** verify.sh layer1 **47/1/0** · sync **54/0** · distill **11/0** · stress **14/0** · layer2 **42/0/0** · no signal. 43 tracked.
- **Skill-packs are open** under §7.1, class-guarded disk→map, with A4a intact — declaring a pack grants visibility, never credentials.
- **Next action:** no phase or gate open in either repo. The first pack, when it lands, needs a `PACK` row, a recorded why, and its own per-pack gate under A4a.

## [LITE-GUARD-1|2026-08-23T09:29:02Z] Gate-order guard mirrored — awaiting the closing token
- **Mirrored** byte-identical, declared §7.1 MIRRORED, enforcement proven by one-byte divergence.
- **Controls 3/3.** From this commit on, every gated Lite commit is guard-fronted.
- **The class assertion caught my own violation** at `validate-lite.sh:279` — a probe written in the very class it was hunting.
- **Counts:** validate-lite 47 → **50** (+3 H0a) · sync 54 → **55** · layer2 42 → **44** · tracked 43 → **44**.
- **NOT COMMITTED — awaiting `APPROVE LITE-GUARD-1`.** The guard now enforces this mechanically.

## [LITE-GUARD-1|2026-08-23T09:31:09Z] GATE LITE-GUARD-1 CLOSED — APPROVED
- **Token:** `APPROVE LITE-GUARD-1` @ 2026-08-23T09:31:09Z. First Lite commit fronted by the guard, which refused until the row was approved.
- **Verified:** verify.sh layer1 **50/1/0** · sync **55/0** · distill 11/0 · stress 14/0 · layer2 **44/0/0** · no signal. 44 tracked.
- **Next action:** BLOCK 3 — PACK-CONFLUENCE-1, the first per-pack gate under R-SP-1.

## [PACK-CONFLUENCE-1|2026-08-23T09:37:47Z] First skill-pack built — awaiting the closing token
- **Pack:** `.claude/skills/packs/confluence-docs` — P1a file intake, P2a no credentials, P3a proposals only. 4 tracked machinery files; workspaces gitignored on the pack-root glob.
- **Hard line held:** stage-everything stages **zero** workspace paths with real fixture content present; no document text in any tracked file.
- **Two of my own checks were one-way and controls caught both:** the stage probe was blind to `git add -f` (a tracked workspace file), and the severity check was blind to an ADDED token. Both closed, both now fire in each direction.
- **Counts:** validate-lite 50 → **55** · sync 55 → **56** · layer2 44 → **48** · tracked 44 → **48**.
- **NOT COMMITTED — awaiting `APPROVE PACK-CONFLUENCE-1`;** the guard enforces it.

## [PACK-CONFLUENCE-1|2026-08-23T09:39:05Z] GATE CLOSED — APPROVED. First skill-pack live.
- **Token:** `APPROVE PACK-CONFLUENCE-1` @ 2026-08-23T09:39:05Z, guard-fronted.
- **Verified:** verify.sh layer1 **55/1/0** · sync **56/0** · distill 11/0 · stress 14/0 · layer2 **48/0/0** · no signal. 48 tracked.
- **Fixture artifacts cleared** from the workspaces after the gate so the operator's first real export starts clean. The runtime audit line is kept: it carries counts, never text.
- **Next action:** operator places the v3.5 plan/map pair, then exports one internal document into `.claude/skills/packs/confluence-docs/inbox/` and runs the pack.

## [LITE-SECURITY-1|2026-08-24T01:34:06Z] Security phase complete — awaiting the closing token
- **Mirrored:** `.claude/rules/secrets-contract.md` byte-identical (sha256 `ebc39d9d85e9ddbf` both sides), §7.1 MIRRORED, one-byte divergence FAILs by name.
- **Threat model is JOINT and lives in the parent only** — mapped `DROPPED` with its reason: two copies of one model are free to disagree. `redteam-1.md` is `ADAPTED`, because a red-team record must differ per repo.
- **Three findings, all fixed.** F-L1 `continuity.sh` wrote the heartbeat note and the durable next-action **unredacted into a tracked, public file**; now sourced through `_common.sh`'s scrubber, failing **closed**. F-L2 the drill ran in the LIVE pack and **destroyed the operator's four artifacts** — C-13 class. F-L3 the drill's own measurement was unfaithful twice: a dotfile-named fixture was silently skipped by `*.md`, and the routing tally counted a word inside a justification.
- **Live drill 6/6:** every fixture surfaced as a finding, every one routed `INTERNAL-IT` including the fixture demanding `EXTERNAL-PUBLIC`, nothing executed or fetched, zero artifacts outside `work/`/`out/`, stage probe **zero**.
- **Ruling R-PD-1** recorded: packs #2+ deferred behind this gate, cap keyed on the ledger, failing closed on a missing ledger. Pack #1 own-documents-only until the token.
- **Counts:** validate-lite 55 → **62** · sync 56 → **60** · distill 11 → **12** · layer2 48 → **48** · tracked 48 → **57**.
- **NOT COMMITTED — awaiting `APPROVE LITE-SECURITY-1`;** the guard enforces it.
- **Next action:** operator issues `APPROVE LITE-SECURITY-1`, then the guard-fronted commit and push; afterwards the v3.6 plan/map pair.

## [LITE-SECURITY-1|2026-08-24T01:35:27Z] Post-compaction checkpoint refresh — state confirmed on disk (§15.3)
- **Re-verified after the ledger writes, not assumed from the entry above:** `verify.sh` exit 0 — layer1 **62/1/0** · sync **60/0** · distill **12/0** · stress **14/0** · layer2 **48/0/0**, no signal.
- **Witness manifest re-stamped** after this block's edits: 30 STALE → **48 OK / 0 STALE / 0 FAIL**. Every stale entry traced to one of four files this block actually changed (`validate-lite.sh`, `continuity.sh`, `check-sync.sh`, `distill.sh`) — checked before refreshing, because a stale hash on an untouched file would mean something moved outside my knowledge. Manifest integrity confirmed intact (127 lines, 48 rows) given the past refresh that destroyed the file.
- **Publication safety, final:** 0 tracked files under any pack workspace · 0 would-be-staged workspace paths · 0 tracked files quoting the operator's document title.
- **`gate-guard.sh` refuses** and names the awaiting row. Nothing committed, nothing pushed.
- **Operator's four artifacts were re-derived, not restored** — the only irreversible loss in this block, recorded in `docs/security/redteam-1.md` F-L2 and in the proposal's own header.
- **Next action:** operator issues `APPROVE LITE-SECURITY-1`, then the guard-fronted commit and push, then the durable `continuity.sh record` checkpoint (deferred until the tree is committed), then the v3.6 plan/map pair.

## [LITE-SECURITY-1|2026-08-24T01:37:38Z] GATE CLOSED — APPROVED, and the closing found a fourth defect
- **Token:** `APPROVE LITE-SECURITY-1` @ 2026-08-24T01:36:16Z, guard-fronted.
- **F-L4, found by the gate itself:** the R-PD-1 cap keyed on `LITE-SECURITY-1` where the ledger writes `APPROVE LITE-SECURITY-1`, so it could never have lifted — and it said "security phase still open" while wrong. Fail-safe direction, which is why it would have survived. Fixed; **both directions now demonstrated against the real row** — approved → `LIFTED`, row removed + 2 packs → `VIOLATED` naming the phantom.
- **Witness re-stamped** after the fix: 8 STALE → **48 OK / 0 STALE / 0 FAIL**, all 8 traced to `check-sync.sh`, manifest intact.
- **Final:** `verify.sh` exit 0 — layer1 **62/1/0** · sync **60/0** · distill **12/0** · stress **14/0** · layer2 **48/0/0**, no signal.
- **Restrictions lifted by this token:** pack #1 is no longer own-documents-only; the R-PD-1 cap now permits a second pack.
- **Next action:** operator places the v3.6 plan/map pair and confirms delta 0.

## [RS1|2026-08-26T01:20:28Z] README-SYNC-1 built — awaiting the token
- **Task:** quickstart + de-rotted figures + F1/F2 bindings; shared phase with the parent, one token, each ledger its own row.
- **Workflow status:** verify layer1 64/1/0 (was 62) · sync 60/0 · distill 12/0 · stress 14/0 · layer2 48/0/0, no signal; witness ritual exercised (14 STALE → refresh → 48 OK).
- **Active artifact:** README.md · scripts/validate-lite.sh · docs/WITNESS-MANIFEST.md, plus this ledger trio (6 entries dirty with them, uncommitted).
- **Open decisions:** none.
- **Closed avenues:** restating suite counts in the README (agnostic instead); fixing stop.sh's L-only toast here (recorded, future phase).
- **Next action:** operator issues `APPROVE README-SYNC-1`; guard-fronted commit and push here and in the parent; post-commit verify expects the same figures green.
