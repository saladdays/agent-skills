#!/bin/bash
# second-opinion: 相手モデルの CLI を読み取り専用で呼び出し、回答をファイルに保存する。
# ブリーフの中身は解釈しない。判断はすべて SKILL.md 側。
# script-version: 1
set -u

usage() {
  cat >&2 <<'EOF'
Usage: ask.sh --brief <path> [--from claude|codex] [--round independent|critique] [--out <path>] [--timeout <sec>]
  --from     呼び出し元。claude = Claude Code から Codex へ聞く / codex = Codex から Claude へ聞く
             省略時は環境変数（CLAUDECODE / CODEX_SANDBOX*）から判定する
  --round    independent（既定）= 独立回答 / critique = 自分の案の弱点を突かせる
  --out      回答の保存先。既定は <repo>/.context/second-opinion/answer-<timestamp>.md
  --timeout  秒。既定 600
Exit codes: 0 成功 / 1 その他 / 2 判定不能 / 3 作業ツリー変更 / 4 CLI 不在 / 5 認証エラー / 6 タイムアウト
EOF
}

BRIEF=""; FROM=""; ROUND="independent"; OUT=""; TIMEOUT=600
while [ $# -gt 0 ]; do
  case "$1" in
    --brief)   BRIEF="${2:-}"; shift 2 ;;
    --from)    FROM="${2:-}"; shift 2 ;;
    --round)   ROUND="${2:-}"; shift 2 ;;
    --out)     OUT="${2:-}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$BRIEF" ] || [ ! -f "$BRIEF" ]; then
  echo "ブリーフが見つかりません: '${BRIEF}'" >&2; usage; exit 1
fi
case "$ROUND" in independent|critique) ;; *) echo "--round は independent か critique: '$ROUND'" >&2; exit 1 ;; esac
case "$TIMEOUT" in ''|*[!0-9]*) echo "--timeout は秒数（整数）: '$TIMEOUT'" >&2; exit 1 ;; esac

# 1. 呼び出し元の判定（--from → Claude Code の環境変数 → Codex の環境変数 → 判定不能）
if [ -z "$FROM" ]; then
  if [ "${CLAUDECODE:-}" = "1" ]; then
    FROM=claude
  elif [ "${CODEX_SANDBOX_NETWORK_DISABLED:-}" = "1" ] || [ "${CODEX_SANDBOX:-}" = "seatbelt" ]; then
    FROM=codex
  else
    echo "実行環境を判定できません。--from claude|codex を指定してください" >&2
    exit 2
  fi
fi
case "$FROM" in
  claude) TARGET=codex ;;
  codex)  TARGET=claude ;;
  *) echo "--from は claude か codex: '$FROM'" >&2; exit 1 ;;
esac

# 2. 相手 CLI の存在確認（実行権限の無いファイルは「見つからない」扱い）
TARGET_BIN=$(command -v "$TARGET" 2>/dev/null)
if [ -z "$TARGET_BIN" ] || [ ! -x "$TARGET_BIN" ]; then
  echo "$TARGET CLI が見つかりません（PATH に無いか実行できない）" >&2
  exit 4
fi

echo "from=$FROM target=$TARGET round=$ROUND" >&2
exit 0
