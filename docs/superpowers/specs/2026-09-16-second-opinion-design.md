# second-opinion プラグイン 設計書

作成日: 2026-09-16
状態: 実装済み（2026-09-17、v1.0.0）。§6 / §7 は実装時のレビューで更新済み

## 1. 目的

同じモデルで作業し続けると、自己選好バイアスと追従性（sycophancy）により判断が偏る。
本プラグインは、実装前の設計判断や行き詰まりの場面で、**別系統のモデルに問題だけを渡して独立に解かせ**、
自分の案と突き合わせることで、偏りを自覚した上で人間が決められる状態をつくる。

コードレビューは対象外（既存の `/codex:review`、`/code-review` に任せる）。対象は「考え方・判断」そのもの。

## 2. ユーザーストーリー

**主ストーリー（設計判断）**

> 👨 **誰が** AI コーディングツールで設計や実装を進める人が
> 🕑 **場面** 方針・アプローチ・トレードオフを決めようとしている瞬間に
> 💭 **欲求** 今使っているモデルの癖に引きずられず、別の頭で見た判断も知りたい
> ✋ **行動** `/second-opinion:ask` を呼ぶ（または AI の提案に「はい」と答える）
> ✨ **変化** 別モデルの独立した見解と自分の案の相違点が表になり、偏りを自覚した上で決められる

**副ストーリー（行き詰まり）**

> 👨 同じ人が
> 🕑 同じ箇所の修正が 2 回続いて抜けられないとき
> 💭 問題の見立て自体を疑いたい
> ✋ 起きた事実だけを渡して別モデルに見立てさせる
> ✨ 自分の解釈に無い原因候補が出てきて、問題定義を一段上から見直せる

## 3. スコープ

**入れるもの（初版）**

- Claude Code → Codex CLI、Codex CLI → Claude Code の双方向
- 独立回答 + 突き合わせ表（基本）。相違があるとき、または判断が大きいときに批判ラウンドを提案
- 手動起動 `/second-opinion:ask [議題]` と、文脈検知による 1 行の提案（実行はしない）
- ブリーフの「事実は渡す、解釈は渡さない」ルール

**外すもの（初版）**

- Cursor からの起動、Gemini 等の第 3 モデル。`ask.sh` の `--from` と呼び出し分岐を増やせば足せる構造にしておく
- 文脈検知による自動実行（外部モデルの費用が勝手に発生するため）
- 会話全体の転送（独立性が下がるため）
- コード差分のレビュー

## 4. 設計の根拠（2026-09-16 調査）

| 根拠 | 設計への反映 |
|---|---|
| LLM 評価者は自分の生成物を認識して高く評価し、高性能なほど強い（NeurIPS 2024） | 別系統モデルに聞く |
| 異種モデルの誤りも相関し、両者が誤るとき 60% は同じ誤り（ICML 2025）。「一致は正確さではない」（2026） | 突き合わせ表の「一致」を検証済み扱いしない。根拠追跡列を置く |
| 誤った同意が正しいモデルを誤らせる方が、その逆より強い（2026） | 自分の案を見せる前に独立に解かせる |
| 同種モデルの無構造な議論は追従的同調を起こす（2026） | 批判ラウンドは「弱点 3 つ以上」を構造的に要求する |
| 既存ツール（codex-plugin-cc、codex-skill、consult）はいずれも自分の案や差分を先に見せる型 | 独立生成先行が差別化点。consult の「実行後に git status で汚染確認」は取り込む |

出典一覧は本書末尾。

## 5. 構成

```
plugins/second-opinion/
├── .claude-plugin/plugin.json
├── .cursor-plugin/plugin.json
├── CLAUDE.md                        — 開発ルール・テスト方法・CLI 仕様の確認日
├── README.md / README.en.md
└── skills/ask/
    ├── SKILL.md                     — 4 フェーズの手順。判断はすべてここ
    ├── scripts/ask.sh               — 相手 CLI の呼び出しだけ
    └── references/
        ├── brief-format.md          — ブリーフの書式と「渡す/渡さない」の線引き
        ├── output-format.md         — 突き合わせ表の書式
        └── trigger-rules.md         — 文脈検知で提案する条件
```

責務の分離: **判断は SKILL.md、機械的な呼び出しは ask.sh**。CLI の仕様変更は ask.sh の修正だけで吸収する。

## 6. 処理の流れ

### Phase 0: ブリーフ作成（今のモデル）

1. 会話から「問い・制約・成功条件・起きた事実・関連ファイルパス」を抜き出し、`.context/second-opinion/brief-<YYYYMMDD-HHMMSS>.md` に書く
2. 自分の案・仮説・「原因はこれだと思う」という解釈は書かない（brief-format.md の線引きに従う）
3. 自分の現時点の案と理由を `.context/second-opinion/own-<同じ timestamp>.md` に書く。相手には渡さない（後知恵で「自分」列を寄せないため）
4. 書いた内容を 3 行で「これを聞きます」とユーザーに見せ、承認を取る。ブリーフに自分の案が混ざっていないかを人間が見る最後の関所

### Phase 1: 独立回答（相手モデル）

`scripts/ask.sh --brief <path>` を実行する。回答は `.context/second-opinion/answer-<timestamp>.md` に保存され、標準出力にも返る。
終了コードが 0 以外なら、コードに応じた 1 行の説明をユーザーに返して終了する（第 7 節）。

### Phase 2: 突き合わせ（今のモデル）

自分の案と相手の回答を output-format.md の表にする。「自分」列は own ファイルから転記し、相手の回答を見て書き換えない。相手の原文は表の下に全文併記。
相違点で自分の側に寄せる表現を禁止し、「どちらを採るかは人間が決める」「一致は検証済みを意味しない」の定型 2 行を必ず付ける。

### Phase 3: 批判ラウンドの提案

次のいずれかのときだけ「自分の案を見せて弱点を突かせますか？」と 1 行で提案する。

- 相違点が 1 つ以上ある
- 議題が事業全体・セキュリティ・後戻りしにくい構造に触れる

承認されたら、ブリーフに「私たちの案」節を足した第 2 ブリーフを作り、`ask.sh --brief <path> --round critique` を実行する。
第 2 ブリーフは「弱点を最低 3 つ、代替案を最低 1 つ」を要求する。結果は Phase 2 と同じ表に追記する。

### 保存先

`.context/second-opinion/` を使う。context-handoff と同じ場所で `.gitignore` 済み。
引き継ぎファイルから「あのときのセカンドオピニオン」をパスで参照できる。

## 7. `scripts/ask.sh` の契約

```
ask.sh --brief <path> [--from claude|codex] [--round independent|critique] [--out <path>] [--timeout <sec>]
```

**相手の決め方**（上から順に評価）

1. `--from` が指定されていればそれに従う（`claude` = Claude 側から Codex へ聞く、`codex` = Codex 側から Claude へ聞く）
2. `CLAUDECODE=1` なら Claude Code 内。Codex へ聞く
3. `CODEX_SANDBOX_NETWORK_DISABLED=1` または `CODEX_SANDBOX=seatbelt` なら Codex 内。Claude へ聞く
4. どれも無ければ終了コード 2。「実行環境を判定できません。--from を指定してください」

Codex はサンドボックス無効時に環境変数を設定しないため、3 だけに頼らない。
`CODEX_SANDBOX_NETWORK_DISABLED=1` は「ネットワークが遮断されている」ときに立つ変数で、これが立った状態で
Claude 側（API 通信が要る）へ聞くと失敗しやすい。ask.sh は判定ロジックは変えずに stderr へ 1 行注意を出す。
失敗する場合はネットワーク許可（昇格）で再実行し、`--from codex` を付ける。

**呼び出し**

| 方向 | コマンド |
|---|---|
| Codex へ | `codex exec - --sandbox read-only --ephemeral -C <repo root> -o <out>`。stdin にプロンプト |
| Claude へ | `claude -p --disallowedTools Edit,Write,NotebookEdit,Bash --permission-mode dontAsk --strict-mcp-config --output-format json`。stdin にプロンプト。`result` を `<out>` に書く |

Claude 側で `--bare` は使わない。`--bare` は OAuth を読まず `ANTHROPIC_API_KEY` が必須になり、
API キーをグローバルに置かない運用ルールと衝突するため。
`disallowedTools` に `NotebookEdit` を含める（`Edit`/`Write`/`Bash` だけでは塞がれない書き込み経路のため）。
`--strict-mcp-config` は settings で許可済みの MCP ツール（外部サービスへの書き込みを含みうる）を
`--permission-mode dontAsk` のまま動かさないための保険（`--mcp-config` 以外の MCP を無視する）。

**プロンプトの組み立て**

スクリプトはブリーフの中身を解釈しない。先頭に固定の役割節を足すだけ:

> あなたは相談役です。リポジトリのファイルは読んでよいが、変更・作成・削除・コマンドによる副作用は行わない。
> 以下のブリーフに対して、独立した見解を根拠付きで述べてください。

`--round critique` のときは役割節の末尾に「提示された案の弱点を最低 3 つ、代替案を最低 1 つ挙げてください」を足す。

**副作用の検出**

実行前後で `git status --short` を比較し、差があれば stderr に警告して終了コード 3。回答ファイルは残す。

**終了コード**

| コード | 意味 | SKILL.md がユーザーに返す文 |
|---|---|---|
| 0 | 成功 | （なし） |
| 2 | 実行環境を判定できない | `--from` の指定を促す |
| 3 | 作業ツリーが変更された | 回答は保存済み。`git status` の確認を促す |
| 4 | 相手 CLI が見つからない | インストール手順の URL を案内 |
| 5 | 認証エラー | 相手 CLI でのログインを案内 |
| 6 | タイムアウト（既定 600 秒） | ブリーフを小さくするか `--timeout` 延長を案内 |
| 1 | その他 | stderr の内容をそのまま表示 |

## 8. 参照ファイルの仕様

### brief-format.md

```markdown
# Second Opinion Brief

## 問い
（1〜2 文。何を決めたいか）

## 制約
（技術・期限・既存資産など。事実のみ）

## 成功条件
（何が満たされれば良い判断と言えるか）

## 起きた事実
（行き詰まりの場合。エラー出力、試した操作とその結果。「原因はこれだと思う」は書かない）

## 関連ファイル
（パスの列挙。相手が自分で読む）

## 私たちの案   ← critique ラウンドのみ
（案と、その理由）
```

**渡さないもの:** 自分の案、仮説、解釈、会話の要約。independent ラウンドで「私たちの案」節があれば SKILL.md の自己検証で弾く。

### output-format.md

```markdown
## セカンドオピニオン: <議題>

| 論点 | 自分（<モデル名>） | 相手（<モデル名>） | 一致/相違 | 根拠を事実に遡れるか |
|---|---|---|---|---|

### 相手の原文
（全文。省略・要約しない）

---
どちらを採るかは人間が決める。
一致は「両者が同じ結論」であって「検証済み」ではない。
```

critique ラウンドの結果は「### 批判ラウンド」として同じファイルに追記する。

### trigger-rules.md

発話するのは次の 2 パターンだけ。発話は 1 行の問いの形。実行はしない。

1. 方針・ライブラリ・構造を決めようとしている発言があり、まだ実装に入っていない
2. 同じ箇所への修正が 2 回続いて解決していない

それ以外は沈黙。typo 修正、既存方針内の実装、テスト実行では発話しない。
同じセッションで断られたら、以後は同じパターンで再提案しない。

## 9. 配布形態

- Claude Code: マーケットプレイス経由。`skills/ask/scripts/ask.sh` は SKILL.md から相対パス `scripts/ask.sh` で呼ぶ
- Codex: `~/.agents/skills/second-opinion/` に `skills/ask/` の中身をコピーして使う。Codex はフォルダ名ではなく frontmatter の `name` で登録する（2026-09-17 に実機確認。`name: ask` のままだと `$ask` になる）ので、コピー後に `name: second-opinion` へ書き換える。README に手順を書く
- Cursor: 初版では起動経路を提供しない（外部 CLI 呼び出しの標準が無い）。README に明記

## 10. テスト

**スクリプト単体**（`tests/` に保存。`.gitignore` 済み）

- `--from claude` と `--from codex` の両方で終了コード 0、`<out>` に回答が書かれる
- 相手 CLI が PATH に無い状態で 4
- 実行中にファイルを変更する擬似 CLI を差し込み、3 が返り回答ファイルが残る
- `--from` 無し、環境変数無しで 2
- ブリーフに `"` や日本語が含まれても壊れない

**スキル**

- 設計判断の場面で `/second-opinion:ask` を呼び、Phase 0 のブリーフに自分の案が混ざっていないかを目視
- 相違があるケースで Phase 3 の提案が 1 行で出る。相違が無いケースで出ない
- 終了コード 2〜6 のそれぞれで、案内文が正しく出る

**文脈検知**

- 同じ箇所の修正が 2 回続いたセッションで提案が 1 行で出る
- typo 修正だけのセッションで沈黙する

**確認済みの CLI 仕様**（CLAUDE.md にも記録する）

- codex-cli 0.153.4: `codex exec [PROMPT]`、`-` で stdin、`--sandbox read-only` 既定、`--ephemeral`、`-C`、`-o`
- Claude Code 2.1.252: `claude -p`、stdin 10MB 上限、`--disallowedTools`、`--permission-mode dontAsk`、`--output-format json`
- 環境変数: `CLAUDECODE=1`（Claude Code の子プロセス）、`CODEX_SANDBOX_NETWORK_DISABLED=1` / `CODEX_SANDBOX=seatbelt`（Codex の子プロセス、サンドボックス有効時のみ）

## 11. 出典

- [LLM Evaluators Recognize and Favor Their Own Generations](https://arxiv.org/pdf/2404.13076) (NeurIPS 2024)
- [Correlated Errors in Large Language Models](https://arxiv.org/abs/2506.07962) (ICML 2025)
- [When LLMs Agree, Are They Right?](https://arxiv.org/html/2607.08065) (arXiv, 2026-07)
- [Easier to Mislead Than to Correct](https://arxiv.org/html/2606.01637) (arXiv, 2026-06)
- [The Cost of Consensus](https://arxiv.org/abs/2605.00914) (arXiv, 2026-04)
- [ReConcile](https://arxiv.org/pdf/2309.13007) (2023, rev. 2024)
- [Codex CLI: Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode)
- [Claude Code: Run Claude Code programmatically](https://code.claude.com/docs/en/headless)
- [Claude Code: Environment variables](https://code.claude.com/docs/en/env-vars)
- [openai/codex spawn.rs](https://github.com/openai/codex/blob/main/codex-rs/core/src/spawn.rs)
- [daviguides/consult](https://github.com/daviguides/consult)
- [cathrynlavery/codex-skill](https://github.com/cathrynlavery/codex-skill)
