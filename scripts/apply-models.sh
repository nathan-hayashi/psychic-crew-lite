#!/usr/bin/env bash
# apply-models.sh — LC-4's "one command". Stamps model: and effort: into agent frontmatter from
# models.config.json. Nothing else may define model identity.
#
# ADAPTED from the parent (CR-029): agents declare a CLASS, so resolution is three levels —
# class -> alias -> id — where the parent's was two.
#
# The audit named the risk this introduces and it is handled explicitly below: the forbidden-model
# scan MUST run against the RESOLVED value, never the declared class, or a prohibited model hides
# behind a class name. That is the whole cost of the indirection.
set -euo pipefail
cd "$(dirname "$0")/.."
CFG="models.config.json"
jq -e . "$CFG" >/dev/null || { echo "[FAIL] $CFG does not parse"; exit 2; }

MODE=$(jq -r '.mode // "alias"' "$CFG")

# Resolve one agent to a concrete model id, following all three hops.
resolve () { # $1 = agent name
  jq -r --arg a "$1" --arg m "$MODE" '
    .agents[$a].class as $c
    | .classes[$c] as $alias
    | if $m == "pinned" then .pinned[$alias] else .aliases[$alias] end' "$CFG"
}

# HC-2 / LC-2 — scan RESOLVED values, plus the alias and pinned tables themselves. Captured into a
# variable and then tested: a pipeline whose producer legitimately exits nonzero would otherwise be
# skipped entirely under pipefail while reporting clean.
HITS=""
for bad in $(jq -r '.forbidden_substrings[]' "$CFG"); do
  for a in $(jq -r '.agents | keys[]' "$CFG"); do
    r=$(resolve "$a")
    case "$(printf '%s' "$r" | tr 'A-Z' 'a-z')" in *"$bad"*) HITS="$HITS [$a -> $r]";; esac
  done
  t=$(jq -r --arg b "$bad" '[(.aliases//{}|to_entries[]|"aliases.\(.key)=\(.value)"),
                             (.pinned //{}|to_entries[]|"pinned.\(.key)=\(.value)"),
                             ("session.model=" + (.session.model // ""))]
                            | .[] | select(ascii_downcase | contains($b))' "$CFG")
  [ -z "$t" ] || HITS="$HITS [$t]"
done
[ -z "$HITS" ] || { echo "[FAIL] LC-2: forbidden model reachable ->$HITS"; exit 2; }

n=0
for a in $(jq -r '.agents | keys[]' "$CFG"); do
  f=".claude/agents/$a.md"
  [ -f "$f" ] || { echo "[WARN] $a declared in config but $f is absent"; continue; }
  want=$(resolve "$a")
  eff=$(jq -r --arg a "$a" '.agents[$a].effort' "$CFG")
  [ "$want" != "null" ] && [ -n "$want" ] || { echo "[FAIL] $a: class did not resolve to a model"; exit 3; }
  tmp="$f.tmp"
  awk -v m="$want" -v e="$eff" '
    BEGIN { infm = 0; done_m = 0; done_e = 0 }
    NR == 1 && $0 == "---" { infm = 1; print; next }
    infm && $0 == "---" {
      if (!done_m) print "model: " m
      if (!done_e) print "effort: " e
      infm = 0; print; next
    }
    infm && /^model:/  { print "model: " m;  done_m = 1; next }
    infm && /^effort:/ { print "effort: " e; done_e = 1; next }
    { print }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
  echo "  [ok] $a -> model:$want effort:$eff"
  n=$((n+1))
done
echo "== apply-models: $n agent(s) stamped, mode=$MODE =="
