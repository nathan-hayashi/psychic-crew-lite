# RULINGS.md — operator rulings in force, with their detectors

A ruling that lives only in a chat window is a load-bearing fact outside the filesystem, which this
build treats as a breach. Each entry records what was ruled, what it changed, and **how a reader
verifies it is still true** — the detector, not a description of one.

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
