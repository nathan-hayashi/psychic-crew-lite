# Model Policy (binding) — ADAPTED from the parent: capability classes

## LC-4 — one file, one command
`models.config.json` is the ONLY source of truth for model identity, version and effort. Change it, then run `./scripts/apply-models.sh`. No other file may define model identity.

**Stamp-only rule:** agent frontmatter `model:` and `effort:` lines are written by the script, never by hand. A new agent is authored with the placeholder `model: {{APPLY}}`; the script fills it. Hand-editing either line is a policy violation that validation fails on, because the stamped value will no longer match config.

## LC-3 — agents declare a CLASS, not a model

This is the one deliberate divergence from the parent (CR-029). Agents declare a **capability need**; the config resolves it:

```
classes: { deep → opus · standard → sonnet · economy → haiku }
```

Judgment that compounds gets `deep`; narrow lenses get `standard`; `economy` is reserved for trivial batch lanes and has no agent today.

| Class | Agents |
|---|---|
| `deep` | session-orchestrator, builder |
| `standard` | verifier, security |
| `economy` | none |

**The known cost, carried from the audit and not discovered here.** Resolution is now three levels — class → alias → id — where the parent's was two. Every check that reads a model value must follow the extra hop, and in particular **the forbidden-substring scan must run against the RESOLVED value, never the declared class**, or a prohibited model hides behind a class name. That is the entire risk this indirection introduces and it is why the scan is specified here rather than left to the implementer.

## LC-2 — no fable, anywhere
No agent, subagent or session may run on any `fable` model. Enforced in three places: the `forbidden_substrings` list, the scan in `apply-models.sh`, and a write-time guard.

**Live hazard:** `model: fable` is a valid frontmatter alias — the platform will run it without complaint. Nothing but these guards prevents it, so a broken guard is a silent breach, not a loud one.

## Mode
`alias` (default) resolves through vendor aliases, which track the current generation and are immune to dated-ID staleness. `pinned` freezes exact ids for reproducibility runs.
