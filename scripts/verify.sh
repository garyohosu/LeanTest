#!/usr/bin/env bash
# LeanTest 検証スクリプト (ローカル / CI 共通)
#  1. 禁止キーワード (sorry / admit / axiom / unsafe) が証明ファイルに無いこと
#  2. lake build が成功すること
#  3. lake env lean Proofs/Basic.lean が成功し、依存公理が Lean 標準公理のみであること
#  4. 偽の命題 (1 = 2) の証明が Lean に拒否される (非ゼロ終了) こと
set -uo pipefail

cd "$(dirname "$0")/.."
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== [1] forbidden keywords"
if grep -nE '\b(sorry|admit|axiom|unsafe)\b' Proofs/*.lean Proofs.lean | grep -vE '^\S+:[0-9]+:\s*(--|#print axioms)'; then
  fail "forbidden keyword found"
fi
echo "OK"

echo "== [2] lake build"
lake build || fail "lake build failed"
echo "OK"

echo "== [3] lake env lean Proofs/Basic.lean"
out="$(lake env lean Proofs/Basic.lean 2>&1)"; rc=$?
echo "$out"
[ $rc -eq 0 ] || fail "lean exited with $rc"
# Lean 標準公理: propext, Quot.sound, Classical.choice
bad="$(echo "$out" | grep 'depends on axioms' | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' \
  | sed -E 's/^ +| +$//g' | grep -vxE 'propext|Quot\.sound|Classical\.choice' || true)"
[ -z "$bad" ] || fail "non-standard axioms: $bad"
n="$(echo "$out" | grep -cE 'depends on axioms|does not depend on any axioms')"
[ "$n" -eq 4 ] || fail "expected 4 axiom reports, got $n"
echo "OK (axioms: standard only)"

echo "== [4] false proposition must be rejected"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf 'theorem bad : 1 = 2 := by\n  decide\n' > "$tmpdir/False.lean"
lake env lean "$tmpdir/False.lean"; rc=$?
[ $rc -ne 0 ] || fail "false proposition was accepted"
echo "OK (rejected with exit code $rc)"

echo "ALL CHECKS PASSED"
