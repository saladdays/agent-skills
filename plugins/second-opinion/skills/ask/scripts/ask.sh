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

# 3. 保存先とプロンプト
REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
if [ -z "$OUT" ]; then
  OUT="$REPO/.context/second-opinion/answer-$STAMP.md"
fi
mkdir -p "$(dirname "$OUT")"

ROLE='あなたは相談役です。リポジトリのファイルは読んでよいが、変更・作成・削除・コマンドによる副作用は行わない。以下のブリーフに対して、独立した見解を根拠付きで述べてください。'
if [ "$ROUND" = "critique" ]; then
  ROLE="$ROLE 提示された案の弱点を最低 3 つ、代替案を最低 1 つ挙げてください。"
fi
PROMPT_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-prompt.XXXXXX")
STDERR_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-stderr.XXXXXX")
trap 'rm -f "$PROMPT_FILE" "$STDERR_FILE"' EXIT
{ printf '%s\n\n' "$ROLE"; cat "$BRIEF"; } > "$PROMPT_FILE"

# タイムアウト付き実行（macOS に timeout コマンドが無いため自前）
# 使い方: run_with_timeout <秒> <入力ファイル> <コマンド...>
# 背景実行は非対話 bash で stdin が /dev/null になりうるため、関数内で明示的にリダイレクトする
run_with_timeout() {
  local secs="$1" infile="$2"; shift 2
  local flag; flag=$(mktemp "${TMPDIR:-/tmp}/second-opinion-timeout.XXXXXX"); rm -f "$flag"
  "$@" < "$infile" &
  local pid=$!
  ( sleep "$secs"; touch "$flag"; kill -TERM "$pid" 2>/dev/null ) &
  local wd=$!
  wait "$pid"; local rc=$?
  kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
  if [ -f "$flag" ]; then rm -f "$flag"; return 124; fi
  return $rc
}

# 4. 相手 CLI の実行
case "$TARGET" in
  codex)
    run_with_timeout "$TIMEOUT" "$PROMPT_FILE" codex exec - --sandbox read-only --ephemeral -C "$REPO" -o "$OUT" \
      > /dev/null 2> "$STDERR_FILE"
    RC=$?
    ;;
  claude)
    JSON_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-json.XXXXXX")
    run_with_timeout "$TIMEOUT" "$PROMPT_FILE" claude -p --disallowedTools Edit,Write,Bash --permission-mode dontAsk --output-format json \
      > "$JSON_FILE" 2> "$STDERR_FILE"
    RC=$?
    if [ "$RC" -eq 0 ]; then
      # result フィールドを取り出す。is_error が true なら失敗扱い。python3 が無ければ生 JSON を保存する
      if command -v python3 >/dev/null 2>&1; then
        python3 - "$JSON_FILE" "$OUT" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(src))
except Exception as e:
    sys.stderr.write(f"claude の出力が JSON として読めません: {e}\n"); sys.exit(1)
if d.get("is_error"):
    sys.stderr.write(str(d.get("result", "")) + "\n"); sys.exit(1)
open(dst, "w").write(str(d.get("result", "")))
PY
        if [ $? -ne 0 ]; then RC=1; cat "$JSON_FILE" >> "$STDERR_FILE"; fi
      else
        echo "python3 が無いため生の JSON を保存します" >&2
        cp "$JSON_FILE" "$OUT"
      fi
    fi
    rm -f "$JSON_FILE"
    ;;
esac

if [ "$RC" -eq 124 ]; then
  echo "$TARGET が ${TIMEOUT} 秒以内に応答しませんでした。ブリーフを小さくするか --timeout を延ばしてください" >&2
  exit 6
fi
if [ "$RC" -ne 0 ]; then
  if grep -qiE 'not logged in|unauthorized|401|invalid api key|authentication|please run /login|codex login' "$STDERR_FILE"; then
    echo "$TARGET の認証エラーです。$TARGET でログインしてから再実行してください" >&2
    tail -5 "$STDERR_FILE" >&2
    exit 5
  fi
  echo "$TARGET の実行に失敗しました (rc=$RC)" >&2
  tail -20 "$STDERR_FILE" >&2
  exit 1
fi

echo "answer: $OUT" >&2
cat "$OUT"
exit 0
