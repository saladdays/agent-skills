# context-handoff プラグイン開発ルール

## 概要

セッション間のコンテキストを自動で引き継ぐプラグイン。
「保存も再開も意識しない」体験を、三層保存（差分追記・PostCompact・手動）と自動読み込みで実現する。

## 重要ファイル

| ファイル | 役割 |
|---|---|
| `skills/save/SKILL.md` | 手動保存スキル本体（L3）。初回セットアップもここから |
| `skills/save/references/handoff-format.md` | handoff.md のフォーマット仕様（SSOT） |
| `skills/save/references/setup-guide.md` | フック設定・セットアップガイド |
| `skills/save/references/auto-save-rules.md` | .claude/rules/ に配置する自動保存ルール（L1/L2） |

## 設計思想

- **会話要約ではなく構造化スナップショット**: Anthropic の claude-progress.txt パターンに基づく
- **git に残らない情報だけを保存**: 意図・判断理由・棄却した試行・次のステップ
- **Dead Ends は最重要セクション**: 同じ失敗の繰り返しが最悪の体験
- **SKILL.md は80行以下**: 常駐型スキルのためコンテキスト効率が全体に影響
- **コンパクション耐性**: @import で読み込むため、コンパクション後も handoff.md は再読み込みされる

## 三層保存モデル

| 層 | トリガー | AI判断 | 信頼性 |
|---|---|---|---|
| L1: 差分追記 | .claude/rules/ ルール | あり | 中（遵守率80-90%） |
| L2: PostCompact | フック自動 | あり（整理） | 中-高 |
| L3: 手動保存 | `/context-handoff:save` | あり | 最高 |

## テスト方法

1. `/context-handoff:save` で初回セットアップ → フック設定が正しいか確認
2. 作業中に設計判断 → L1 追記が発生するか確認
3. コンテキストを意図的に消費 → PostCompact でL2整理が動くか確認
4. 新セッション開始 → 自動読み込み・3行サマリ表示を確認
5. ブランチ切り替え → 対応する handoff.md に切り替わるか確認
6. ブランチをマージして main に戻る → main 用ファイルが無いとき、旧ブランチのファイルへ誘導されるか確認
7. 旧版フックがある状態で `/context-handoff:save` → hook-version の比較と更新提案が出るか確認
8. `"` を含むブランチ名・ユーザー別運用（`HANDOFF_SUFFIX`）でフック出力が有効な JSON か、他ユーザーのファイルを拾わないか確認
