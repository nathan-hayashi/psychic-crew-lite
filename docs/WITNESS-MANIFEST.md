# Witness manifest — verification layer 2 (plan §4, operator answer Q4)

Every correction this build has made, bound to the line that would have to change for the defect to
return, and to a hash of the file that line lives in.

## Why a marker alone is not enough

The parent build's `context/plan-corrections.md` is a hand-rolled version of this: 26 documented
fixes, each with a detector. The audit found **two of those detectors attesting nothing** — one
matched a comment describing the fix rather than the fix, the other tested a file's executable bit
rather than running it. Both reported green for weeks.

Two properties close that class here:

1. **Markers are searched in comment-stripped code.** A marker surviving only inside a comment is
   reported as a distinct failure naming that reason, because it is the exact shape the audit found.
   Prose describing a control is not the control.
2. **Each entry carries a content hash of the attested file.** A substring can keep matching while
   the code around it changes meaning. Any edit to an attested file makes its entry `STALE` — not
   passing, not failing — and clearing it requires `./scripts/check-witness.sh --refresh`, which
   re-stamps and prints what moved. Re-verification is deliberate rather than automatic.

`STALE` exits 2 and `FAIL` exits 1, so a caller can tell "unproven" from "broken".

## The manifest

Tab-separated: `id · file · marker · sha256[0:16]`. `scripts/check-witness.sh` parses and
exercises this block, so it is data rather than decoration.

```text
# WITNESS-MANIFEST v1
W-01	scripts/apply-models.sh	HITS="$HITS [$a -> $r]"	42cc93b744ad31d9
W-02	hooks/model-guard.sh	. as $r	76bd7f3eb2f7d5a4
W-03	scripts/validate-lite.sh	class resolution produced a model for all	7852e86cfc9bf0fc
W-04	scripts/validate-lite.sh	every tracked hook is wired	7852e86cfc9bf0fc
W-05	hooks/_common.sh	PHASE="L?"	c6ad08a77c06404e
W-06	hooks/_common.sh	deny-audit.jsonl	c6ad08a77c06404e
W-07	hooks/release-guard.sh	released_by equals from_agent	5055ab487fe2b652
W-08	scripts/check-sync.sh	severity vocabulary byte-identical	2daa4b1b57202ca4
W-09	scripts/check-sync.sh	ADDED row names a parent path	2daa4b1b57202ca4
W-10	scripts/check-sync.sh	every comparison below would be vacuous	2daa4b1b57202ca4
W-11	hooks/bash-blocker.sh	LC-7: this build is Claude-only	1f035a0ac95a0bd4
W-12	hooks/sensitive-guard.sh	writes to .env/secrets are blocked	feaac63888e103f3
W-13	scripts/validate-lite.sh	denial records carry an L-series phase	7852e86cfc9bf0fc
W-14	scripts/check-sync.sh	UNDECLARED Lite file(s)	2daa4b1b57202ca4
W-15	scripts/verify.sh	rolling-median	421f435cab54036d
W-16	scripts/check-witness.sh	marker survives ONLY in a comment	96c421ed057ad9ab
W-17	scripts/verify.sh	history did NOT record	421f435cab54036d
W-18	scripts/validate-lite.sh	carried the prior next action forward verbatim	7852e86cfc9bf0fc
W-19	scripts/continuity.sh	write divergence, not a stall	8ecd476d650e4522
W-20	scripts/continuity.sh	-path ./logs -prune	8ecd476d650e4522
W-21	scripts/continuity.sh	may not run its own stall check	8ecd476d650e4522
W-22	scripts/distill.sh	UNBOUND claim(s) in the summary	f9ad473efb964acc
W-23	scripts/distill.sh	unknown extractor	f9ad473efb964acc
W-24	scripts/stress.sh	BLINDNESS BREACH	da3116dd268e0a84
W-25	scripts/stress.sh	the live trail is never touched	da3116dd268e0a84
W-26	scripts/stress.sh	a self-release was REFUSED by the shipped guard	da3116dd268e0a84
W-27	scripts/validate-lite.sh	release trail is absent or empty	7852e86cfc9bf0fc
W-28	scripts/stress.sh	the union is what a single pass would have missed	da3116dd268e0a84
W-29	scripts/continuity.sh	refusing to record: not a git work tree	8ecd476d650e4522
W-30	scripts/continuity.sh	durable record did NOT land	8ecd476d650e4522
W-31	scripts/continuity.sh	[durable: survives a clone]	8ecd476d650e4522
W-32	scripts/continuity.sh	does not travel to a fresh clone	8ecd476d650e4522
W-33	scripts/continuity.sh	sh_count ()	8ecd476d650e4522
W-34	scripts/validate-lite.sh	R-SD-1 VIOLATION	7852e86cfc9bf0fc
W-35	scripts/validate-lite.sh	the mirrored rule this assertion enforces is present	7852e86cfc9bf0fc
W-36	scripts/validate-lite.sh	rule 5 VIOLATION	7852e86cfc9bf0fc
W-37	scripts/validate-lite.sh	_sdstrip=	7852e86cfc9bf0fc
W-38	hooks/release-guard.sh	self_hits=$(	5055ab487fe2b652
W-39	scripts/check-sync.sh	UNDECLARED pack(s) on disk	2daa4b1b57202ca4
W-40	scripts/check-sync.sh	a pack is Lite-only by definition	2daa4b1b57202ca4
W-41	scripts/check-sync.sh	no 'why' is recorded	2daa4b1b57202ca4
W-42	scripts/validate-lite.sh	A4a is recorded	7852e86cfc9bf0fc
W-43	scripts/gate-guard.sh	has no APPROVED row in	0afad32c9e7b1b2a
W-44	scripts/validate-lite.sh	refusal branch reads the ledger	7852e86cfc9bf0fc
W-45	scripts/validate-lite.sh	PUBLICATION RISK — pack workspace NOT ignored	7852e86cfc9bf0fc
W-46	scripts/validate-lite.sh	force-add would be caught here	7852e86cfc9bf0fc
W-47	scripts/validate-lite.sh	no second scale	7852e86cfc9bf0fc
W-48	scripts/check-sync.sh	packdirs=	2daa4b1b57202ca4
```

The fenced header above is `WITNESS-MANIFEST v1` and the extractor anchors on that exact versioned
line. It previously anchored on the prefix alone, which also matched this document's title — so
extraction started at line 1 and `--refresh` rewrote the file from prose and destroyed it. The
anchor is versioned now, and `--refresh` refuses to write at all unless every row parses to four
fields naming a file that exists.

## What each entry attests

| id | The defect that must not return |
| --- | --- |
| `W-01` | A forbidden model reachable through a class is caught at the **resolved** value, not the declared class name. |
| `W-02` | `model-guard` resolves a proposed config from its root. Losing root context is what made this scan vacuous once already. |
| `W-03` | The static LC-2 scan asserts it resolved one model per agent. It once passed while comparing against an empty list. |
| `W-04` | Tracked hooks and wired hooks are compared in both directions — the check the parent still lacks (C-26). |
| `W-05` | The phase derivation fails **closed** to a sentinel rather than to an empty string. |
| `W-06` | A denial writes its own audit record. Blocking without a record is a silent control. |
| `W-07` | `released_by` may not equal `from_agent` — the one law replacing the arbiter. |
| `W-08` | The severity vocabulary stays byte-identical to the parent even though `security.md` is ADAPTED. |
| `W-09` | An `ADDED` row may not name a parent path, so Lite-first artifacts stay declared. |
| `W-10` | The sync map's vacuity guard: a map parsing to nothing must not read as clean. |
| `W-11` | The deny-list still refuses non-Claude CLI invocation. |
| `W-12` | The secrets guard still refuses writes to `.env` and `secrets/`. |
| `W-13` | Denial records carry an L-series phase, never the fail-closed sentinel. |
| `W-14` | Every tracked machinery file is **declared** in the sync map. `ADDED` made declaring possible; this makes it required. |
| `W-15` | Regression is judged against a **rolling median**, not the last run, so one noisy run is not a regression. |
| `W-16` | A marker surviving only in a comment is reported as its own failure — the shape the parent's audit actually found. |
| `W-17` | The history write is **confirmed to have landed**. It once reported success while appending nothing. |
| `W-18` | The checkpoint carries the prior next action **verbatim**. The parent's version displaced it with its own pointer, degrading the field it exists to protect. |
| `W-19` | A stall is never declared from one store — a stale heartbeat beside live activity is divergence. |
| `W-20` | The two stores are **independent**: the activity scan excludes `logs/`, where heartbeats are written. Without this, STALL is unreachable. |
| `W-21` | The orchestrator may not run its own stall check — the watchdog is watched by a party with no stake. |
| `W-22` | A number in the summary with no declared binding **fails**. Fidelity is not a property you finish. |
| `W-23` | Extractors are named in the script; a manifest that could specify shell would be an injection surface. |
| `W-24` | Blindness is asserted against the **payload** — pass 2's dispatch must carry nothing from pass 1. Not a promise. |
| `W-25` | The stress harness never writes to the live release trail. Fixture and real releases must never share a file. |
| `W-26` | A self-release is refused by the **shipped guard** inside the run, not re-implemented by the harness. |
| `W-27` | An empty release trail is announced, never passed. "No self-release in 0 lines" is trivially true. |
| `W-28` | The two passes must find **different** defects, or the second bought nothing. |
| `W-29` | The durable history refuses fixture roots. A history that accepts synthetic checkpoints is one nobody can trust. |
| `W-30` | The durable write is **confirmed to have landed** — the L2 history once reported success while appending nothing. |
| `W-31` | Seance labels which store answered, so a successor can tell what travels to a clone and what does not. |
| `W-32` | Seance says so explicitly when every hit is runtime-only, rather than looking complete on the only machine that has them. |
| `W-33` | Counts are captured and validated before use (R-SD-1 rule 2), never a count-then-default composite. |
| `W-34` | The R-SD-1 class scan is live: a forbidden composite anywhere in tracked shell fails, naming file and line. |
| `W-35` | The class assertion is bound to the mirrored rule's presence — enforcing a rule this repo does not carry would enforce nothing declared. |
| `W-36` | No status-consumed pipeline has a signal-able producer (R-SD-1 rule 5) — the SIGPIPE class the parent's flake proved. |
| `W-37` | Comment stripping keeps a hash that lives inside a string. The naive form hid 5 of 9 sites of that class in this repo. |
| `W-38` | The release-guard loops capture their output and then test it, rather than piping a loop into a status-consumed grep. |
| `W-39` | R-SP-1 disk→map: a pack on disk with no §7.1 row FAILS naming the path. The converse direction is the ruling. |
| `W-40` | A `PACK` row may not name a parent path — a pack is Lite-only, and the parent side is a refusal, not a counterpart. |
| `W-41` | A declared pack with no recorded **why** FAILS: a row asserting a refusal nobody wrote down. |
| `W-42` | A4a is recorded in the map — declaring a pack grants no credentials, only visibility to a future gate. |
| `W-43` | The gate guard refuses when no APPROVED row exists (H0a). It exists because a session committed before the operator's token. |
| `W-44` | The guard's refusal branch is asserted to read the ledger — a guard that exits 0 unconditionally satisfies every caller. |
| `W-45` | Every pack workspace is gitignored. This repo is PUBLIC and packs read real internal documents. |
| `W-46` | A **tracked** file under a pack workspace fails. The stage-everything probe is blind to a force-add; this is not. |
| `W-47` | A pack may not invent severity words. The comparison is two-way — an ADDED token fails, not only a missing one. |
| `W-48` | Packs are declared at directory granularity, so a file inside a declared pack is covered by its pack's row. |
