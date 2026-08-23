# session-summary.md — distilled state

Conclusions, not chronology. The ledgers (`PROGRESS.md`, `GATES.md`, `Plan.md`) outrank this file;
where they disagree, they win. Every number below is bound to its source in `context/CLAIMS.md` and
checked by `./scripts/distill.sh check`.

## What this build is

**verified** — psychic-crew-lite: a four-agent IT-automation crew derived from psychic-crew, with a
human gate on every phase. Claude Code is the runtime, so hooks fire and the enforcement layer
travels. **48** tracked files.

**verified** — There is no arbiter. Neither producer releases its own output: `verifier` releases
`security`'s findings and `security` releases `verifier`'s, with `released_by` required to differ
from `from_agent`. Four agents leave no spare body for a broker, and an orchestrator releasing what
it dispatched reopens the defect the parent watched happen live.

## Enforcement

**verified** — **7** wired hook commands across five events. Three can block a call: the deny-list,
the class-aware model guard, and the secrets guard. `release-guard` refuses a self-release wherever
it can read the payload, and `validate-lite.sh` scans the whole trail for what it cannot see.

**verified** — Agents declare a capability **class**, not a model. Resolution is class → alias → id,
and every forbidden-model scan runs against the **resolved** value. A class named `deep` carries no
forbidden substring and can still point at a prohibited model; that indirection is the entire cost
of the design and the reason the rule is stated rather than left to the implementer.

## Verification — three layers

**verified** — Layer 1 is behavioural. Layer 2 is the witness manifest: **48** attested corrections,
each bound to a marker searched in comment-stripped code and pinned to a content hash, so an edit
makes an entry `STALE` rather than letting a stale attestation coast. Layer 3 is the temporal
history in `docs/verification-history.jsonl` — append-only and commit-stamped, so a regression is
bisected rather than argued. Regression is judged against a rolling median, not the last run.

## Correlation with the parent

**verified** — `docs/SYNC-CORRELATION.md` holds **52** sync map rows under four relations:
MIRRORED, ADAPTED, DROPPED and ADDED. `security.md` is ADAPTED because byte-identity shipped
references to an arbiter this build does not have, while its severity table stays pinned
byte-identical — two builds that disagree about `crit` cannot exchange findings.

## Continuity

**verified** — Disk is canonical; a context window is a cache. A stall is never declared from a
single store: a stale heartbeat beside live filesystem activity is write divergence, not a stuck
agent. The orchestrator may not run its own stall check.

**verified** — The continuity record is split on purpose. The raw heartbeat log stays runtime and
gitignored: tracking chatter means a diff per heartbeat and a conflict per parallel session, and it
would put runtime state and history in one artifact, which is the defect where no reader can tell
the two apart. What is durable is a recorded **checkpoint** — `docs/session-history.jsonl`, tracked
and append-only, carrying the commit so a successor on a fresh clone can reconstruct and bisect.
`record` refuses outside a git work tree, so fixture roots cannot enter the history, and confirms
its line landed rather than assuming it.

**verified** — Seance queries both stores and **labels which answered**. A successor elsewhere has
only the durable half, and an unlabelled result set would look complete on a machine where it is
not; when every hit is runtime-only, seance says the answer does not travel.

## Next action

L4, the stress phase: one end-to-end build exercising all four agents and the cross-release law.
It is the first time `logs/release-audit.jsonl` carries real traffic rather than only being guarded,
so it is also the first live test of the release law itself.
