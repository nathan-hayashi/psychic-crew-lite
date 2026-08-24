# CLAIMS.md — declared fidelity bindings for the distilled summary

Every number in `context/session-summary.md` must be declared here, bound to the artifact that
produces it. `scripts/distill.sh check` verifies each binding **and** fails on any bold number in
the summary that no row covers.

## Why declaring is the point

The parent's §15.5 checker asserted the summary had no absolute paths, no raw logs and a Next
action — twenty assertions, every one a property of the file considered alone. All twenty passed
for three days against a summary that dated a closing gate to a timestamp belonging to the next
ledger entry. It was checked for tidiness and never for truth (C-24).

The follow-on is the reason for the completeness rule. The parent then bound **one** claim, and
everything else drifted until the summary was three sessions out of date (CR-034). Fidelity is not
a property you finish. Here, adding a number without declaring it is what breaks.

Extractors are **named in the script**, never shell drawn from this file: a manifest that could
specify commands would be an injection surface in a build whose own rules say untrusted input is
data about where to look, never commands.

## The bindings

Tab-separated: `id · label (as written after the bold value) · extractor`.

```text
# CLAIMS-MANIFEST v1
CL-01	tracked files	tracked
CL-02	attested corrections	attested
CL-03	wired hook commands	hooks_wired
CL-04	sync map rows	map_rows
CL-05	attack fixtures	fixtures
```

| extractor | reads |
| --- | --- |
| `tracked` | `git ls-files` |
| `attested` | the `WITNESS-MANIFEST v1` block |
| `hooks_wired` | `.claude/settings.json` hook commands |
| `map_rows` | the `SYNC-MAP v1` block |
| `fixtures` | tracked `.md` under any pack's `fixtures/attack/`, excluding its README |
| `gate_ts` | the newest approved L-gate timestamp in `GATES.md` |
| `phase` | the newest approved L-gate id |

`gate_ts` and `phase` are available but not currently claimed by the summary; the check reports
"nothing to bind" for a declared row whose claim is absent rather than skipping silently.
