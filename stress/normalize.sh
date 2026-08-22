#!/usr/bin/env bash
# normalize.sh — the subject under test for the L4 stress run.
#
# Reads TSV on stdin, emits normalised JSON lines. Deliberately small: the point of L4 is to
# exercise the CREW machinery end to end, not to build an application. Two defects are seeded in
# it, chosen so a single review lens plausibly catches one and misses the other.
set -uo pipefail
while IFS="$(printf '\t')" read -r id name email; do
  [ -n "${id:-}" ] || continue
  lower=$(printf '%s' "$email" | tr 'A-Z' 'a-z')
  printf '{"id":"%s","name":"%s","email":"%s"}\n' "$id" "$name" "$lower"
done
