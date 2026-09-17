#!/bin/bash
# ask.sh の回帰テスト。偽の codex / claude を PATH に置いて終了コードと出力を検証する。
# 実行: bash ask.test.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ASK="$HERE/ask.sh"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/ask-test.XXXXXX")
PASS=0; FAIL=0

# 偽 CLI: 引数を記録し、モードに応じて振る舞う
mkdir -p "$WORK/bin"
cat > "$WORK/bin/codex" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$FAKE_LOG"
case "${FAKE_MODE:-ok}" in
  auth) echo "Error: not logged in. Run codex login" >&2; exit 1;;
  hang) sleep 30; exit 0;;
  dirty) echo "contaminated" > "$FAKE_REPO/dirty.txt";;
  fail) echo "boom" >&2; exit 1;;
esac
OUT=""; while [ $# -gt 0 ]; do [ "$1" = "-o" ] && OUT="$2"; shift; done
{ echo "fake codex answer"; echo "--- prompt received ---"; cat; } > "$OUT"
EOF
cat > "$WORK/bin/claude" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$FAKE_LOG"
case "${FAKE_MODE:-ok}" in
  auth) echo '{"type":"result","is_error":true,"result":"Not logged in. Please run /login"}'; exit 0;;
  hang) sleep 30; exit 0;;
  dirty) echo "contaminated" > "$FAKE_REPO/dirty.txt";;
  fail) echo "boom" >&2; exit 1;;
esac
PROMPT=$(cat | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')
echo "{\"type\":\"result\",\"is_error\":false,\"result\":\"fake claude answer\",\"prompt_echo\":$PROMPT}"
EOF
chmod +x "$WORK/bin/codex" "$WORK/bin/claude"

# 偽リポジトリ
export FAKE_REPO="$WORK/repo"
mkdir -p "$FAKE_REPO" && (cd "$FAKE_REPO" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init)
printf '## 問い\nどちらの設計が良いか "引用符" と日本語を含む\n' > "$WORK/brief.md"

# run_case NAME EXPECTED_RC "ENV=1 ENV2=x" ARGS...
run_case() {
  local name="$1" expected="$2" envs="$3"; shift 3
  export FAKE_LOG="$WORK/$name.log"
  local rc
  ( cd "$FAKE_REPO" && env -i HOME="$HOME" PATH="$WORK/bin:/usr/bin:/bin" TMPDIR="$WORK" FAKE_REPO="$FAKE_REPO" FAKE_LOG="$FAKE_LOG" $envs bash "$ASK" "$@" > "$WORK/$name.out" 2> "$WORK/$name.err" )
  rc=$?
  if [ "$rc" = "$expected" ]; then PASS=$((PASS+1)); echo "pass  $name (rc=$rc)"
  else FAIL=$((FAIL+1)); echo "FAIL  $name: expected rc=$expected got rc=$rc"; sed 's/^/      /' "$WORK/$name.err"; fi
}

assert_file_contains() {  # NAME FILE PATTERN
  if grep -q -- "$3" "$2"; then PASS=$((PASS+1)); echo "pass  $1"
  else FAIL=$((FAIL+1)); echo "FAIL  $1: '$3' not in $2"; fi
}

# --- ケース ---
run_case no-brief 1 "" --from claude
run_case bad-round 1 "" --brief "$WORK/brief.md" --from claude --round wrong
run_case undetectable 2 "" --brief "$WORK/brief.md"
run_case detect-claude 0 "CLAUDECODE=1" --brief "$WORK/brief.md"
assert_file_contains detect-claude-target "$WORK/detect-claude.err" "target=codex"
run_case detect-codex-net 0 "CODEX_SANDBOX_NETWORK_DISABLED=1" --brief "$WORK/brief.md"
assert_file_contains detect-codex-net-target "$WORK/detect-codex-net.err" "target=claude"
run_case detect-codex-seatbelt 0 "CODEX_SANDBOX=seatbelt" --brief "$WORK/brief.md"
run_case explicit-wins 0 "CLAUDECODE=1" --brief "$WORK/brief.md" --from codex
assert_file_contains explicit-wins-target "$WORK/explicit-wins.err" "target=claude"
# CLI 不在: PATH から偽 CLI を外す
chmod -x "$WORK/bin/codex"
run_case cli-missing 4 "CLAUDECODE=1" --brief "$WORK/brief.md"
chmod +x "$WORK/bin/codex"

run_case codex-ok 0 "CLAUDECODE=1" --brief "$WORK/brief.md" --out "$WORK/codex-ok.answer.md"
assert_file_contains codex-ok-answer "$WORK/codex-ok.answer.md" "fake codex answer"
assert_file_contains codex-ok-stdout "$WORK/codex-ok.out" "fake codex answer"
assert_file_contains codex-ok-role "$WORK/codex-ok.answer.md" "あなたは相談役です"
assert_file_contains codex-ok-brief "$WORK/codex-ok.answer.md" '"引用符"'
assert_file_contains codex-ok-sandbox "$WORK/codex-ok.log" "read-only"
assert_file_contains codex-ok-ephemeral "$WORK/codex-ok.log" "ephemeral"
assert_file_contains codex-ok-cd "$WORK/codex-ok.log" "$FAKE_REPO"
run_case codex-critique 0 "CLAUDECODE=1" --brief "$WORK/brief.md" --round critique --out "$WORK/codex-critique.answer.md"
assert_file_contains codex-critique-role "$WORK/codex-critique.answer.md" "弱点を最低 3 つ"
run_case codex-default-out 0 "CLAUDECODE=1" --brief "$WORK/brief.md"
assert_file_contains codex-default-out-path "$WORK/codex-default-out.err" "\.context/second-opinion/answer-"

run_case claude-ok 0 "CODEX_SANDBOX_NETWORK_DISABLED=1" --brief "$WORK/brief.md" --out "$WORK/claude-ok.answer.md"
assert_file_contains claude-ok-answer "$WORK/claude-ok.answer.md" "fake claude answer"
assert_file_contains claude-ok-disallow "$WORK/claude-ok.log" "Edit,Write,Bash"
assert_file_contains claude-ok-dontask "$WORK/claude-ok.log" "dontAsk"
assert_file_contains claude-ok-json "$WORK/claude-ok.log" "json"
if grep -q -- "--bare" "$WORK/claude-ok.log"; then FAIL=$((FAIL+1)); echo "FAIL  claude-ok-nobare: --bare must not be used"; else PASS=$((PASS+1)); echo "pass  claude-ok-nobare"; fi
run_case codex-auth 5 "CLAUDECODE=1 FAKE_MODE=auth" --brief "$WORK/brief.md" --out "$WORK/codex-auth.answer.md"
run_case claude-auth 5 "CODEX_SANDBOX_NETWORK_DISABLED=1 FAKE_MODE=auth" --brief "$WORK/brief.md" --out "$WORK/claude-auth.answer.md"
run_case codex-timeout 6 "CLAUDECODE=1 FAKE_MODE=hang" --brief "$WORK/brief.md" --timeout 2 --out "$WORK/codex-timeout.answer.md"
run_case codex-fail 1 "CLAUDECODE=1 FAKE_MODE=fail" --brief "$WORK/brief.md" --out "$WORK/codex-fail.answer.md"
assert_file_contains codex-fail-stderr "$WORK/codex-fail.err" "boom"

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
