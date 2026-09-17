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

need_val() {  # $1=フラグ名 $2=残り引数の数
  if [ "$2" -lt 2 ]; then echo "$1 に値がありません" >&2; usage; exit 1; fi
}

BRIEF=""; FROM=""; ROUND="independent"; OUT=""; TIMEOUT=600
while [ $# -gt 0 ]; do
  case "$1" in
    --brief)   need_val "$1" $#; BRIEF="$2"; shift 2 ;;
    --from)    need_val "$1" $#; FROM="$2"; shift 2 ;;
    --round)   need_val "$1" $#; ROUND="$2"; shift 2 ;;
    --out)     need_val "$1" $#; OUT="$2"; shift 2 ;;
    --timeout) need_val "$1" $#; TIMEOUT="$2"; shift 2 ;;
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

if [ "${CODEX_SANDBOX_NETWORK_DISABLED:-}" = "1" ]; then
  echo "注意: Codex サンドボックスがネットワークを遮断しています。失敗する場合はネットワーク許可（昇格）で再実行し、--from codex を付けてください" >&2
fi

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

ROLE='あなたは相談役です。リポジトリのファイルは読んでよいが、変更・作成・削除・コマンドによる副作用は行わない。以下のブリーフに対して、独立した見解を根拠付きで述べてください。'
if [ "$ROUND" = "critique" ]; then
  ROLE="$ROLE 提示された案の弱点を最低 3 つ、代替案を最低 1 つ挙げてください。"
fi
PROMPT_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-prompt.XXXXXX")
STDERR_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-stderr.XXXXXX")
# 回答はまず一時ファイルで受ける。$OUT（既定は <repo>/.context/second-opinion/ 配下）に
# 直接書くと、その保存先自体を無視していないリポジトリでは相手 CLI の実行前後で
# git status に自分の出力が差分として現れ、汚染検出が誤発火する。判定後に mv する。
OUT_TMP=$(mktemp "${TMPDIR:-/tmp}/second-opinion-answer.XXXXXX")
trap 'rm -f "$PROMPT_FILE" "$STDERR_FILE" "$OUT_TMP"' EXIT
{ printf '%s\n\n' "$ROLE"; cat "$BRIEF"; } > "$PROMPT_FILE"

# タイムアウト付き実行（macOS に timeout コマンドが無いため自前）
# 使い方: run_with_timeout <秒> <入力ファイル> <コマンド...>
# 背景実行は非対話 bash で stdin が /dev/null になりうるため、関数内で明示的にリダイレクトする
run_with_timeout() {
  local secs="$1" infile="$2"; shift 2
  local flag; flag=$(mktemp "${TMPDIR:-/tmp}/second-opinion-timeout.XXXXXX"); rm -f "$flag"
  "$@" < "$infile" &
  local pid=$!
  ( sleep "$secs" && { touch "$flag"; kill -TERM "$pid" 2>/dev/null; sleep 2; kill -KILL "$pid" 2>/dev/null; } ) &
  local wd=$!
  wait "$pid"; local rc=$?
  pkill -P "$wd" 2>/dev/null; kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
  if [ -f "$flag" ]; then rm -f "$flag"; return 124; fi
  return $rc
}

BEFORE=$(git -C "$REPO" status --short 2>/dev/null)

# 4. 相手 CLI の実行
case "$TARGET" in
  codex)
    run_with_timeout "$TIMEOUT" "$PROMPT_FILE" codex exec - --sandbox read-only --ephemeral -C "$REPO" -o "$OUT_TMP" \
      > /dev/null 2> "$STDERR_FILE"
    RC=$?
    ;;
  claude)
    JSON_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-json.XXXXXX")
    run_with_timeout "$TIMEOUT" "$PROMPT_FILE" claude -p --disallowedTools Edit,Write,NotebookEdit,Bash --permission-mode dontAsk --strict-mcp-config --output-format json \
      > "$JSON_FILE" 2> "$STDERR_FILE"
    RC=$?
    if [ "$RC" -eq 0 ]; then
      # result フィールドを取り出す。is_error が true なら失敗扱い。python3 が無ければ生 JSON を保存する
      if command -v python3 >/dev/null 2>&1; then
        python3 - "$JSON_FILE" "$OUT_TMP" <<'PY'
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
        if [ $? -ne 0 ]; then RC=1; fi
      else
        echo "python3 が無いため生の JSON を保存します" >&2
        cp "$JSON_FILE" "$OUT_TMP"
      fi
    fi
    if [ "$RC" -ne 0 ] && [ -s "$JSON_FILE" ]; then cat "$JSON_FILE" >> "$STDERR_FILE"; fi
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

if [ ! -s "$OUT_TMP" ]; then
  echo "$TARGET の回答が空でした" >&2
  tail -20 "$STDERR_FILE" >&2
  exit 1
fi

# 5. 作業ツリーの汚染検出（相手は読み取り専用のはず。差があれば警告して 3）
# 判定対象は相手 CLI の副作用だけにするため、$OUT への移動は判定の後に行う
AFTER=$(git -C "$REPO" status --short 2>/dev/null)
mkdir -p "$(dirname "$OUT")"
mv "$OUT_TMP" "$OUT" || { echo "回答の保存に失敗しました: $OUT" >&2; exit 1; }
echo "answer: $OUT" >&2
cat "$OUT"
if [ "$BEFORE" != "$AFTER" ]; then
  echo "警告: 相手 CLI の実行中に作業ツリーが変更されました。git status で確認してください" >&2
  diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") >&2
  exit 3
fi
exit 0
