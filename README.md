# psychic-crew-lite

A four-agent IT-automation crew derived from [psychic-crew], plan-driven, with a human gate on every
phase. Claude Code CLI is the runtime; Zed hosts the terminal.

**Lite means fewer agents and fewer phases. It does not mean fewer controls.** The parent's audit
priced a Lite variant as "practices without controls" on the assumption the host would not be Claude
Code. It is, so hooks fire, settings are read, and the enforcement layer travels.

## The roster

| Agent | Class | Remit |
| --- | --- | --- |
| `session-orchestrator` | deep | holds the plan, dispatches, stops at gates |
| `builder` | deep | executes approved steps; ACCEPT / REJECT / DEFER |
| `verifier` | standard | runs suites, interprets nothing — **and releases security's findings** |
| `security` | standard | the adversarial lens, run twice with the second blind — **and releases verifier's results** |

## The one design decision worth reading

There is no arbiter. Four agents leaves no spare body for a broker, and the obvious shortcut — the
orchestrator releasing what it dispatched — reopens the defect the parent build watched happen live:
a party that can satisfy its own auditor will.

So **neither producer releases its own output**. `released_by` must differ from `from_agent`, and
that is asserted mechanically rather than trusted. See `.claude/rules/release-protocol.md`.

## Staying in step with the parent

`docs/SYNC-CORRELATION.md` maps every parent artifact to its Lite counterpart under one of three
relations — `MIRRORED` (byte-identical, hash-compared), `ADAPTED` (deliberate difference), `DROPPED`
(considered absence). `./scripts/check-sync.sh` enforces it. Without that check the map is
documentation that rots, which is the failure the parent build kept recording.

## Verify it yourself

```bash
./scripts/verify.sh          # all three layers, with the regression signal
./scripts/verify.sh --record # ...and append a bisectable line to the history

./scripts/apply-models.sh    # stamps agent frontmatter from models.config.json
./scripts/check-sync.sh      # layer 1b: parent correlation, and map completeness
./scripts/validate-lite.sh   # layer 1a: wiring, model policy, hygiene, guards firing for real
./scripts/check-witness.sh   # layer 2: every attested correction still holds
./scripts/distill.sh check   # layer 1c: the distilled summary matches its sources

./scripts/continuity.sh orient          # discover your own state from disk
./scripts/continuity.sh stalls          # stall detection, never from one store
./scripts/continuity.sh seance <query>  # query the predecessor's events, not its summary
./scripts/restore-context.sh            # forward-resume after a compaction
```

Set `PSYCHIC_CREW_PARENT` if the parent repo is not at `$HOME/projects/psychic-crew`.

## The enforcement layer

Six wired hooks. Three can block a call; the rest observe.

| Hook | Event | What it refuses |
| --- | --- | --- |
| `bash-blocker` | `PreToolUse[Bash]` | destructive commands, installs, fetch-piped-to-shell, non-Claude CLIs |
| `model-guard` | `PreToolUse[Write\|Edit]` | a config making a forbidden model **reachable** — resolved, not pattern-matched |
| `sensitive-guard` | `PreToolUse[Write\|Edit]` | writes to `.env`/secrets, and removal of protected ignore entries |
| `release-guard` | `PreToolUse[Write\|Edit\|Bash]` | a release line where `released_by` equals `from_agent` |
| `stop` | `Stop` | nothing — snapshots, and announces an L-series gate awaiting its token |
| `session-start` | `SessionStart` | nothing — re-grounds the session against disk |

`model-guard` is the one worth reading. Agents declare a **class**, so a forbidden model can be
reachable with no forbidden word anywhere near an agent. The guard resolves the proposed config
exactly as `apply-models.sh` would and refuses on the **resolved** value.

`release-guard` enforces the one law replacing the arbiter. It cannot see a line assembled from
shell variables — `validate-lite.sh` scans the whole trail at the gate for that. Hook plus scan,
and neither is claimed to be the other.

**Every denial writes an audit line.** A guard that blocks without a record is a control nobody can
audit afterwards; the parent's equivalent gate produced six live denials and zero records before
this was enforced.

## Verification — three layers

Most builds have layer 1 and call it testing.

| Layer | What it answers | Where |
| --- | --- | --- |
| **1 · behavioural** | does the thing under test actually do it? | `validate-lite.sh` (24) · `check-sync.sh` (41) |
| **2 · witness manifest** | is every correction we ever made *still* in force? | `check-witness.sh` (16 attested) |
| **3 · temporal history** | **when** did it stop working? | `docs/verification-history.jsonl` |

**Layer 2 exists because a marker is not a control.** The parent's registry holds 26 documented
fixes each with a detector, and its audit found two of those detectors attesting nothing — one
matched a comment describing the fix rather than the fix itself. So markers here are searched in
**comment-stripped code**, and a marker surviving only in a comment is reported as its own kind of
failure. Each entry also pins a hash of the file it lives in: edit that file and the entry goes
`STALE` — not passing, not failing — until someone re-verifies and re-stamps deliberately.

**Layer 3 is the one nothing here had.** Without it no one can answer when a control stopped
working. One append-only line per recorded run, carrying the commit, so a regression is bisected
rather than argued about. It is tracked rather than in `logs/`: a bisectable record that does not
survive a clone is not a record.

Regression is judged against a **rolling median of the last five runs**, not the last run, so a
single noisy run is not a regression. The signal threshold is stated in `verify.sh` rather than
implied: any `FAIL`, any `STALE`, or a layer-1 pass count *below* the median. Counts going up is
expected and quiet.

## Continuity

Disk is canonical; a context window is a cache.

**A stall is never declared from a single store.** A stale heartbeat beside live filesystem activity
is heartbeat-write *divergence*, not a stuck agent — gastown learned that from a false escalation and
this build inherits the lesson without paying for it. The two stores are genuinely independent: the
activity scan excludes `logs/`, because that is where heartbeats are written, and without that
exclusion `STALL` can never fire at all.

**The watchdog is itself watched.** `session-orchestrator` may not run its own stall check; the chain
terminates at `verifier`, which has no stake in the answer.

**Seance** lets a successor session query its predecessor's *events* rather than inherit a summary.
Distillation loses detail by design — that is what makes it useful, and what makes this necessary.

**Distillation is checked for fidelity, not tidiness.** The parent's equivalent asserted the summary
had no absolute paths, no raw logs and a next action: twenty assertions, every one a property of the
file alone, all passing for three days against a summary that dated a gate to the wrong timestamp.
Here every number is declared in `context/CLAIMS.md` and compared to its source — and **a number
with no declared binding fails**. Adding an unbound claim is what breaks, rather than something
nobody notices for three sessions.

## Status

**L3 complete.** Scaffold, enforcement, verification, continuity. Seven wired hooks, 23 attested
corrections, a bisectable history, and a distilled state that cannot drift from its sources without
saying so.

L4 is the stress phase: one end-to-end build exercising all four agents and the cross-release law —
also the first time `logs/release-audit.jsonl` carries real traffic.
