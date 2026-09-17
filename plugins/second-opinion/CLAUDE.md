# second-opinion プラグイン開発ルール

## 概要

別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせるプラグイン。
Claude Code からは Codex CLI へ、Codex CLI からは Claude Code へ聞く。
対象は「考え方・判断」であり、コード差分のレビューではない。

## 重要ファイル

| ファイル | 役割 |
|---|---|
| `skills/ask/SKILL.md` | スキル本体。4 フェーズの手順。判断はすべてここ |
| `skills/ask/scripts/ask.sh` | 相手 CLI の呼び出しだけ。判定・実行・保存・汚染検出・終了コード |
| `skills/ask/scripts/ask.test.sh` | 偽 CLI による回帰テスト |
| `skills/ask/references/brief-format.md` | ブリーフの書式と「渡す/渡さない」の線引き |
| `skills/ask/references/output-format.md` | 突き合わせ表の書式 |
| `skills/ask/references/trigger-rules.md` | 文脈検知で提案する条件 |
| `docs/superpowers/specs/2026-09-16-second-opinion-design.md` | 設計書（リポジトリルート） |

## 設計思想

- **独立生成を先にする**: 自分の案を見せると相手は追従する（LLM の追従性・自己選好バイアスの研究に基づく）
- **一致は検証済みではない**: 異種モデルでも誤りは相関する（ICML 2025）。突き合わせ表に「根拠を事実に遡れるか」列を置く
- **判断は SKILL.md、機械的な呼び出しは ask.sh**: CLI の仕様変更は ask.sh だけで吸収する
- **沈黙が既定**: 文脈検知は 2 パターンだけ、提案は 1 行、実行はしない
- **決めるのは人間**: 表を出して終わる

## CLI 仕様の確認記録（変わりやすいので日付とバージョンを残す）

| 確認日 | 対象 | 使っている仕様 |
|---|---|---|
| 2026-09-16 | codex-cli 0.153.4 | `codex exec -`（stdin）、`--sandbox read-only`、`--ephemeral`、`-C`、`-o` |
| 2026-09-16 | Claude Code 2.1.252 | `claude -p`、`--disallowedTools`、`--permission-mode dontAsk`、`--output-format json`（`result` / `is_error`） |
| 2026-09-16 | 環境変数 | `CLAUDECODE=1`（Claude Code の子プロセス）、`CODEX_SANDBOX_NETWORK_DISABLED=1` / `CODEX_SANDBOX=seatbelt`（Codex の子プロセス、サンドボックス有効時のみ） |

ask.sh を触るときは、上の表の対象バージョンで `--help` を再確認して更新する。

## テスト方法

**スクリプト（自動）**

```bash
bash plugins/second-opinion/skills/ask/scripts/ask.test.sh
```

偽の codex / claude で終了コード 0/1/2/3/4/5/6 と引数を検証する。すべて `pass` で `failed=0` になること。

**スキル（手動）**

1. 設計判断の場面で `/second-opinion:ask` を呼び、Phase 0 のブリーフに自分の案が混ざっていないかを目視
2. 相違があるケースで Phase 3 の提案が 1 行で出る。相違が無いケースで出ない
3. 終了コード 2〜6 のそれぞれで案内文が正しく出る（偽 CLI を PATH に置いて再現できる）

**文脈検知（手動）**

4. 同じ箇所の修正が 2 回続いたセッションで提案が 1 行で出る
5. typo 修正だけのセッションで沈黙する

**実 CLI の疎通（費用が発生するので承認を取ってから）**

6. `ask.sh --brief <小さなブリーフ> --from claude` で rc=0、`git status` が変わらない
7. Codex セッション内で `/second-opinion:ask` を実行し、Claude 方向で rc=0
