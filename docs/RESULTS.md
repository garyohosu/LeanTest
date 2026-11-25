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
'LeanTest.add_comm'' depends on axioms: [propext, Quot.sound]
'LeanTest.add_assoc'' does not depend on any axioms
'LeanTest.double_eq_two_mul' depends on axioms: [propext, Quot.sound]
'LeanTest.add_zero'' does not depend on any axioms
```

- 標準公理: `propext`, `Quot.sound` (`rw` / `omega` 経由)。`Classical.choice` は不使用。
- 追加公理: なし。`sorryAx` もなし。

### エラーと修正内容

| 発生箇所 | 内容 | 修正 |
|---|---|---|
| elan 導入 | `powershell -File elan-init.ps1 -NoPrompt 1` で `Cannot convert value "System.String" to type "System.Boolean"` | スクリプトを `& .\elan-init.ps1 -NoPrompt $true` で呼び出し直して解決 |
| `add_comm'` の初版 | `induction` の後で `omega` が全体を閉じており、帰納法の仮定を使っていなかった (エラーではない) | `Nat.add_succ` / `Nat.succ_add` を `rw` する帰納法の証明に書き直した |
| `scripts/verify.sh` 初回 | 禁止キーワード検査が `Proofs/Basic.lean` 冒頭の説明文中の単語 `sorry` 等に反応して FAIL | 説明文の言い回しを変更 (定理・証明は変更なし) |

Lean の証明自体はエラーなく成功したため、命題の弱化・削除は行っていません。

### CI

`.github/workflows/lean.yml` を追加しました。push 後の GitHub Actions の結果は下記に追記します。
