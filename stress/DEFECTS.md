# Seeded defects — the L4 stress subject

Two defects in `stress/normalize.sh`, seeded before the run and recorded here so the stress result
can be scored against a fixed answer key rather than against whatever the run happened to produce.

| id | Defect | Lens that plausibly catches it |
| --- | --- | --- |
| `D-1` | Fields are interpolated into JSON with `printf` and no escaping. A name containing `"` or `\` emits malformed JSON; a crafted value can inject arbitrary keys. | **security** — injection-adjacent, untrusted input reaching a position where it changes structure |
| `D-2` | `read` without `-r` mangles backslashes, and the loop drops a trailing line that has no newline. Silent data loss, no error. | **correctness** — behavioural, only visible by running it on a file with no trailing newline |

**Why two, and why these two.** F7's measured result in the parent was that two of three seeded
bugs were invisible to all eighteen tests and were found only by reading — and the branch that
found them was the one that had seen nothing else. `D-1` is visible to a security lens reading the
code. `D-2` is invisible to that lens and shows up when the thing is actually run. A single pass
that finds `D-1` and stops looks successful.

**The answer key is fixed before the run** (the parent's C-18 lesson: denominators fixed pre-run so
the score cannot be self-awarded).
