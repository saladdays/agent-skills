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

## プラグインの命名規則

### プラグイン名（ディレクトリ名）

- **ケバブケース**（小文字 + ハイフン区切り）: `design-md`, `search-best-practice`, `roundtable`
- ユーザーがインストール時に指定する名前になる（`/plugin install <プラグイン名>@saladdays-skills`）
- 短く、何をするか想像できる名前にする

### スキル名（skills/ 配下のディレクトリ名）

- **動詞または動作を表す単語**: `generate`, `search`, `convene`
- プラグイン名とは別に、スキルの呼び出し名になる（`/design-md:generate`）
- 1プラグインに複数スキルを持てるが、メインのスキルは1つに絞る

### 呼び出し形式

`/<プラグイン名>:<スキル名>` — 例: `/roundtable:convene [議題]`

## プラグインの作成手順

### 1. ディレクトリ構造をつくる

```
plugins/<plugin-name>/
├── .claude-plugin/plugin.json   — Claude Code 向けメタデータ
├── .cursor-plugin/plugin.json   — Cursor 向けメタデータ
├── CLAUDE.md                    — 開発ルール（設計思想、テスト方法等）
├── README.md                    — 利用者向けドキュメント（ストアページ）
└── skills/
    └── <skill-name>/
        ├── SKILL.md             — スキル本体（YAML frontmatter + 実行手順）
        └── references/          — 補足資料（必要に応じて）
```

### 2. plugin.json を書く

```json
{
  "name": "<plugin-name>",
  "description": "1文の説明",
  "version": "1.0.0",
  "author": { "name": "saladdays" },
  "license": "MIT",
  "skills": "./skills/"
}
```

`.claude-plugin/plugin.json` と `.cursor-plugin/plugin.json` の両方に配置する（内容は同一で可）。

### 3. SKILL.md を書く

```yaml
---
name: <skill-name>
description: >
  スキルの説明。どんなときに使うか。
argument-hint: "[引数の説明]"
---
```

frontmatter の後にスキルの実行手順を Markdown で記述する。

### 4. マーケットプレイスに登録する

`.claude-plugin/marketplace.json` と `.cursor-plugin/marketplace.json` の `plugins` 配列にエントリを追加する。

### 5. ドキュメントを書く

- `CLAUDE.md` — 開発者向け（設計思想、重要ファイル、テスト方法）
- `README.md` — 利用者向け（後述の「プラグイン README の書き方」に従う）
- ルートの `CLAUDE.md` のプラグイン一覧にも追加する

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
- なぜこう動くのか（ロジック・学術的根拠の噛み砕いた解説）
- 背景・参考資料へのリンク

### 書き方の指針

- 冒頭は「ユーザーの課題」から始める（ツール説明書にしない）
- 機能説明ではなくユーザー価値を伝える
- 項目が空欄になるくらいなら省略する（テンプレートを埋める作業にしない）
- 各プラグインの体験を最適化する方向で書く（画一的にしない）
- 非エンジニアの利用者を想定する（技術的な例だけでなく、事業戦略・デザイン・組織設計等の例も含める）

### ロジック解説の書き方

プラグインに学術的根拠や独自のロジックがある場合、「なぜこう動くのか」セクションで解説する。

- **文体**: 専門用語を避けず、ただし初出時は意味が伝わるように書く。大学生〜社会人が自然に読める文体
- **内容の噛み砕き方**: 学術的な裏付けを維持しつつ、仕組みの本質を平易に説明する。予備知識がなくても一読で理解できる明快さを目指す
- **具体例を添える**: 抽象的な原理だけでなく、読者が想像できる具体例をセットにする。技術例と非技術例の両方を含める
- **学術的根拠の示し方**: 研究名・人名は自然な文脈で織り込む（「〜と呼ばれています」「〜の研究に基づいています」）。参考文献リストではなく、説明の中に溶け込ませる
- **ロジック自体の価値に言及する**: レポートの内容だけでなく、そこで使われている考え方（情報評価の手法、専門家選定の原理等）自体がユーザーにとって有用であることを伝える

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

### 他のAIツール

SKILL.md をAIツールのスキルディレクトリにコピーしてください。
```

## プラグイン一覧

- [design-md](./plugins/design-md/) — 対話で DESIGN.md を生成
- [search-best-practice](./plugins/search-best-practice/) — ベストプラクティスを調査し構造化レポートにまとめる
- [roundtable](./plugins/roundtable/) — 多分野の専門家を集めて構造化された議論
