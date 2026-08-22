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
W-02	hooks/model-guard.sh	. as $r	fde327eab7f92e8a
W-03	scripts/validate-lite.sh	class resolution produced a model for all	521a7da53f67533e
W-04	scripts/validate-lite.sh	every tracked hook is wired	521a7da53f67533e
W-05	hooks/_common.sh	PHASE="L?"	c6ad08a77c06404e
W-06	hooks/_common.sh	deny-audit.jsonl	c6ad08a77c06404e
W-07	hooks/release-guard.sh	released_by equals from_agent	411e4706d4470b62
W-08	scripts/check-sync.sh	severity vocabulary byte-identical	a2abbddf75cf9d86
W-09	scripts/check-sync.sh	ADDED row names a parent path	a2abbddf75cf9d86
W-10	scripts/check-sync.sh	every comparison below would be vacuous	a2abbddf75cf9d86
W-11	hooks/bash-blocker.sh	LC-7: this build is Claude-only	1f035a0ac95a0bd4
W-12	hooks/sensitive-guard.sh	writes to .env/secrets are blocked	4489ddd39bc978cd
W-13	scripts/validate-lite.sh	denial records carry an L-series phase	521a7da53f67533e
W-14	scripts/check-sync.sh	UNDECLARED Lite file(s)	a2abbddf75cf9d86
W-15	scripts/verify.sh	rolling-median	bda59c4e7f29960b
W-16	scripts/check-witness.sh	marker survives ONLY in a comment	39df0904728c69dc
W-17	scripts/verify.sh	history did NOT record	bda59c4e7f29960b
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
