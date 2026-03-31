# saladdays/agent-skills

AI コーディングツール向けのプラグインマーケットプレイス。

## 構造

```
plugins/
└── <plugin-name>/
    ├── .claude-plugin/plugin.json   — プラグインメタデータ
    ├── .cursor-plugin/plugin.json   — Cursor 向けメタデータ
    ├── CLAUDE.md                    — プラグイン固有の開発ルール
    ├── README.md                    — 利用者向けドキュメント
    └── skills/                      — スキル定義
```

## 開発ルール

- 各プラグインの開発ルールは `plugins/<plugin-name>/CLAUDE.md` を参照
- プラグインを追加したら `marketplace.json`（`.claude-plugin/` と `.cursor-plugin/` の両方）に登録する
- コミットメッセージ: `type(scope): description`（scope はプラグイン名）

## プラグイン README の書き方

各プラグインの README.md はマーケットプレイスのストアページ本文に相当する。
「初見のユーザーがインストールして使い始められるか」を基準に書く。

### 必須要素

- **バリュープロポジション**（冒頭1文。「何であるか」ではなく「何が解決されるか」）
- **こんな方に**（ターゲットユーザー / ペルソナ。2-4項目）
- **インストール手順**（Claude Code / Cursor / 手動の3パターン）
- **使い方**（最小限のコマンド例 + 期待される結果の説明）
- **ライセンス**

### 推奨要素（内容があれば含める）

- Before/After または問題-解決の対比
- 出力フォーマット・成果物の説明
- 完成例・サンプル出力へのリンク
- 設計思想・大切にしていること
- 背景・参考資料へのリンク

### 書き方の指針

- 冒頭は「ユーザーの課題」から始める（ツール説明書にしない）
- 機能説明ではなくユーザー価値を伝える
- 項目が空欄になるくらいなら省略する（テンプレートを埋める作業にしない）
- 各プラグインの体験を最適化する方向で書く（画一的にしない）

### インストール手順の共通フォーマット

```markdown
### Claude Code

Claude Code の画面で、以下の2行を実行するだけです。

/plugin marketplace add saladdays/agent-skills
/plugin install <プラグイン名>@saladdays-skills

インストールできたら `/<スキル呼び出し>` で開始します。

> これは Claude Code の「プラグイン」という仕組みです。1回入れたら、あとはずっと使えます。

### Cursor

Cursor のプラグインマーケットプレイスから `<プラグイン名>` を検索してインストール。

> [Cursor Marketplace](https://cursor.com/marketplace) に公開後はワンクリックでインストールできます。

公開前は手動でルールをコピーできます：

git clone https://github.com/saladdays/agent-skills.git /tmp/agent-skills
cp -r /tmp/agent-skills/plugins/<プラグイン名>/skills/ .cursor/skills/

### 他のAIツール

SKILL.md をAIツールのスキルディレクトリにコピーしてください。
```

## プラグイン一覧

- [design-md](./plugins/design-md/) — 対話で DESIGN.md を生成
- [search-best-practice](./plugins/search-best-practice/) — ベストプラクティスを調査し構造化レポートにまとめる
- [roundtable](./plugins/roundtable/) — 多分野の専門家を集めて構造化された議論
