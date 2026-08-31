#!/usr/bin/env bash
# validate-lite.sh — the L1 assertion layer.
#
# ONE script rather than the parent's static/behavioural split. Lite is small enough that two
# entry points would be ceremony, and LC-4's "one command" spirit argues against a second. Stated
# as a simplification, not discovered as one.
#
# Behavioural cases run under a mktemp root. The parent shipped a fixture that wrote 178 synthetic
# records into the live trail it audits, and the redaction had to be logged to stay distinguishable
# from tampering. No case here touches this repo's own logs/.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0; S=0
ok () { P=$((P+1)); printf '  [PASS] %s\n' "$1"; }
no () { F=$((F+1)); printf '  [FAIL] %s\n' "$1"; }
sk () { S=$((S+1)); printf '  [SKIP] %s\n' "$1"; }

# Built, not written literally: this guard is high-recall and this repo's own rules file explains
# why quoting the token is a hazard.
ABS=$(printf '/%s/' home)

echo "== A. wiring =="
jq -e . .claude/settings.json >/dev/null 2>&1 && ok "settings.json parses" || no "settings.json does not parse"
for f in hooks/*.sh scripts/*.sh; do bash -n "$f" 2>/dev/null || no "syntax error in $f"; done
ok "all shell files parse"

# C-26, carried forward as a design input rather than inherited as a defect. The parent's map-vs-tree
# check polices scripts/ and context/ and has NEVER policed hooks/, so two hooks added at S2 drifted
# for four days in the directory holding its entire enforcement layer. Bound in both directions
# here, from the start. _common.sh is excluded BY NAME because it is sourced, never wired.
tracked=$(git ls-files 'hooks/*.sh' 2>/dev/null | sed 's|hooks/||' | grep -vE '^(_common|_profile)\.sh$' | sort -u)
wired=$(jq -r '.hooks | to_entries[] | .value[] | .hooks[] | .command' .claude/settings.json 2>/dev/null \
        | sed 's|.*/||' | sort -u)
ntr=$(printf '%s\n' "$tracked" | grep -c . || true)
nwi=$(printf '%s\n' "$wired" | grep -c . || true)
# Vacuity guard first: two empty sets differ by nothing, which is a clean comparison proving zero.
{ [ "${ntr:-0}" -ge 3 ] && [ "${nwi:-0}" -ge 3 ]; } \
  && ok "hook extraction is non-vacuous ($ntr tracked, $nwi wired)" \
  || no "hook extraction vacuous — tracked:$ntr wired:$nwi"
unw=$(comm -23 <(printf '%s\n' "$tracked") <(printf '%s\n' "$wired") | tr '\n' ' ')
gho=$(comm -13 <(printf '%s\n' "$tracked") <(printf '%s\n' "$wired") | tr '\n' ' ')
{ [ -z "$unw" ] && [ -z "$gho" ]; } \
  && ok "every tracked hook is wired and every wired hook exists" \
  || no "hooks/ drift — tracked but unwired:[$unw] wired but absent:[$gho]"

echo
echo "== B. model policy (LC-2 / LC-3 / LC-4) =="
jq -e . models.config.json >/dev/null 2>&1 && ok "models.config.json parses" || no "models.config.json does not parse"
mode=$(jq -r '.mode // "alias"' models.config.json)
bad_any=""
for b in $(jq -r '.forbidden_substrings[]' models.config.json); do
  # Resolved values, never declared classes. A class named "deep" carries no forbidden substring
  # and can still point at a forbidden model; that indirection is the whole cost of LC-3.
  hit=$(jq -r --arg b "$b" --arg m "$mode" '. as $r
    | [ ($r.agents | to_entries[] | .value.class as $c | ($r.classes[$c]) as $al
          | if $m == "pinned" then $r.pinned[$al] else $r.aliases[$al] end),
        ($r.aliases | to_entries[] | .value), ($r.pinned | to_entries[] | .value),
        ($r.session.model // "") ]
    | map(select(type == "string" and (ascii_downcase | contains($b)))) | .[0] // ""' models.config.json)
  [ -z "$hit" ] || bad_any="$bad_any [$b -> $hit]"
done
# VACUITY GUARD, added because this check passed while resolving NOTHING. Inside
# `.agents | to_entries[]` the dot is the entry, not the root, so .classes[$c] indexed null and
# every comparison ran against an empty list. It reported clean and the behavioural case in D was
# what exposed it. Assert the resolution actually produced one model per agent.
nres=$(jq -r --arg m "$mode" '. as $r | [ $r.agents | to_entries[] | .value.class as $c
        | ($r.classes[$c]) as $al | if $m == "pinned" then $r.pinned[$al] else $r.aliases[$al] end
        | select(type == "string" and length > 0) ] | length' models.config.json)
nag=$(jq -r '.agents | length' models.config.json)
[ "${nres:-0}" = "$nag" ] && ok "class resolution produced a model for all $nag agents (scan is not vacuous)" \
                          || no "class resolution produced $nres models for $nag agents — the LC-2 scan above is vacuous"
[ -z "$bad_any" ] && ok "LC-2: no forbidden model reachable through any class, alias or pin" \
                  || no "LC-2 BREACH: forbidden model reachable ->$bad_any"

# Stamp parity. A hand-edited frontmatter line is the failure model-policy.md names, and it is
# invisible unless the stamped value is compared to what config resolves to.
drift=""
for a in $(jq -r '.agents | keys[]' models.config.json); do
  f=".claude/agents/$a.md"
  [ -f "$f" ] || { drift="$drift [$a: file absent]"; continue; }
  want=$(jq -r --arg a "$a" --arg m "$mode" '.agents[$a].class as $c | .classes[$c] as $al
         | if $m == "pinned" then .pinned[$al] else .aliases[$al] end' models.config.json)
  got=$(awk '/^---$/{n++;next} n==1 && /^model:/{sub(/^model:[[:space:]]*/,"");print;exit}' "$f")
  [ "$want" = "$got" ] || drift="$drift [$a: config=$want file=$got]"
done
[ -z "$drift" ] && ok "every agent's stamped model matches what config resolves to" \
                || no "stamp drift —$drift"

echo
echo "== C. hygiene =="
hits=$(git grep -l "$ABS" -- . 2>/dev/null | tr '\n' ' ')
[ -z "$hits" ] && ok "no absolute machine path in any tracked file" || no "absolute path in: $hits"
_v1="cod""ex"; _v2="chat""gpt"; _v3="open""ai"
vh=$(git grep -ilE "$_v1|$_v2|$_v3" -- . 2>/dev/null | grep -v '^hooks/bash-blocker\.sh$' | tr '\n' ' ')
[ -z "$vh" ] && ok "LC-7: no non-Claude vendor name outside the deny-list itself" || no "vendor name in: $vh"
# R-SD-1 — the CLASS assertion required by .claude/rules/shell-discipline.md, which is MIRRORED
# byte-identical from the parent. The rule's own enforcement clause specifies this check, so a
# mirrored rule with no assertion behind it would be prose describing a control that does not exist.
#
# The defect: `grep -c` prints its count and THEN exits nonzero on zero matches, so a `|| echo`
# fallback fires too and the composite emits TWO lines. It misbehaves only when the count is zero —
# a clean tree — which is why it survived five times across two builds. In THIS repo it broke the
# durable write at L2 and again at the durability work, the second time three lines below the
# comment citing the first.
#
# NEEDLES FRAGMENT-ASSEMBLED so neither this assertion nor the rule file matches itself. `|| true`
# is deliberately NOT matched: grep prints "0" and true adds nothing, which is the correct form.
# THE ALLOWLIST IS EMPTY AND STAYS EMPTY — an exemption turns a class assertion back into an
# instance fix, which is the whole reason this rule exists.
_sd1="gre""p -c"; _sd2="|| ec""ho"
# STRIPPER UPGRADED at v2. `s/#.*//` destroys any line carrying a hash inside a string, and this
# repo's scripts are full of them: a naive census of the rule-5 class here reported 4 sites where
# the accurate one found 9. A scanner blind to more than half its class reports clean and means
# nothing. Strip only a whitespace-introduced hash, or a whole-line comment.
_sdstrip='s/^[[:space:]]*#.*$//; s/[[:space:]]#.*$//'
sdbad=$(git ls-files '*.sh' 2>/dev/null | while read -r sdf; do
          sed -E "$_sdstrip" "$sdf" | grep -nF -- "$_sd1" | grep -F -- "$_sd2" | sed "s|^|$sdf:|"
        done)
sdn=$(git ls-files '*.sh' 2>/dev/null | grep -c .)
# Vacuity guard: a scan over no files is trivially clean, which is how this would switch off.
[ "${sdn:-0}" -ge 5 ] && ok "R-SD-1 class scan covers $sdn tracked shell file(s)" \
                      || no "R-SD-1 scan is vacuous — only ${sdn:-0} shell file(s) enumerated"
[ -z "$sdbad" ] && ok "R-SD-1 no count-then-default composite in any tracked shell file" \
                || no "R-SD-1 VIOLATION — count-then-default composite at: $(printf '%s' "$sdbad" | tr '\n' ' ')"

# R-SD-1 rule 5 — the sibling class, mirrored from the parent's ruling. `producer | grep -q PAT`
# under pipefail: grep -q exits the instant it matches, the producer's next write takes SIGPIPE
# (141), and pipefail reports the producer's death as the pipeline's verdict. In the parent it cost
# a one-in-four red suite on unchanged inputs. NO SMALL-INPUT EXEMPTION and an EMPTY allowlist, per
# the rule: uniformity is the guard.
_sd5="| gr""ep -"
sd5bad=$(git ls-files '*.sh' 2>/dev/null | while read -r sd5f; do
           sed -E "$_sdstrip" "$sd5f" | grep -nE '\|[[:space:]]*grep[[:space:]]+-[a-zA-Z]*q' | sed "s|^|$sd5f:|"
         done)
[ -z "$sd5bad" ] && ok "R-SD-1 rule 5: no status-consumed pipeline with a signal-able producer (census 9 -> 0)" \
                 || no "R-SD-1 rule 5 VIOLATION — pipe-to-grep-q at: $(printf '%s' "$sd5bad" | tr '\n' ' ')"
# The rule is MIRRORED, so the assertion must be bound to the rule actually being present — a class
# check enforcing a rule this repo does not carry would be enforcing nothing declared.
[ -f .claude/rules/shell-discipline.md ] \
  && ok "R-SD-1 the mirrored rule this assertion enforces is present" \
  || no "R-SD-1 assertion runs but .claude/rules/shell-discipline.md is absent"

for e in ".env" "logs/" ".claude/state/"; do
  grep -qxF "$e" .gitignore && ok "ignore rule present: $e" || no "ignore rule missing: $e"
done

echo
echo "== D. the guards actually fire (behavioural, temp root) =="
T=$(mktemp -d); mkdir -p "$T/logs" "$T/.claude"
cp models.config.json "$T/" 2>/dev/null; cp GATES.md "$T/" 2>/dev/null
fire () { # $1 = hook, $2 = json payload -> echoes "DENY" or "ALLOW"
  out=$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$T" ./hooks/"$1" 2>/dev/null || true)
  case "$out" in *'"deny"'*) echo DENY ;; *) echo ALLOW ;; esac
}
# Assembled from fragments: writing these verbs contiguously into a command string is denied by
# this repo's own deny-list, which is precisely what it is supposed to do.
c1=git; c2=clone; probe="$c1 $c2 https://example.invalid/x"
[ "$(fire bash-blocker.sh "$(jq -cn --arg c "$probe" '{tool_name:"Bash",tool_input:{command:$c}}')")" = DENY ] \
  && ok "bash-blocker denies a prohibited fetch verb" || no "bash-blocker allowed a prohibited fetch verb"
[ "$(fire bash-blocker.sh "$(jq -cn '{tool_name:"Bash",tool_input:{command:"ls -la"}}')")" = ALLOW ] \
  && ok "bash-blocker allows an ordinary command" || no "bash-blocker denied an ordinary command"
[ "$(fire sensitive-guard.sh "$(jq -cn '{tool_name:"Write",tool_input:{file_path:"/x/.env",content:"K=v"}}')")" = DENY ] \
  && ok "sensitive-guard denies a write to .env" || no "sensitive-guard allowed a write to .env"
# Class indirection at write time: the agent never changes and no forbidden word sits near one.
fb=$(jq -r '.forbidden_substrings[0]' models.config.json)
poison=$(jq -c --arg b "$fb" '.aliases.opus = $b' models.config.json)
[ "$(fire model-guard.sh "$(jq -cn --arg c "$poison" '{tool_name:"Write",tool_input:{file_path:"models.config.json",content:$c}}')")" = DENY ] \
  && ok "model-guard denies a config where a CLASS resolves to a forbidden model" \
  || no "model-guard allowed a forbidden model reachable through a class"
[ "$(fire model-guard.sh "$(jq -cn --arg c "$(cat models.config.json)" '{tool_name:"Write",tool_input:{file_path:"models.config.json",content:$c}}')")" = ALLOW ] \
  && ok "model-guard allows the clean config" || no "model-guard denied the clean config"
selfrel='{"ts":"2026-01-01T00:00:00Z","task_id":"t1","agent_id":"a","from_agent":"security","released_by":"security","mutation":"none","reason":"x"}'
crossrel='{"ts":"2026-01-01T00:00:00Z","task_id":"t1","agent_id":"a","from_agent":"security","released_by":"verifier","mutation":"none","reason":"x"}'
noid='{"ts":"2026-01-01T00:00:00Z","agent_id":"a","from_agent":"security","released_by":"verifier","mutation":"none","reason":"x"}'
[ "$(fire release-guard.sh "$(jq -cn --arg c "$selfrel" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = DENY ] \
  && ok "release-guard denies a self-release" || no "release-guard allowed a self-release"
[ "$(fire release-guard.sh "$(jq -cn --arg c "$crossrel" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = ALLOW ] \
  && ok "release-guard allows a cross-release" || no "release-guard denied a valid cross-release"
[ "$(fire release-guard.sh "$(jq -cn --arg c "$noid" '{tool_name:"Write",tool_input:{file_path:"logs/release-audit.jsonl",content:$c}}')")" = DENY ] \
  && ok "release-guard denies a release line with no task_id" || no "release-guard allowed an uncorrelatable release"
# The Bash path too, since an append is the likelier way this line gets written.
[ "$(fire release-guard.sh "$(jq -cn --arg c "echo '$selfrel' >> logs/release-audit.jsonl" '{tool_name:"Bash",tool_input:{command:$c}}')")" = DENY ] \
  && ok "release-guard denies a self-release appended via Bash" || no "release-guard missed a self-release via Bash"
# A denial must leave a record. Blocking silently is a control nobody can audit after the fact.
[ -s "$T/logs/deny-audit.jsonl" ] && ok "every denial wrote an audit line ($(grep -c . "$T/logs/deny-audit.jsonl") records)" \
                                  || no "denials left no audit record"
# The phase stamped on those records must be L-series and must not be the fail-closed sentinel.
ph=$(jq -r '.phase' "$T/logs/deny-audit.jsonl" 2>/dev/null | sort -u | tr '\n' ' ')
case "$ph" in *"L?"*) no "denial records carry the fail-closed phase sentinel ($ph)" ;;
              L[0-9]*) ok "denial records carry an L-series phase ($ph)" ;;
              *) no "denial records carry an unexpected phase ($ph)" ;; esac
rm -rf "$T"

echo
echo "== D2. continuity (L3, behavioural, temp root) =="
CT=$(mktemp -d); mkdir -p "$CT/logs" "$CT/.claude/state"
cp GATES.md "$CT/" 2>/dev/null
printf '# P\n\n## [L2|t] c\n- **Next action:** SENTINEL-CARRY-FORWARD\n' > "$CT/PROGRESS.md"
CLAUDE_PROJECT_DIR="$CT" ./hooks/pre-compact-checkpoint.sh >/dev/null 2>&1; ckrc=$?
[ "$ckrc" = 0 ] && ok "pre-compact exits 0 (it must never block compaction)" \
                || no "pre-compact exited $ckrc — it would block or fail a compaction"
ls "$CT"/.claude/state/checkpoints/ckpt-*.md >/dev/null 2>&1 \
  && ok "pre-compact wrote a numbered snapshot" || no "pre-compact wrote no snapshot"
# The parent's version hardcoded a pointer here, which then BECAME the newest Next action line, so
# the cold reader recovered the pointer instead of the instruction it displaced. The parachute
# degraded the one field it exists to protect. Assert the prior action is carried VERBATIM.
grep -qF 'SENTINEL-CARRY-FORWARD' "$CT/PROGRESS.md" \
  && ok "pre-compact carried the prior next action forward verbatim" \
  || no "pre-compact displaced the next action with its own pointer"
chmod 400 "$CT/PROGRESS.md" 2>/dev/null
CLAUDE_PROJECT_DIR="$CT" ./hooks/pre-compact-checkpoint.sh >/dev/null 2>&1; ckrc2=$?
chmod 644 "$CT/PROGRESS.md" 2>/dev/null
[ "$ckrc2" = 0 ] && ok "pre-compact still exits 0 with PROGRESS.md unwritable" \
                 || no "pre-compact failed on an unwritable ledger (exit $ckrc2)"
rm -rf "$CT"

# §6.2 — the watchdog must be watched by a party with no stake in the answer.
./scripts/continuity.sh stalls --as session-orchestrator >/dev/null 2>&1 \
  && no "the orchestrator was allowed to run its own stall check" \
  || ok "the orchestrator may not run its own stall check (the watchdog is watched)"
./scripts/continuity.sh heartbeat not-an-agent working >/dev/null 2>&1 \
  && no "heartbeat accepted an unknown agent name" \
  || ok "heartbeat rejects an agent outside the roster"
# The durable record: a history that accepts fixture data is a history nobody can trust, which is
# what C-14 recorded when synthetic records entered a live trail. `record` must refuse outside a git
# work tree, because that is where fixtures and stress harnesses run.
DT=$(mktemp -d); mkdir -p "$DT/scripts" "$DT/docs" "$DT/logs"
cp scripts/continuity.sh "$DT/scripts/"; cp GATES.md PROGRESS.md "$DT/" 2>/dev/null
( cd "$DT" && ./scripts/continuity.sh record >/dev/null 2>&1 ) \
  && no "record accepted a fixture root — the durable history would carry synthetic checkpoints" \
  || ok "record refuses outside a git work tree (fixture data cannot enter the durable history)"
[ -s "$DT/docs/session-history.jsonl" ] \
  && no "record wrote to the fixture's durable history despite refusing" \
  || ok "the refused record wrote nothing at all"
rm -rf "$DT"
# Confirm-it-landed, and the durable line must parse with its required fields. The L2 history write
# once reported success while appending nothing.
grep -qF -- 'durable record did NOT land' <<<"$(sed 's/#.*//' scripts/continuity.sh)" \
  && ok "record confirms its line landed rather than assuming it" \
  || no "record does not confirm the write landed"
if [ -s docs/session-history.jsonl ]; then
  jq -e '.commit and .phase and .event=="checkpoint"' docs/session-history.jsonl >/dev/null 2>&1 \
    && ok "every durable checkpoint carries commit, phase and event ($(grep -c . docs/session-history.jsonl) recorded)" \
    || no "a durable checkpoint is missing required fields"
else
  sk "no durable checkpoint recorded yet — nothing to validate"
fi
# Seance must LABEL which store answered. An unlabelled result set looks complete on a machine
# where it is not, and the durable half is all a fresh clone has.
grep -qF -- '[durable: survives a clone]' <<<"$(sed 's/#.*//' scripts/continuity.sh)" \
  && ok "seance labels durable hits so a successor can tell what travels" \
  || no "seance does not distinguish durable from runtime results"
grep -qF -- 'does not travel to a fresh clone' <<<"$(sed 's/#.*//' scripts/continuity.sh)" \
  && ok "seance says so when every hit is runtime-only" \
  || no "seance is silent when its answer would not travel"

grep -qF -- 'write divergence, not a stall' <<<"$(sed 's/#.*//' scripts/continuity.sh)" \
  && ok "stall detection distinguishes divergence from a stall (never one store)" \
  || no "stall detection lost the divergence branch — it would escalate from a single store"

echo
echo "== I. secrets contract (R-SEC-1) =="
[ -f .claude/rules/secrets-contract.md ] && ok "R-SEC-1 contract present (MIRRORED from the parent)" \
                                         || no "R-SEC-1 contract missing — rule 1 has no written home"
# RULE 1 — zero is the default. Nothing token-shaped may exist anywhere in the tracked tree. This is
# the assertion that would have caught a credential pasted into a ledger, which is the realistic way
# one arrives in a repo that has none.
_r1="gh""p_"; _r2="xox""b-"; _r3="AKI""A"; _r4="-----BEG""IN"
sec_hits=$(git grep -lE "${_r1}[A-Za-z0-9]{20,}|${_r2}[A-Za-z0-9]{10,}|${_r3}[A-Z0-9]{16}|${_r4} [A-Z ]*PRIVATE KEY" -- . 2>/dev/null | grep -v '^\.claude/rules/secrets-contract\.md$' | tr '\n' ' ')
[ -z "$sec_hits" ] && ok "R-SEC-1 rule 1: no credential-shaped value in any tracked file" \
                   || no "R-SEC-1 rule 1 VIOLATED — credential-shaped value in: $sec_hits"
# RULE 3 — proved by writing planted fakes THROUGH each writer and reading back. Grepping the
# writers for "scrub" reports green for one that calls it on the wrong variable; this repo's own
# continuity.sh passed that reading while writing notes verbatim.
rsroot=$(mktemp -d); mkdir -p "$rsroot/logs"; cp GATES.md models.config.json "$rsroot/" 2>/dev/null
rstok="${_r1}RSEC1LITEAAAAAAAAAAAAAAAAAAAAAAAAAAA"
rsleak=""
rg1=git; rg2=clone
printf '%s' "$(jq -cn --arg c "$rg1 $rg2 https://x@h.invalid/r?t=$rstok" '{tool_name:"Bash",tool_input:{command:$c}}')" \
  | CLAUDE_PROJECT_DIR="$rsroot" ./hooks/bash-blocker.sh >/dev/null 2>&1
grep -qF -- "$rstok" "$rsroot/logs/deny-audit.jsonl" 2>/dev/null && rsleak="$rsleak [deny]"
# continuity's heartbeat note — operator-supplied text straight into a log.
hbprobe=$(mktemp -d); mkdir -p "$hbprobe/logs" "$hbprobe/scripts" "$hbprobe/hooks"
cp scripts/continuity.sh "$hbprobe/scripts/"; cp hooks/_common.sh "$hbprobe/hooks/"; cp GATES.md PROGRESS.md "$hbprobe/" 2>/dev/null
( cd "$hbprobe" && ./scripts/continuity.sh heartbeat verifier working "tok $rstok" >/dev/null 2>&1 )
grep -qF -- "$rstok" "$hbprobe/logs/heartbeats.jsonl" 2>/dev/null && rsleak="$rsleak [continuity-heartbeat]"
rm -rf "$rsroot" "$hbprobe"
[ -z "$rsleak" ] && ok "R-SEC-1 rule 3: a planted token survives no Lite writer (deny, heartbeat note)" \
                 || no "R-SEC-1 rule 3 VIOLATED — planted token written verbatim by:$rsleak"

echo
echo "== H. skill packs (R-SP-1 / P1a P2a P3a) =="
# PUBLICATION SAFETY IS THE HARD LINE. This repository is PUBLIC, and a pack reads real internal
# documents. Everything a pack reads or writes must be unstageable, and that has to be an assertion
# rather than a habit — the habit is what fails on the day someone runs `git add -A` in a hurry.
PK=".claude/skills/packs"
pk_dirs=$(find "$PK" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
npk=$(grep -c . <<<"$pk_dirs"); case "$npk" in ''|*[!0-9]*) npk=0 ;; esac
if [ "$npk" = 0 ]; then
  ok "no pack on disk — nothing to protect yet (announced, not skipped)"
else
  # Every workspace of every pack, ignored. Probed with a path that does not exist, because
  # check-ignore answers about the PATH, and a rule that only works on existing files is a rule
  # that arrives after the leak.
  leak=""
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    for w in inbox work out; do
      git check-ignore -q "$d/$w/probe-does-not-exist.md" || leak="$leak [$d/$w]"
    done
  done <<PKEOF
$pk_dirs
PKEOF
  [ -z "$leak" ] && ok "every pack workspace is gitignored ($npk pack(s), inbox/work/out each)" \
                 || no "PUBLICATION RISK — pack workspace NOT ignored:$leak"
  # The probe that actually matters: what would a careless `git add -A` stage?
  staged_ws=$(git add -A -n 2>/dev/null | grep -cE 'packs/[^/]+/(inbox|work|out)/|logs/pack-[^ ]*\.jsonl')
  case "$staged_ws" in ''|*[!0-9]*) staged_ws=0 ;; esac
  [ "$staged_ws" = 0 ] && ok "stage-everything probe stages ZERO pack workspace paths" \
                       || no "PUBLICATION RISK — stage-everything would stage $staged_ws workspace path(s)"
  # THE PROBE ABOVE IS BLIND TO THE LIKELIEST LEAK, and a control found that rather than reasoning.
  # `git add -A -n` reports what WOULD be staged; it says nothing about what already IS. A single
  # `git add -f` on a proposal makes the file tracked, and the probe then reports ZERO forever after
  # — clean, and wrong, on the one path a person is most likely to take when an ignore rule gets in
  # their way. Ask git what is TRACKED under a workspace, which no ignore rule and no force-add can
  # hide.
  tracked_ws=$(git ls-files -- "$PK/*/inbox/*" "$PK/*/work/*" "$PK/*/out/*" 2>/dev/null | grep -vc '/\.keep-runtime$')
  case "$tracked_ws" in ''|*[!0-9]*) tracked_ws=0 ;; esac
  if [ "$tracked_ws" = 0 ]; then
    ok "no TRACKED file under any pack workspace (force-add would be caught here)"
  else
    no "PUBLICATION RISK — $tracked_ws file(s) TRACKED under a pack workspace: $(git ls-files -- "$PK/*/inbox/*" "$PK/*/work/*" "$PK/*/out/*" 2>/dev/null | grep -v '/\.keep-runtime$' | tr '\n' ' ')"
  fi
  # Machinery must be tracked, or the pack is undeclared behaviour.
  mach_missing=""
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    for m in PACK.md doc-standards.md; do
      git ls-files --error-unmatch "$d/$m" >/dev/null 2>&1 || mach_missing="$mach_missing [$d/$m]"
    done
  done <<PKEOF2
$pk_dirs
PKEOF2
  [ -z "$mach_missing" ] && ok "every pack's machinery is tracked (PACK.md + doc-standards.md)" \
                         || no "pack machinery untracked:$mach_missing — the contract would not travel"
  # NO SECOND SCALE. The pack reuses security.md's four severity tokens; a pack inventing its own
  # makes two vocabularies that drift, which is the defect CR-026 recorded in the parent.
  sec_toks=$(grep -oE '^\| `(crit|high|med|low)`' .claude/rules/security.md | grep -oE 'crit|high|med|low' | sort -u | tr '\n' ' ')
  # EXTRACT WHATEVER THE PACK DECLARES, not the tokens we hope to find. The first version grepped
  # for `crit|high|med|low` specifically, so it could detect a MISSING token and was blind to an
  # ADDED one — a pack could introduce `blocker` and the check would still report parity. A one-way
  # comparison is not parity. Read the pack's own severity line and take every backticked word.
  pk_toks=$(sed -n '/^## Severity vocabulary/,/^## /p' "$PK"/*/PACK.md 2>/dev/null \
            | grep -oE '`[a-z]+`' | tr -d '`' | sort -u | tr '\n' ' ')
  { [ -n "$pk_toks" ] && [ "$pk_toks" = "$sec_toks" ]; } \
    && ok "pack severity vocabulary is security.md's exactly, no second scale ($pk_toks)" \
    || no "pack severity vocabulary diverges — pack:[$pk_toks] security.md:[$sec_toks]"
fi

echo
echo "== G. gate-order guard (H0a, MIRRORED) =="
# Mirrors the parent's assertion. The guard exists because a session — this one — committed before
# the operator's token at LITE-SYNC-2. It is MIRRORED byte-identical, so check-sync already proves
# the bytes; what this proves is that the thing is present, executable, and that its refusal branch
# actually reads the ledger. A guard that exits 0 unconditionally satisfies every caller.
GG="scripts/gate-guard.sh"
[ -x "$GG" ] && ok "H0a gate-guard present and executable" || no "H0a gate-guard missing or not executable"
_hg1="GATE""S.md"; _hg2="REFU""SED"; _hg3="APPRO""VED"
ggbody=$(sed -E "$_sdstrip" "$GG" 2>/dev/null)
ggmiss=""
for nd in "$_hg1" "$_hg2" "$_hg3"; do
  grep -qF -- "$nd" <<<"$ggbody" || ggmiss="$ggmiss [$nd]"
done
[ -z "$ggmiss" ] \
  && ok "H0a refusal branch reads the ledger and keys on the approval marker" \
  || no "H0a gate-guard is missing load-bearing logic:$ggmiss — it would pass every caller"
# It must also obey the rule this repo enforces on everything else.
# CAPTURE, THEN TEST. The first version of this line was `grep -c … | grep -qx 0`, which is BOTH a
# rule-5 violation and broken by rule 5: grep -c prints 0 and exits nonzero on no match, pipefail
# surfaces that, and the assertion failed on a guard that was perfectly clean. The rule-5 class
# assertion caught it and named this file and line, minutes after it was written — the guard working
# against its own author, which is the only test of a guard that counts.
ggq=$(grep -cE '\|[[:space:]]*grep[[:space:]]+-[a-zA-Z]*q' <<<"$ggbody") || true
case "$ggq" in ''|*[!0-9]*) ggq=0 ;; esac
[ "$ggq" = 0 ] \
  && ok "H0a gate-guard itself obeys R-SD-1 rule 5" \
  || no "H0a gate-guard violates the rule this repo enforces on every other script ($ggq site(s))"

echo
echo "== F. rulings (R-SP-1) =="
# The detector reads the guard's LOGIC, never a token: a file that merely mentions the ruling
# satisfies a grep and guards nothing, which is the shape the parent's audit found twice.
[ -f docs/RULINGS.md ] && ok "the rulings register exists and is tracked" \
                       || no "docs/RULINGS.md missing — a ruling living outside the filesystem is a breach"
_rs="che""ck-sync.sh"
csbody=$(sed -E "$_sdstrip" scripts/check-sync.sh)
for needle in 'UNDECLARED pack(s) on disk' 'a pack is Lite-only by definition' "no 'why' is recorded"; do
  grep -qF -- "$needle" <<<"$csbody" \
    && ok "R-SP-1 guard carries the logic: ${needle}" \
    || no "R-SP-1 guard is missing the logic for: ${needle}"
done
# The map must declare the relation and the convention, or the guard enumerates a path nobody agreed.
mapbody=$(cat docs/SYNC-CORRELATION.md)
grep -qF -- '.claude/skills/packs/<pack-name>/' <<<"$mapbody" \
  && ok "R-SP-1 the pack path convention is stated in the map the guard enumerates" \
  || no "R-SP-1 the pack path convention is undeclared — the guard would enumerate a path nobody agreed"
grep -qF -- 'proposal-only under A4a' <<<"$mapbody" \
  && ok "R-SP-1 A4a is recorded: declaring a pack grants no credentials" \
  || no "R-SP-1 A4a constraint absent from the map"
# R-PD-1, same detector shape and for the same reason: proving the cap behaviourally in-suite needs
# a phantom directory in the live tree, which is the C-13/C-14 class. The behavioural proof is the
# gate control, run by hand and recorded in docs/security/redteam-1.md.
for needle in 'R-PD-1 VIOLATED' 'cap LIFTED' 'pack cap armed and observed'; do
  grep -qF -- "$needle" <<<"$csbody" \
    && ok "R-PD-1 cap guard carries the branch: ${needle}" \
    || no "R-PD-1 cap guard is missing the branch: ${needle}"
done
# The cap must key on the ledger, not on a count someone maintains by hand.
grep -qF -- 'LITE-SECURITY-1' <<<"$csbody" \
  && ok "R-PD-1 the cap lifts on an APPROVED ledger row, not on recollection" \
  || no "R-PD-1 the cap has no ledger binding — it could not lift or hold mechanically"

echo
echo "== E. release trail =="
TRAIL="logs/release-audit.jsonl"
n=0; [ -f "$TRAIL" ] && n=$(grep -c . "$TRAIL" 2>/dev/null); n=${n:-0}
# An EMPTY trail is not a clean trail. "no self-release in 0 lines" is trivially true, and this
# section reported exactly that as a PASS the moment the stress harness stopped writing here —
# a vacuous pass in the check guarding this build's central law. Absent and empty are the same
# answer and both are announced, never passed.
if [ "$n" = 0 ]; then
  sk "release trail is absent or empty — no dispatch has released anything, so the law below is untested here (stress runs are run-scoped by design)"
else
  selfn=$(jq -r 'select(.from_agent == .released_by) | .task_id' "$TRAIL" 2>/dev/null | tr '\n' ' ')
  [ -z "$selfn" ] && ok "no self-release in $n trail lines" || no "SELF-RELEASE in trail for task_id(s): $selfn"
  noidn=$(jq -r 'select((.task_id // "") == "") | .ts' "$TRAIL" 2>/dev/null | tr '\n' ' ')
  [ -z "$noidn" ] && ok "every release line carries a task_id" || no "release lines with no task_id at: $noidn"
fi

echo
echo "== F. README bindings (README-SYNC-1) =="
# The parent's CR-027 lesson, ported after this README carried four suite counts frozen at the L2
# era for the life of the build: the file a new reader starts from either binds its numbers or
# loses them. The README now states ONE count — wired hooks — and it is bound here; every other
# figure was made agnostic, so there is nothing left to rot.
rhw=$(grep -m1 -oE '^\*\*[0-9]+ wired hooks' README.md)
rhw=$(printf '%s' "$rhw" | grep -oE '[0-9]+')
case "$rhw" in ''|*[!0-9]*) rhw="" ;; esac
lhw=$(jq -r '[.hooks[]?[]?.hooks[]?.command] | length' .claude/settings.json 2>/dev/null)
case "$lhw" in ''|*[!0-9]*) lhw=0 ;; esac
if [ -z "$rhw" ]; then
  no "F1 README states no wired-hook count to bind — the claim was removed, not updated"
elif [ "$rhw" = "$lhw" ]; then
  ok "F1 README wired-hook count matches settings ($lhw)"
else
  no "F1 README says $rhw wired hooks, settings wire $lhw"
fi
# The defect actually found at README-SYNC-1: a reference-style link with no definition renders as
# literal brackets and points nowhere, and nothing noticed for the life of the build. Strip inline
# links and code spans, then require every residual [label] to carry a [label]: definition.
rref=$(sed -E 's/\[[^][]*\]\([^)]*\)//g; s/`[^`]*`//g' README.md | grep -oE '\[[A-Za-z][^][]*\]' | sort -u)
rmiss=""
while IFS= read -r rl; do
  [ -n "$rl" ] || continue
  rdef=$(grep -cF "$rl:" README.md)
  case "$rdef" in ''|*[!0-9]*) rdef=0 ;; esac
  [ "$rdef" -ge 1 ] || rmiss="$rmiss $rl"
done <<RREOF
$rref
RREOF
if [ -z "$rref" ]; then
  ok "F2 no reference-style links in README (inline only) — nothing to dangle"
elif [ -z "$rmiss" ]; then
  ok "F2 every reference-style link in README has a definition"
else
  no "F2 dangling reference(s) in README:$rmiss — they render as literal brackets"
fi

# HARNESS-CONV-1 / R-PR-1 — same two detectors as the parent, against this repo's own bytes.
rpa=$(mktemp -d); mkdir -p "$rpa/hooks" "$rpa/logs"
cp hooks/bash-blocker.sh hooks/_common.sh "$rpa/hooks/"
printf '%s' "$(jq -cn --arg c "sudo rm x" '{tool_name:"Bash",tool_input:{command:$c}}')" \
  | CLAUDE_PROJECT_DIR="$rpa" "$rpa/hooks/bash-blocker.sh" >/dev/null 2>&1; rpu=$?
printf '%s' "$(jq -cn --arg c "git clone https://x/y" '{tool_name:"Bash",tool_input:{command:$c}}')" \
  | CLAUDE_PROJECT_DIR="$rpa" "$rpa/hooks/bash-blocker.sh" >/dev/null 2>&1; rpb=$?
{ [ "$rpu" = 2 ] && [ "$rpb" = 2 ]; } \
  && ok "R-PR-1 universal precedes profile AND missing resolver fails closed (rc $rpu/$rpb)" \
  || no "R-PR-1 order/fail-direction broken — universal rc=$rpu build rc=$rpb (want 2/2, no resolver)"
rm -rf "$rpa"
rpc=$(mktemp -d); mkdir -p "$rpc/.claude" "$rpc/logs"
printf '{"profile":"node-app"}' > "$rpc/.claude/harness-profile.json"
printf '%s' "$(jq -cn --arg c "git clone https://x/y" '{tool_name:"Bash",tool_input:{command:$c}}')" \
  | CLAUDE_PROJECT_DIR="$rpc" ./hooks/bash-blocker.sh >/dev/null 2>&1; rpr=$?
rpn=$(grep -c . "$rpc/logs/deny-audit.jsonl" 2>/dev/null || true)
case "$rpn" in ''|*[!0-9]*) rpn=0 ;; esac
{ [ "$rpr" = 2 ] && [ "$rpn" -ge 1 ]; } \
  && ok "R-PR-1 two-root: a session-root marker cannot loosen the live blocker; record lands at the session root" \
  || no "R-PR-1 two-root broken — rc=$rpr (want 2) records=$rpn (want >=1)"
rm -rf "$rpc"

printf '\n== validate-lite: %s PASS / %s SKIP / %s FAIL ==\n' "$P" "$S" "$F"
[ "$F" = 0 ] || exit 1
