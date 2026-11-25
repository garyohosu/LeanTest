# LeanTest

Claude Code が Lean 4 の証明コードを生成し、実際に Lean を実行して検証し、失敗時に修正する実験の最小構成です。外部の有料 AI API は使用しません。Mathlib は導入していません。

## 構成

```
.
├── lean-toolchain            # Lean バージョン固定 (leanprover/lean4:v4.36.0)
├── lakefile.toml             # Lake 設定 (lean_lib Proofs, warningAsError = true)
├── lake-manifest.json        # 依存マニフェスト (依存なし)
├── Proofs.lean               # ライブラリのルート (Proofs.Basic を import)
├── Proofs/Basic.lean         # 証明本体 (4定理)
├── scripts/verify.sh         # ローカル / CI 共通の検証スクリプト
├── .github/workflows/lean.yml# GitHub Actions
└── docs/RESULTS.md           # 実行記録
```

## 証明した定理 (`Proofs/Basic.lean`, 名前空間 `LeanTest`)

| 定理 | 型 | 依存公理 |
|---|---|---|
| `add_comm'` | `∀ (a b : Nat), a + b = b + a` | propext, Quot.sound |
| `add_assoc'` | `∀ (a b c : Nat), a + b + c = a + (b + c)` | なし |
| `double_eq_two_mul` | `∀ (n : Nat), double n = 2 * n` (`double n := n + n`) | propext, Quot.sound |
| `add_zero'` | `∀ (n : Nat), n + 0 = n` (帰納法) | なし |

依存公理はいずれも Lean 標準公理 (`propext`, `Quot.sound`, `Classical.choice`) の範囲内で、独自 axiom や `sorryAx` はありません。

## 導入方法

1. elan (Lean のツールチェーン管理) を公式手順で導入します。
   - Windows (PowerShell):
     ```powershell
     curl -O --location https://elan.lean-lang.org/elan-init.ps1
     powershell -ExecutionPolicy Bypass -f elan-init.ps1
     ```
   - Linux / macOS:
     ```sh
     curl https://elan.lean-lang.org/elan-init.sh -sSf | sh
     ```
2. このリポジトリで `lake build` を実行すると、`lean-toolchain` に書かれた Lean v4.36.0 が自動で取得されます。

## 実行コマンド

```sh
lake build                       # ライブラリ Proofs をビルド (証明を検証)
lake env lean Proofs/Basic.lean  # 単体ファイルとして検証 (#check / #print axioms を表示)
./scripts/verify.sh              # 上記 + 禁止キーワード検査 + 公理検査 + 偽命題の拒否確認
```

`scripts/verify.sh` の検査内容:

1. `Proofs/` に `sorry` / `admit` / `axiom` / `unsafe` が含まれないこと
2. `lake build` が成功すること (`warningAsError = true` により `sorry` の警告もエラー扱い)
3. `lake env lean Proofs/Basic.lean` が成功し、`#print axioms` の結果が標準公理のみであること
4. 一時ファイルの偽命題 `theorem bad : 1 = 2` が Lean に拒否され、非ゼロ終了すること

## CI

`.github/workflows/lean.yml` が push / pull_request で `scripts/verify.sh` を実行します。

- `actions/checkout` v7.0.1 (SHA 固定)
- `leanprover/lean-action` v1.7.1 (SHA 固定, 公式)
- 権限は `contents: read` のみ

## 結果

ローカル (Windows 11, Lean 4.36.0) で 4 定理の検証、公理検査、偽命題の拒否をすべて確認しました。詳細は [docs/RESULTS.md](docs/RESULTS.md) を参照してください。

## 次段階 (未実装)

AI が命題を提案し、Lean の検証結果に基づいて修正し、証明済みの定理だけを蓄積する仕組みを検討します。命題の新規性や数学的価値は形式証明とは別に評価します。
