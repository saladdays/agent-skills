---
name: save
description: >
  セッション間のコンテキストを構造化して保存する。
  「引き継ぎ」「セッション保存」「handoff」「コンテキスト保存」等で使用。
  通常は自動保存（L1/L2）で十分。明示的に高品質な保存をしたいときに呼ぶ。
argument-hint: "[省略可。保存時の補足メモ]"
---

# Context Handoff — セッション間引き継ぎ

## 設計原則

- **会話の要約ではなく、作業状態のスナップショットを保存する**
- **git で復元可能な情報は書かない**（コード差分、ファイル一覧等は git が持つ）
- **保存すべきは「git に残らない情報」**：意図、判断理由、棄却した試行、次のステップ
- Dead Ends の棄却理由は要約・圧縮しない（最も忘れられやすく、最も再現コストが高い）

## 三層保存モデル

| 層 | トリガー | 内容 |
|---|---|---|
| **L1: 差分追記** | 設計判断・アプローチ棄却の瞬間（自動） | handoff.md に1行追記 |
| **L2: PostCompact** | コンパクション発生時（自動フック） | handoff.md の全体整理 |
| **L3: 手動保存** | `/context-handoff:save`（このスキル） | フル品質で書き直し |

L1/L2 は [auto-save-rules.md](references/auto-save-rules.md) で動作する。
このスキル（L3）はフル品質の保存が必要なとき、または初回セットアップ時に使う。

## 実行手順

### 初回実行時（.context/ が存在しない場合）

1. `.context/` と `.context/hooks/` と `.context/archive/` ディレクトリを作成
2. [setup-guide.md](references/setup-guide.md) のフックスクリプト3ファイルを `.context/hooks/` に書き出し、実行権限を付与
3. `.claude/settings.json` に [setup-guide.md](references/setup-guide.md) の hooks 設定と permissions 設定を**マージ**して書き込む（既存設定を上書きしない）
4. `.claude/rules/context-handoff.md` に [auto-save-rules.md](references/auto-save-rules.md) の自動保存ルールを配置（プロジェクトの CLAUDE.md は変更しない）
5. 現在の作業状態から handoff.md を生成（手動保存 L3 の手順に従う）
6. `.context/` の git 管理について確認: 「個人開発なら git 追跡（別 PC で引き継ぎ可能）、チーム開発なら .gitignore 追加を推奨。どちらにしますか？」
7. セットアップ結果を報告し、リカバリー方法を案内:
   `handoff.md が壊れた場合は削除して /context-handoff:save で再生成できます`

### 既存セットアップの更新（.context/hooks/ が存在する場合）

1. `.context/hooks/session-start.sh` 先頭の `# hook-version:` を [setup-guide.md](references/setup-guide.md) のスクリプトと比較する（行が無ければ旧版）
2. 古ければ差分を提示し、承認後に setup-guide.md のスクリプトで上書きする。`HANDOFF_SUFFIX` などユーザーが変更した行は引き継ぐ
3. 更新後は通常の手動保存（L3）へ進む

### 手動保存（L3）の実行

1. 現在のコンテキストを分析し、保存すべき情報を選別
   - 優先度: Environment → Dead Ends → Decisions → Status → Next
   - git diff で復元可能な情報は除外
2. [handoff-format.md](references/handoff-format.md) のフォーマットに従い構造化
3. `.context/handoff-{safe-branch}.md` に書き出し（ブランチ名のスラッシュ `/` とコロン `:` はハイフン `-` に変換）
4. 100行 / 1,500トークンの上限を超える場合:
   - 解決済みの Dead Ends を `.context/archive/` に移動
   - 現在の作業に無関係な Decisions を `.context/archive/` に移動
   - archive は直近5ファイルのみ保持（超過分は古いものから削除）
5. 保存結果を1行で報告: `保存しました: [N]タスク, [N]判断, [N]棄却`

## 参照ファイル

| ファイル | 内容 |
|---|---|
| [handoff-format.md](references/handoff-format.md) | handoff.md のフォーマット仕様 |
| [setup-guide.md](references/setup-guide.md) | フック設定・セットアップガイド |
| [auto-save-rules.md](references/auto-save-rules.md) | .claude/rules/ に配置する自動保存ルール |
