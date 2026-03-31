# best-practice プラグイン開発ルール

## 概要

世の中のベストプラクティスを Web 検索で調査し、鮮度・信頼性・多角的視点を考慮して
構造化レポートにまとめるプラグイン。技術・ビジネス・教育・デザイン等あらゆるドメインに対応。

## 重要ファイル

| ファイル | 役割 |
|---|---|
| `skills/search/SKILL.md` | スキル本体。6フェーズのパイプライン定義 |
| `skills/search/references/freshness.md` | 鮮度分類・二層ラベルモデル |
| `skills/search/references/source-tiers.md` | ソースティアリング・権威評価基準 |
| `skills/search/references/verification.md` | 検証チェックリスト（SIFT/CRAAP） |
| `skills/search/references/perspectives.md` | 専門視点タクソノミ・自動選定ロジック |
| `skills/search/references/output-format.md` | 出力テンプレート・不確実性の表現 |

## 設計思想

- **原理ベース**: キーワードリストではなく原理で判断する。未知のドメインにも対応できる
- **二層ラベルモデル**: 原則（Layer S: 安定）とツール（Layer V: 流動）で鮮度を分離管理
- **反証の必須化**: アンチパターンを意図的に探し、一面的な結論を防止する
- **深度の自動判定**: Quick / Standard / Deep を Phase 0 で決定し、コスト効率を最適化
- **参照ファイルの遅延読み込み**: Quick では SKILL.md だけで完結。深度に応じて references を読む

## 開発方針

- SKILL.md がパイプラインの正。references/ は詳細の分離
- 新しいドメインへの対応は perspectives.md への追加で行う（SKILL.md は原理レベルを維持）
- 出力フォーマットの変更は output-format.md を修正（SKILL.md は最低限の要件のみ記載）
- references/ の各ファイルは独立して読めるよう自己完結させる

## テスト方法

15 トピック × 3 ラウンド（Quick / Standard / Deep）で全件完走を確認:
- 技術系: Kubernetes, React, セキュリティ等
- 非技術系: 価格設定, 読書習慣, 組織設計等
- 高リスク: 医療, 法務, 金融等

テスト結果は `tests/` に保存（.gitignore で除外済み）。
