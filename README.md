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
```

Set `PSYCHIC_CREW_PARENT` if the parent repo is not at `$HOME/projects/psychic-crew`.

## Status

**L0 complete.** Scaffold only: config, four agent bodies, rules, line-ending policy, ignore rules,
and the correlation map with its check. No hooks, no suites, no continuity layer — those are L1–L3.
