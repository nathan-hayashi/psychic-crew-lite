# RULINGS.md — operator rulings in force, with their detectors

A ruling that lives only in a chat window is a load-bearing fact outside the filesystem, which this
build treats as a breach. Each entry records what was ruled, what it changed, and **how a reader
verifies it is still true** — the detector, not a description of one.

## R-PD-1 — packs #2+ deferred behind the security phase (ruled 2026-08-23)

**Ruled.** No second skill-pack lands until the security phase closes at `LITE-SECURITY-1`. Pack #1
(`confluence-docs`) remains usable in the meantime, restricted to **the operator's own documents** —
material they authored or already hold — and that restriction lifts when the phase closes.

**Why the ordering was wrong and is being corrected rather than excused.** Pack #1 was gated at
`PACK-CONFLUENCE-1`, *before* a threat model existed for the surface it opened. The pack is the only
component in either repository that ingests content the build did not write, and it was approved on
its constraints (P1a file-only intake, P2a no credentials, P3a proposals only) with no adversarial
pass behind them. Those constraints turned out to hold — the drill in `docs/security/redteam-1.md`
shows 6/6 fixtures surfaced and refused — but they held on inspection, not by demonstration, and the
demonstration came second. One pack gated that way is a recoverable ordering mistake. It becoming
the pattern is not, which is what this ruling stops.

**Applied.**
- The cap guard in `scripts/check-sync.sh`, beside the R-SP-1 class guard because both enumerate the
  same directory: more than one pack on disk while the phase is open is a **FAIL naming the extra
  packs**.
- The cap **lifts mechanically**, on an `**APPROVED**` row for `LITE-SECURITY-1` in `GATES.md` —
  the same needle shape `gate-guard.sh` uses. Nobody has to remember that the restriction expired,
  and nobody can lift it by asserting that it did.
- **Fail closed on a missing ledger.** No `GATES.md` reads as *not approved*. The permissive reading
  would let the cap be lifted by deleting a file, which is the wrong direction for every control in
  this build.

**What the cap does not do.** It bounds *how many* packs exist, not what pack #1 is pointed at. The
own-documents-only restriction is an instruction to the operator, not a guard: nothing on disk can
tell whose document is in `inbox/`, and P1a means the pack processes what it is given. Stated as a
limit rather than left to look like enforcement.

**Detector.** `scripts/validate-lite.sh` §F asserts all three branches of the guard are present
(hold, lift, violate) and that the lift keys on the ledger token, using comment-stripped needles.

**Behavioural proof — the gate control, executed and recorded.** A *declared* phantom second pack
was planted so the cap would fire in isolation: R-SP-1 **passed** (2 packs, both declared) while
R-PD-1 **failed** naming `zz-phantom`. That separation is the point — the cap binds to the count and
the ledger, not to whether a pack was declared. The **lift** branch was deliberately unproven at the time of
writing — demonstrating it meant writing an `**APPROVED**` row for a gate not yet given, which is the
forgery `gate-guard.sh` exists to make expensive — and it proved itself on the first `check-sync` run
after approval by **failing**: the needle keyed on `LITE-SECURITY-1` where the ledger writes
`APPROVE LITE-SECURITY-1`, so the cap could never have lifted. Recorded as F-L4. Corrected, and both
directions are now demonstrated against the real ledger row.

## R-SP-1 — skill-packs open UNDER §7.1, class-guarded (ratified 2026-08-23)

**Ruled.** Domain skill-packs are permitted, and they open *under* the sync correlation rather than
beside it. A pack present on disk without a §7.1 row is a `check-sync` **failure naming the path**.
The parent-side relation is a **refusal with a reason**. **A4a stands**: packs are proposal-only
until a per-pack gate grants scoped write credentials.

**Applied.**
- Path convention, stated once so a guard can enumerate it:
  `.claude/skills/packs/<pack-name>/`, each carrying a `PACK.md` contract.
- A new `PACK` relation in `docs/SYNC-CORRELATION.md`. It is distinct rather than a reuse of
  `ADDED` or `DROPPED`, because the ruling asks for three properties at once that neither carries: a
  pack is Lite-only (so `DROPPED`, which requires a live parent path, cannot express it), and the
  parent's disposition is a deliberate refusal *with a recorded ground* (which `ADDED` does not
  record). Overloading either would have made the map assert something it does not mean.
- The class guard in `scripts/check-sync.sh`, running **disk → map**. Every row already proved a
  declared pack is in the state its relation claims; the guard proves the converse, that a pack on
  disk is declared at all. That converse is the ruling.
- With no pack on disk the guard **announces** that state rather than passing silently, because a
  class guard with nothing to guard proves nothing and would decay into decoration before the first
  pack ever landed.

**Declaring a pack grants nothing.** It makes the pack visible to the map, and visibility is the
precondition for a per-pack gate under A4a, not a substitute for one.

**Detector.** `scripts/validate-lite.sh` asserts the guard's *logic* is present — the disk→map
direction, the parent-path refusal, and the missing-why failure — using comment-stripped,
fragment-assembled needles, so a file that merely mentions R-SP-1 does not satisfy it.

**Deliberately not an in-suite behavioural case.** Proving it behaviourally needs either a phantom
directory in the live tree — a fixture writing to the artifact it audits, the C-13/C-14 class — or
an env override on the pack root, which is a bypass surface that could point the guard at an empty
directory and silence it. The behavioural proof is therefore the gate control, executed and
recorded: a phantom pack FAILs naming the path; declaring it without a why FAILs; adding the why
passes both directions; and a `PACK` row naming a parent path FAILs.
