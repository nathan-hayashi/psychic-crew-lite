# session-summary.md — distilled state

Conclusions, not chronology. The ledgers (`PROGRESS.md`, `GATES.md`, `Plan.md`) outrank this file;
where they disagree, they win. Every number below is bound to its source in `context/CLAIMS.md` and
checked by `./scripts/distill.sh check`.

## What this build is

**verified** — psychic-crew-lite: a four-agent IT-automation crew derived from psychic-crew, with a
human gate on every phase. Claude Code is the runtime, so hooks fire and the enforcement layer
travels. **60** tracked files.

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

**verified** — `docs/SYNC-CORRELATION.md` holds **58** sync map rows under five relations:
MIRRORED, ADAPTED, DROPPED, ADDED and PACK. `security.md` is ADAPTED because byte-identity shipped
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

## Security

**verified** — `docs/security/redteam-1.md` records the LITE-SECURITY-1 pass. Three findings, all
fixed: the continuity layer wrote the heartbeat note and the durable next-action unredacted into a
tracked file; the adversarial drill ran in the live pack and destroyed the operator's artifacts
(C-13 class); and the drill's own measurement was unfaithful twice over. **6** attack fixtures are
tracked and drive a live drill — 6/6 surfaced as findings, 6/6 routed INTERNAL-IT including the one
that asserted otherwise, nothing executed or fetched.

The threat model is joint and lives in the parent only, mapped `DROPPED` with its reason: two copies
of one model are free to disagree. R-SEC-1 is `MIRRORED` byte-identical.

**Ruling R-PD-1** caps packs at one until this gate closes, keyed on the ledger rather than on
recollection. Pack #1 is own-documents-only until then, which is an instruction to the operator, not
a guard — nothing on disk can tell whose document is in `inbox/`.

Suite pass counts are deliberately **not** distilled here. They are volatile run state, already
recorded per gate in `GATES.md` and per checkpoint in `PROGRESS.md`; a fourth copy would be a fourth
thing that can drift, which is the defect this file's declared bindings exist to prevent. Run
`./scripts/verify.sh` for the live figure.

## Next action

`APPROVE LITE-SECURITY-1` closes the security phase. On approval the R-PD-1 cap lifts mechanically
on the next `check-sync` run, the own-documents-only restriction on pack #1 ends, and the operator
replaces the plan pair with v3.6.
