#!/usr/bin/env bash
# check-witness.sh — verification layer 2, the witness manifest (plan §4, operator answer Q4).
#
# The parent build's context/plan-corrections.md is a hand-rolled version of this: 26 documented
# fixes, each with a detector. The audit found TWO of those detectors attesting nothing — one bound
# to a comment, one to a file-mode test. That is the failure this layer is built against.
#
# Two properties the parent's registry does not have:
#
#   1. MARKERS ARE SEARCHED IN COMMENT-STRIPPED CODE. A marker that survives only inside a comment
#      is exactly the C-09 defect, where a detector matched prose describing the fix rather than the
#      fix. Every marker here must be load-bearing code.
#   2. EACH ENTRY CARRIES A CONTENT HASH OF THE ATTESTED FILE. A marker alone is a substring and can
#      drift while the file around it changes meaning. Pairing it with a hash means any edit forces
#      deliberate re-verification instead of letting a stale attestation coast.
#
# STALE is not FAIL and not PASS. The marker is still there but the file changed, so the attestation
# is unproven rather than broken. Clearing it requires `--refresh`, which re-stamps hashes and prints
# what moved — the point is that a human ran it knowingly.
set -uo pipefail
# LITE-PARITY-1: portable hashing — sha256sum is GNU-only; on macOS both sides of a compare
# come back empty and "" = "" is a SILENT FALSE PASS (the parent's rule-7 lesson). An EMPTY
# hash is a failure, never a match.
_sha256 () { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
             else shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; fi; }

cd "$(dirname "$0")/.."
MODE="${1:-check}"
MAN="docs/WITNESS-MANIFEST.md"
P=0; F=0; ST=0
pass () { P=$((P+1));  printf '  [OK]    %s\n' "$1"; }
fail () { F=$((F+1));  printf '  [FAIL]  %s\n' "$1"; }
stal () { ST=$((ST+1)); printf '  [STALE] %s\n' "$1"; }

# Anchored on the VERSIONED in-fence header, not on a prefix. The first version of this matched
# `^# WITNESS-MANIFEST` — which also matches this document's own H1 title — so extraction began at
# line 1, swallowed the prose, and --refresh then rewrote the file from that garbage and destroyed
# it. Caught because a refresh that should have restamped 13 placeholder hashes printed nothing.
# Same family as every other anchor defect here: the pattern matched something that merely looked
# like the target.
ROWS=$(awk '/^# WITNESS-MANIFEST v[0-9]+$/{f=1;next} f&&/^```/{exit} f&&NF&&!/^#/' "$MAN" 2>/dev/null)
NROW=$(printf '%s\n' "$ROWS" | grep -c . || true)
# Vacuity guard first. A manifest that parses to nothing attests nothing and reports clean — which
# is the precise defect this layer exists to make harder.
if [ "${NROW:-0}" -lt 5 ]; then
  printf '  [FAIL]  manifest parsed to %s row(s) — it attests nothing and every check below is vacuous\n' "${NROW:-0}"
  printf '\n== check-witness: 0 OK / 0 STALE / 1 FAIL ==\n'
  exit 1
fi

if [ "$MODE" = "--refresh" ]; then
  echo "== refreshing attested hashes =="
  # REFUSE TO REWRITE ON A BAD PARSE. This mode rewrites a tracked file in place, so a loose parse
  # does not merely report wrongly — it destroys the artifact, which is what happened the first time
  # this ran. Every row must carry four tab-separated fields naming a file that exists, or nothing
  # is written at all.
  badrow=""
  while IFS="$(printf '\t')" read -r id file marker hash extra; do
    [ -n "${id:-}" ] || continue
    { [ -n "${file:-}" ] && [ -n "${marker:-}" ] && [ -n "${hash:-}" ] && [ -z "${extra:-}" ] && [ -f "$file" ]; } \
      || badrow="$badrow [$id]"
  done <<EOF
$ROWS
EOF
  if [ -n "$badrow" ]; then
    printf '  [FAIL]  refusing to rewrite: malformed row(s)%s — the manifest is NOT modified\n' "$badrow"
    exit 1
  fi
  tmp=$(mktemp)
  while IFS="$(printf '\t')" read -r id file marker hash; do
    [ -n "${id:-}" ] || continue
    new=$(_sha256 "$file" 2>/dev/null | cut -c1-16)
    if [ "$new" != "$hash" ]; then printf '  %s  %s  %s -> %s\n' "$id" "$file" "$hash" "$new"; fi
    printf '%s\t%s\t%s\t%s\n' "$id" "$file" "$marker" "$new" >> "$tmp"
  done <<EOF
$ROWS
EOF
  awk -v NEW="$tmp" '
    /^# WITNESS-MANIFEST v[0-9]+$/ { print; while ((getline l < NEW) > 0) print l; inb=1; next }
    inb && /^```/ { inb=0; print; next }
    inb { next }
    { print }' "$MAN" > "$MAN.tmp" && mv "$MAN.tmp" "$MAN"
  rm -f "$tmp"
  echo "  manifest re-stamped. Re-verify every entry above before committing."
  exit 0
fi

echo "== check-witness: $NROW attested corrections =="
while IFS="$(printf '\t')" read -r id file marker hash; do
  [ -n "${id:-}" ] || continue
  if [ ! -f "$file" ]; then fail "$id: attested file is gone — $file"; continue; fi
  # Comment-stripped: a marker surviving only in prose is an attestation of nothing.
  if ! grep -qF -- "$marker" <<<"$(sed 's/#.*//' "$file")"; then
    if grep -qF -- "$marker" "$file"; then
      fail "$id: marker survives ONLY in a comment — the control it attests is gone ($file)"
    else
      fail "$id: marker absent — $file no longer carries '$marker'"
    fi
    continue
  fi
  now=$(_sha256 "$file" 2>/dev/null | cut -c1-16)
  if [ "$now" != "$hash" ]; then
    stal "$id: $file changed since attestation ($hash -> $now) — re-verify, then --refresh"
  else
    pass "$id: $file attested and unchanged"
  fi
done <<EOF
$ROWS
EOF

printf '\n== check-witness: %s OK / %s STALE / %s FAIL ==\n' "$P" "$ST" "$F"
[ "$F" = 0 ] || exit 1
[ "$ST" = 0 ] || exit 2
