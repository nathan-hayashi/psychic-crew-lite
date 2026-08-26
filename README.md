# psychic-crew-lite

A four-agent IT-automation crew derived from [psychic-crew](https://github.com/nathan-hayashi/psychic-crew), plan-driven, with a human gate on every
phase. Claude Code CLI is the runtime; Zed hosts the terminal.

**Lite means fewer agents and fewer phases. It does not mean fewer controls.** The parent's audit
priced a Lite variant as "practices without controls" on the assumption the host would not be Claude
Code. It is, so hooks fire, settings are read, and the enforcement layer travels.

## Quickstart

```bash
mkdir -p ~/projects && cd ~/projects
git clone https://github.com/nathan-hayashi/psychic-crew.git        # the parent — side by side matters
git clone https://github.com/nathan-hayashi/psychic-crew-lite.git
cd psychic-crew-lite && ./scripts/apply-models.sh && ./scripts/verify.sh
```

**Requirements:** `git`, `jq`, and a POSIX shell — no Node, no installs, zero runtime dependencies.
**There is deliberately no setup script:** the hooks create `logs/` on first use and `verify.sh` is
the entry point. The parent is expected beside this repo so `check-sync.sh` can correlate against
it; anywhere else, set `PSYCHIC_CREW_PARENT`.

**The harness engages by directory:** run `claude` with this repo as the project folder and
`.claude/settings.json` wires the guard hooks, the four agents, and the session re-grounding on its
own. Claude Code auth is per-machine (`claude auth status`); this repo holds no secrets and needs
none. Work advances only on exact `APPROVE` tokens in `GATES.md` — `scripts/gate-guard.sh` refuses
a gated commit without one.

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
./scripts/stress.sh          # layer 1d: the release law end to end, under traffic

./scripts/continuity.sh orient          # discover your own state from disk
./scripts/continuity.sh stalls          # stall detection, never from one store
./scripts/continuity.sh seance <query>  # query the predecessor's events, not its summary
./scripts/restore-context.sh            # forward-resume after a compaction
```

Set `PSYCHIC_CREW_PARENT` if the parent repo is not at `$HOME/projects/psychic-crew`.

## The enforcement layer

**7 wired hooks.** Three can block a call; the rest observe.

| Hook | Event | What it refuses |
| --- | --- | --- |
| `bash-blocker` | `PreToolUse[Bash]` | destructive commands, installs, fetch-piped-to-shell, non-Claude CLIs |
| `model-guard` | `PreToolUse[Write\|Edit]` | a config making a forbidden model **reachable** — resolved, not pattern-matched |
| `sensitive-guard` | `PreToolUse[Write\|Edit]` | writes to `.env`/secrets, and removal of protected ignore entries |
| `release-guard` | `PreToolUse[Write\|Edit\|Bash]` | a release line where `released_by` equals `from_agent` |
| `pre-compact-checkpoint` | `PreCompact` | nothing — the emergency checkpoint and numbered snapshot before any compaction |
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
| **1 · behavioural** | does the thing under test actually do it? | `validate-lite.sh` · `check-sync.sh` |
| **2 · witness manifest** | is every correction we ever made *still* in force? | `check-witness.sh` |
| **3 · temporal history** | **when** did it stop working? | `docs/verification-history.jsonl` |

**Layer 2 exists because a marker is not a control.** The parent's registry documents its
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

## The stress run

`./scripts/stress.sh` drives one end-to-end pass across all four roles against a subject with two
seeded defects and an answer key fixed **before** the run.

**What it proves.** The cross-release law under traffic — `released_by ≠ from_agent`, enforced by
the shipped hook rather than by the harness, which routes every candidate line through
`hooks/release-guard.sh` and appends only what the guard permits. Blindness as a property of the
**payload**: pass 2's dispatch is checked to contain nothing from pass 1. Ordering, the audit
schema, and coverage correlated by `task_id` identity rather than count. A self-release is attempted
live inside the run and refused.

**What it does not prove.** That a model would find these defects. The findings are fixture data
scored against the answer key; what is under test is the machinery this build built, not the
reviewer. Real agent traffic needs the four agents dispatched with this repo as the project
directory — the harness stands in for that and says so.

The two seeded defects are chosen so a single lens plausibly catches one and misses the other, which
is why the run asserts the passes found **different** ones: a second pass that finds what the first
found bought nothing.

Stress runs are **run-scoped** under `logs/stress/<run>/`. The live trail is never written by a
fixture — mixing fixture and real releases in one file leaves no reader able to tell them apart.

## Status

**L4 complete — the build is closed — and hardened since.** Scaffold, enforcement, verification,
continuity, stress; then the mirrored shell-discipline and gate-order guards, the skill-pack law
with pack #1 live, and the security phase (`LITE-SECURITY-1`). Current suite counts live in
`./scripts/verify.sh` output and `docs/verification-history.jsonl` — deliberately not restated
here, where they rotted from L2 to README-SYNC-1 without anything noticing. The wired-hook count
above is the one number this file still states, and `validate-lite.sh` binds it.
