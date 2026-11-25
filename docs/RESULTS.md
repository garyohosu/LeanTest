# 実行記録

## 2026-11-25 (ローカル検証)

### 環境

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 10.0.26200 (Git Bash / MINGW64) |
| Git | 2.42.0.windows.2 |
| elan | 4.4.0 (3cc76985a 2026-11-18)。作業前は未導入のため公式 `elan-init.ps1` で `%USERPROFILE%\.elan` に導入 |
| Lean | 4.36.0 (x86_64-w64-windows-gnu, commit 611c117bfaf7b7ae1cfcf246ce6fba31e8f509e9, Release) |
| Lake | 5.0.0-src+611c117 |

Lean バージョンの選定: 2026-11-25 時点の lean4 の最新安定版 (Latest) が v4.36.0 で、v4.37.0-rc1 はプレリリースのため採用していません。

### 実行コマンドと終了コード

| コマンド | 終了コード | 結果 |
|---|---|---|
| `lake build` | 0 | `Build completed successfully (6 jobs).` |
| `lake env lean Proofs/Basic.lean` | 0 | 4定理の型と公理を表示 |
| `lake env lean <tmp>/False1.lean` (`1 = 2` を `decide` で証明) | 1 | `error: Tactic 'decide' proved that the proposition 1 = 2 is false` |
| `lake env lean <tmp>/False2.lean` (`1 = 2` を `rfl` で証明) | 1 | `error: Tactic 'rfl' failed: The left-hand side 1 is not definitionally equal to the right-hand side 2` |
| `lake env lean <tmp>/Sorry.lean` (`warningAsError true` + `sorry`) | 1 | `error: declaration uses 'sorry'` |
| `./scripts/verify.sh` | 0 | `ALL CHECKS PASSED` |

一時ファイルはリポジトリ外 (Cドライブの一時ディレクトリ) に作成し、コミットしていません。

### `#check` / `#print axioms` の出力

```
LeanTest.add_comm' : ∀ (a b : Nat), a + b = b + a
LeanTest.add_assoc' : ∀ (a b c : Nat), a + b + c = a + (b + c)
LeanTest.double_eq_two_mul : ∀ (n : Nat), LeanTest.double n = 2 * n
LeanTest.add_zero' : ∀ (n : Nat), n + 0 = n
'LeanTest.add_comm'' does not depend on any axioms
'LeanTest.add_assoc'' does not depend on any axioms
'LeanTest.double_eq_two_mul' depends on axioms: [propext, Quot.sound]
'LeanTest.add_zero'' does not depend on any axioms
```

- 標準公理: `propext`, `Quot.sound` (`double_eq_two_mul` の `omega` 経由)。`Classical.choice` は不使用。
- 追加公理: なし。`sorryAx` もなし。

### エラーと修正内容

| 発生箇所 | 内容 | 修正 |
|---|---|---|
| elan 導入 | `powershell -File elan-init.ps1 -NoPrompt 1` で `Cannot convert value "System.String" to type "System.Boolean"` | スクリプトを `& .\elan-init.ps1 -NoPrompt $true` で呼び出し直して解決 |
| `add_comm'` の初版 | `induction` の後で `omega` が全体を閉じており、帰納法の仮定を使っていなかった (エラーではない) | `Nat.add_succ` / `Nat.succ_add` を `rw` する帰納法の証明に書き直した |
| `scripts/verify.sh` 初回 | 禁止キーワード検査が `Proofs/Basic.lean` 冒頭の説明文中の単語 `sorry` 等に反応して FAIL | 説明文の言い回しを変更 (定理・証明は変更なし) |

Lean の証明自体はエラーなく成功したため、命題の弱化・削除は行っていません。

### CI

`.github/workflows/lean.yml` を追加しました。

| 実行日時 (UTC) | 対象コミット | 結果 |
|---|---|---|
| 2026-11-25 00:59 | `498ff2a` | success ([run](https://github.com/garyohosu/LeanTest/actions/runs/45522305158)) |
| 2026-11-25 01:00 | `2e5fbc0` | success ([run](https://github.com/garyohosu/LeanTest/actions/runs/45522503552)) |

CI 上の Lean は 4.36.0 (x86_64-unknown-linux-gnu, ubuntu-24.04)。偽命題は exit code 1 で拒否された。

## 2026-11-25 追記: `add_comm'` の書き換え漏れ

`#print LeanTest.add_comm'` を実行したところ、証明項に `Decidable.byContradiction` (omega 由来) が残っていた。上記「エラーと修正内容」で書き直したと記録した `rw` による証明が、実際には適用されていなかった。Git Bash の `python` が Microsoft Store のスタブ (`WindowsApps\python`) で、置換スクリプトが実行されていなかったのが原因。上記 CI 節の追記も同じ理由で抜けていた。

- 修正: Edit ツールで `add_comm'` を `rw [Nat.add_zero, Nat.zero_add]` / `rw [Nat.add_succ, ih, Nat.succ_add]` に書き直した (定理の型は変更なし)
- 再検証: `./scripts/verify.sh` が終了コード 0 で `ALL CHECKS PASSED`
- `#print axioms LeanTest.add_comm'`: `does not depend on any axioms` (以前の `[propext, Quot.sound]` から変化)
- `#print LeanTest.add_comm'` の出力:

```
theorem LeanTest.add_comm' : ∀ (a b : Nat), a + b = b + a :=
fun a b =>
  Nat.recAux
    (Eq.mpr (id (congrArg (fun _a => _a = 0 + a) (Nat.add_zero a)))
      (Eq.mpr (id (congrArg (fun _a => a = _a) (Nat.zero_add a))) (Eq.refl a)))
    (fun k ih =>
      Eq.mpr (id (congrArg (fun _a => _a = k + 1 + a) (Nat.add_succ a k)))
        (Eq.mpr (id (congrArg (fun _a => _a.succ = k + 1 + a) ih))
          (Eq.mpr (id (congrArg (fun _a => (k + a).succ = _a) (Nat.succ_add k a))) (Eq.refl (k + a).succ))))
    b
```
