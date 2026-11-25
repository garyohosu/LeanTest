/-!
# Proofs.Basic

LeanTest の最小構成で検証する4つの基本定理。
証明を回避する構文や独自公理は使用しない (scripts/verify.sh で検査)。
-/

-- 証明未完了 (`sorry` 等) の警告をエラーとして扱う
set_option warningAsError true

namespace LeanTest

/-- 自然数の加算の交換則 -/
theorem add_comm' (a b : Nat) : a + b = b + a := by
  induction b with
  | zero => rw [Nat.add_zero, Nat.zero_add]
  | succ k ih => rw [Nat.add_succ, ih, Nat.succ_add]

/-- 自然数の加算の結合則 -/
theorem add_assoc' (a b c : Nat) : a + b + c = a + (b + c) := by
  induction c with
  | zero => rfl
  | succ k ih => rw [Nat.add_succ, Nat.add_succ, Nat.add_succ, ih]

/-- 自然数を2倍する関数 -/
def double (n : Nat) : Nat := n + n

/-- `double n = 2 * n` -/
theorem double_eq_two_mul (n : Nat) : double n = 2 * n := by
  unfold double
  omega

/-- `n + 0 = n` を帰納法で証明 -/
theorem add_zero' (n : Nat) : n + 0 = n := by
  induction n with
  | zero => rfl
  | succ k _ih => rfl

end LeanTest

-- 定理の型を確認
#check @LeanTest.add_comm'
#check @LeanTest.add_assoc'
#check @LeanTest.double_eq_two_mul
#check @LeanTest.add_zero'

-- 依存公理を確認 (追加公理が無いこと)
#print axioms LeanTest.add_comm'
#print axioms LeanTest.add_assoc'
#print axioms LeanTest.double_eq_two_mul
#print axioms LeanTest.add_zero'
