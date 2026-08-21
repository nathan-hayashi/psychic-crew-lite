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
./scripts/apply-models.sh    # stamps agent frontmatter from models.config.json
./scripts/check-sync.sh      # enforces the parent correlation
./scripts/validate-lite.sh   # wiring, model policy, hygiene, and the guards firing for real
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

## Status

**L1 complete.** Scaffold plus enforcement: six hooks, the deny-list, the class-aware model guard,
the secrets guard, the release guard, and `validate-lite.sh` — 24 assertions, eleven of them
behavioural and run under a temp root so no case touches the live trail it audits.

No continuity layer and no release trail yet: those are L2–L3.
