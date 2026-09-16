# second-opinion プラグイン 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 実装前の設計判断や行き詰まりの場面で、別系統モデル（Claude Code ⇄ Codex CLI）に問題だけを渡して独立に解かせ、自分の案と突き合わせるプラグインを作る。

**Architecture:** 判断はすべて `skills/ask/SKILL.md` に書き、機械的な呼び出しだけを `skills/ask/scripts/ask.sh` に切り出す。スクリプトは呼び出し元を判定し、相手 CLI を読み取り専用で起動し、回答をファイルに保存し、作業ツリーの汚染を検出する。ブリーフの中身は解釈しない。

**Tech Stack:** bash（macOS / Linux 両対応、外部依存なし。JSON 抽出のみ python3 を使い、無ければ生 JSON を保存）、codex-cli 0.153.4、Claude Code 2.1.252、Markdown（SKILL.md / references）。

**Spec:** `docs/superpowers/specs/2026-09-16-second-opinion-design.md`

## Global Constraints

- プラグイン名 `second-opinion`、スキル名 `ask`、呼び出し `/second-opinion:ask [議題]`
- `plugin.json` は `.claude-plugin/` と `.cursor-plugin/` の両方に同一内容で置く。`marketplace.json` も両方に登録する
- README は日本語 `README.md` と英語 `README.en.md` を両方作り、冒頭に言語スイッチャーを置く（ルート CLAUDE.md の必須手順）
- SKILL.md は判断と手順だけ。CLI のフラグや環境変数名を SKILL.md に書かない（ask.sh の責務）
- Codex への呼び出しは `codex exec - --sandbox read-only --ephemeral -C <repo root> -o <out>`
- Claude への呼び出しは `claude -p --disallowedTools Edit,Write,Bash --permission-mode dontAsk --output-format json`。`--bare` は使わない
- 呼び出し元の判定順: `--from` → `CLAUDECODE=1` → `CODEX_SANDBOX_NETWORK_DISABLED=1` または `CODEX_SANDBOX=seatbelt` → 終了コード 2
- 終了コード: 0 成功 / 1 その他 / 2 判定不能 / 3 作業ツリー変更 / 4 CLI 不在 / 5 認証エラー / 6 タイムアウト（既定 600 秒）
- 保存先は `.context/second-opinion/`（`.gitignore` 済み）
- コミットメッセージは `type(second-opinion): 説明` で「なぜ」を書き、末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`
- テストスクリプトは `skills/ask/scripts/ask.test.sh` としてコミットする（仕様 §10 の `tests/` は実行時の一時成果物にのみ使う。理由: スクリプトのテストは回帰検出に使うためリポジトリに残す）

## ファイル構成

| ファイル | 責務 | 作るタスク |
|---|---|---|
| `plugins/second-opinion/.claude-plugin/plugin.json` | Claude Code 向けメタデータ | 1 |
| `plugins/second-opinion/.cursor-plugin/plugin.json` | Cursor 向けメタデータ（同一内容） | 1 |
| `.claude-plugin/marketplace.json` / `.cursor-plugin/marketplace.json` | マーケットプレイス登録 | 1 |
| `plugins/second-opinion/skills/ask/scripts/ask.sh` | 相手 CLI の呼び出し。判定・実行・保存・汚染検出・終了コード | 2〜5 |
| `plugins/second-opinion/skills/ask/scripts/ask.test.sh` | 偽 CLI を使った ask.sh の回帰テスト | 2〜5 |
| `plugins/second-opinion/skills/ask/references/brief-format.md` | ブリーフの書式と「渡す/渡さない」 | 6 |
| `plugins/second-opinion/skills/ask/references/output-format.md` | 突き合わせ表の書式 | 6 |
| `plugins/second-opinion/skills/ask/references/trigger-rules.md` | 文脈検知の条件 | 6 |
| `plugins/second-opinion/skills/ask/SKILL.md` | 4 フェーズの手順、終了コードの案内文、自己検証 | 7 |
| `plugins/second-opinion/CLAUDE.md` | 開発ルール、テスト方法、CLI 仕様の確認日 | 8 |
| `plugins/second-opinion/README.md` / `README.en.md` | 利用者向け | 8 |
| ルート `README.md` / `README.en.md` / `CLAUDE.md` | プラグイン一覧に追加 | 8 |

---

### Task 1: プラグインの骨組みとマーケットプレイス登録

**Files:**
- Create: `plugins/second-opinion/.claude-plugin/plugin.json`
- Create: `plugins/second-opinion/.cursor-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`（`plugins` 配列の末尾）
- Modify: `.cursor-plugin/marketplace.json`（`plugins` 配列の末尾）

**Interfaces:**
- Produces: プラグイン名 `second-opinion`、`skills` パス `./skills/`。後続タスクはこの配下に置く

- [ ] **Step 1: plugin.json を 2 箇所に作る**

`plugins/second-opinion/.claude-plugin/plugin.json` と `plugins/second-opinion/.cursor-plugin/plugin.json` に同じ内容を書く:

```json
{
  "name": "second-opinion",
  "description": "別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせる。単一モデルの偏りを自覚した上で判断できる。",
  "version": "1.0.0",
  "author": {
    "name": "saladdays"
  },
  "license": "MIT",
  "skills": "./skills/"
}
```

- [ ] **Step 2: マーケットプレイスに登録する**

`.claude-plugin/marketplace.json` の `plugins` 配列末尾（context-handoff の後）に追加:

```json
    {
      "name": "second-opinion",
      "source": "./plugins/second-opinion",
      "description": "別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせる",
      "version": "1.0.0",
      "author": {
        "name": "saladdays"
      },
      "license": "MIT",
      "keywords": ["second-opinion", "cross-model", "bias", "review", "codex", "claude-code"],
      "category": "review"
    }
```

`.cursor-plugin/marketplace.json` の `plugins` 配列末尾に追加:

```json
    {
      "name": "second-opinion",
      "source": "plugins/second-opinion",
      "description": "別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせる。単一モデルの偏りを自覚した上で判断できる。"
    }
```

他プラグインにある `logo` は初版では付けない（画像が無い状態でパスを書くと Cursor 側の検証に落ちる可能性があるため。Cursor 公開時に `assets/logo.png` と一緒に追加する）。

- [ ] **Step 3: JSON が壊れていないことを確認する**

Run:
```bash
python3 -c "import json;[json.load(open(f)) for f in ['.claude-plugin/marketplace.json','.cursor-plugin/marketplace.json','plugins/second-opinion/.claude-plugin/plugin.json','plugins/second-opinion/.cursor-plugin/plugin.json']];print('json ok')"
```
Expected: `json ok`

- [ ] **Step 4: コミット**

```bash
git add plugins/second-opinion/.claude-plugin/plugin.json plugins/second-opinion/.cursor-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/marketplace.json
git commit -m "feat(second-opinion): プラグインの骨組みとマーケットプレイス登録を追加

別系統モデルに独立した見解を求めるプラグインの土台。以降のタスクで
スクリプト・スキル・ドキュメントを積む。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: ask.sh の引数解析と呼び出し元の判定

**Files:**
- Create: `plugins/second-opinion/skills/ask/scripts/ask.sh`
- Create: `plugins/second-opinion/skills/ask/scripts/ask.test.sh`

**Interfaces:**
- Produces: `ask.sh --brief <path> [--from claude|codex] [--round independent|critique] [--out <path>] [--timeout <sec>]`。終了コード 1（引数不正）、2（判定不能）、4（CLI 不在）
- Produces（テスト側）: `ask.test.sh` の関数 `run_case NAME EXPECTED_RC ENV_STRING ARGS...` と偽 CLI 置き場 `$WORK/bin`

- [ ] **Step 1: テストの土台と最初の 3 ケースを書く**

`plugins/second-opinion/skills/ask/scripts/ask.test.sh`:

```bash
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

echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: 3 件とも `FAIL`（ask.sh が存在しないため rc=127）

- [ ] **Step 3: ask.sh の引数解析と判定を書く**

`plugins/second-opinion/skills/ask/scripts/ask.sh`:

```bash
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

# 2. 相手 CLI の存在確認
if ! command -v "$TARGET" >/dev/null 2>&1; then
  echo "$TARGET CLI が見つかりません（PATH に無い）" >&2
  exit 4
fi

echo "from=$FROM target=$TARGET round=$ROUND" >&2
exit 0
```

`chmod +x plugins/second-opinion/skills/ask/scripts/ask.sh`

- [ ] **Step 4: テストに判定と CLI 不在のケースを足して実行する**

`ask.test.sh` の `# --- ケース ---` の後に追加:

```bash
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
```

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `passed=11 failed=0`（この時点では呼び出し前に exit 0 しているため detect 系が通る）

- [ ] **Step 5: コミット**

```bash
git add plugins/second-opinion/skills/ask/scripts/ask.sh plugins/second-opinion/skills/ask/scripts/ask.test.sh
git commit -m "feat(second-opinion): ask.sh の引数解析と呼び出し元判定を追加

--from 明示を最優先にし、環境変数は補助にする。Codex はサンドボックス
無効時に環境変数を設定しないため、判定不能は推測せず終了コード 2 で
人間に返す。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Codex への呼び出しと回答の保存

**Files:**
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.sh`（末尾の `echo ... exit 0` を置き換える）
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.test.sh`

**Interfaces:**
- Consumes: Task 2 の `FROM` / `TARGET` / `ROUND` / `OUT` / `TIMEOUT`
- Produces: 関数 `run_with_timeout SECS CMD...`（stdin は呼び出し側が明示リダイレクト）、変数 `REPO`、`PROMPT_FILE`、`STDERR_FILE`。成功時は `$OUT` に回答、stdout に回答全文、stderr に `answer: <path>`

- [ ] **Step 1: テストを書く（Codex 方向の成功と引数）**

`ask.test.sh` の `# CLI 不在` ブロックの後に追加:

```bash
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
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `codex-ok-answer` 以降が FAIL（回答ファイルが作られない）

- [ ] **Step 3: 呼び出しを実装する**

`ask.sh` の末尾の `exit 0` を次に置き換える（`echo "from=$FROM target=$TARGET round=$ROUND" >&2` の行はテストが参照するので残す）:

```bash
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

# タイムアウト付き実行（macOS に timeout コマンドが無いため自前）。stdin は呼び出し側で明示する
run_with_timeout() {
  local secs="$1"; shift
  local flag; flag=$(mktemp "${TMPDIR:-/tmp}/second-opinion-timeout.XXXXXX"); rm -f "$flag"
  "$@" &
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
    run_with_timeout "$TIMEOUT" codex exec - --sandbox read-only --ephemeral -C "$REPO" -o "$OUT" \
      < "$PROMPT_FILE" > /dev/null 2> "$STDERR_FILE"
    RC=$?
    ;;
  claude)
    echo "claude 方向は未実装" >&2; exit 1
    ;;
esac

if [ "$RC" -ne 0 ]; then
  echo "$TARGET の実行に失敗しました (rc=$RC)" >&2
  tail -20 "$STDERR_FILE" >&2
  exit 1
fi

echo "answer: $OUT" >&2
cat "$OUT"
exit 0
```

- [ ] **Step 4: テストを実行して通す**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: Task 3 で足したケースはすべて `pass`。`failed=3` で、落ちるのは Claude 方向を通る `detect-codex-net`、`detect-codex-seatbelt`、`explicit-wins` の 3 件だけ（「claude 方向は未実装」で rc=1。Task 4 で通る）。`codex-default-out` は偽リポジトリ内に `.context/second-opinion/` が作られる

- [ ] **Step 5: コミット**

```bash
git add plugins/second-opinion/skills/ask/scripts/ask.sh plugins/second-opinion/skills/ask/scripts/ask.test.sh
git commit -m "feat(second-opinion): Codex への読み取り専用呼び出しと回答保存を追加

役割節は固定文でスクリプトが足し、ブリーフ本文には触れない。
macOS に timeout が無いため自前のタイムアウトを持つ。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Claude への呼び出し、認証エラー、タイムアウト

**Files:**
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.sh`（`case "$TARGET"` の `claude)` 分岐と、失敗時の分岐）
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.test.sh`

**Interfaces:**
- Consumes: Task 3 の `run_with_timeout`、`PROMPT_FILE`、`STDERR_FILE`、`OUT`
- Produces: 終了コード 5（認証）、6（タイムアウト）。Claude 方向は JSON の `result` を `$OUT` に保存

- [ ] **Step 1: テストを書く**

`ask.test.sh` の Task 3 のケースの後に追加:

```bash
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
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `claude-ok` が rc=1（未実装）、`codex-auth` が rc=1（5 でない）、`codex-timeout` が rc=1 で FAIL

- [ ] **Step 3: 実装する**

`ask.sh` の `claude)` 分岐を置き換える:

```bash
  claude)
    JSON_FILE=$(mktemp "${TMPDIR:-/tmp}/second-opinion-json.XXXXXX")
    run_with_timeout "$TIMEOUT" claude -p --disallowedTools Edit,Write,Bash --permission-mode dontAsk --output-format json \
      < "$PROMPT_FILE" > "$JSON_FILE" 2> "$STDERR_FILE"
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
```

`if [ "$RC" -ne 0 ]; then ... exit 1; fi` ブロックを次に置き換える:

```bash
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
```

- [ ] **Step 4: テストを実行して通す**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `failed=0`。`codex-timeout` は約 2 秒で返る

- [ ] **Step 5: コミット**

```bash
git add plugins/second-opinion/skills/ask/scripts/ask.sh plugins/second-opinion/skills/ask/scripts/ask.test.sh
git commit -m "feat(second-opinion): Claude への呼び出しと認証・タイムアウトの終了コードを追加

Claude 側は --bare を使わない。OAuth を読まず API キー必須になり、
API キーをグローバルに置かない運用と衝突するため。認証切れと
タイムアウトは SKILL.md が案内文を出し分けられるよう別コードにする。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: 作業ツリー汚染の検出

**Files:**
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.sh`（実行前後の `git status` 比較）
- Modify: `plugins/second-opinion/skills/ask/scripts/ask.test.sh`

**Interfaces:**
- Consumes: Task 3 の `REPO`、`OUT`
- Produces: 終了コード 3（回答は保存済み、stdout にも出す）

- [ ] **Step 1: テストを書く**

`ask.test.sh` の Task 4 のケースの後に追加:

```bash
run_case codex-dirty 3 "CLAUDECODE=1 FAKE_MODE=dirty" --brief "$WORK/brief.md" --out "$WORK/codex-dirty.answer.md"
assert_file_contains codex-dirty-warn "$WORK/codex-dirty.err" "作業ツリー"
assert_file_contains codex-dirty-answer-kept "$WORK/codex-dirty.answer.md" "fake codex answer"
rm -f "$FAKE_REPO/dirty.txt"
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `codex-dirty` が rc=0 で FAIL

- [ ] **Step 3: 実装する**

`ask.sh` の `# 4. 相手 CLI の実行` の直前に追加:

```bash
BEFORE=$(git -C "$REPO" status --short 2>/dev/null)
```

末尾の `echo "answer: $OUT" >&2; cat "$OUT"; exit 0` を次に置き換える:

```bash
# 5. 作業ツリーの汚染検出（相手は読み取り専用のはず。差があれば警告して 3）
AFTER=$(git -C "$REPO" status --short 2>/dev/null)
echo "answer: $OUT" >&2
cat "$OUT"
if [ "$BEFORE" != "$AFTER" ]; then
  echo "警告: 相手 CLI の実行中に作業ツリーが変更されました。git status で確認してください" >&2
  diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") >&2
  exit 3
fi
exit 0
```

- [ ] **Step 4: テストを実行して通す**

Run: `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh`
Expected: `failed=0`

- [ ] **Step 5: 実際の CLI で片方向だけ疎通確認する（人間の承認後）**

このステップは外部モデルの費用が発生するため、実行前にユーザーに確認する。承認されたら:

```bash
cd /Users/uno/Developer/agent-skills
printf '## 問い\nこのリポジトリの README.md の冒頭 3 行を読み、1 文で要約してください。\n\n## 関連ファイル\nREADME.md\n' > "$TMPDIR/smoke-brief.md"
bash plugins/second-opinion/skills/ask/scripts/ask.sh --brief "$TMPDIR/smoke-brief.md" --from claude --timeout 180
echo "rc=$?"
```

Expected: `rc=0`、stderr に `answer: .../.context/second-opinion/answer-...md`、stdout に Codex の要約。`git status --short` が空のまま。
Codex → Claude 方向は Codex セッション内でしか環境が揃わないため、ここでは `--from codex` を手動指定して同様に実行し、`rc=0` を確認する。

- [ ] **Step 6: コミット**

```bash
git add plugins/second-opinion/skills/ask/scripts/ask.sh plugins/second-opinion/skills/ask/scripts/ask.test.sh
git commit -m "feat(second-opinion): 相手 CLI 実行後の作業ツリー汚染を検出する

読み取り専用で呼んでいても CLI 側の設定や不具合で書き込まれる可能性が
あるため、実行前後の git status を比較して差があれば終了コード 3 で
警告する。回答は捨てない。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: 参照ファイル（ブリーフ書式・出力書式・文脈検知）

**Files:**
- Create: `plugins/second-opinion/skills/ask/references/brief-format.md`
- Create: `plugins/second-opinion/skills/ask/references/output-format.md`
- Create: `plugins/second-opinion/skills/ask/references/trigger-rules.md`

**Interfaces:**
- Produces: SKILL.md（Task 7）が参照する 3 ファイル。ブリーフの節名は `## 問い` `## 制約` `## 成功条件` `## 起きた事実` `## 関連ファイル` `## 私たちの案`

- [ ] **Step 1: brief-format.md を書く**

```markdown
# ブリーフの書式

相手モデルに渡す唯一の入力。**問題は渡す、自分の答えは渡さない。**

## テンプレート

```markdown
# Second Opinion Brief

## 問い
（1〜2 文。何を決めたいか、何が分からないか）

## 制約
（技術・期限・既存資産・変えられないもの。事実のみ）

## 成功条件
（何が満たされれば良い判断と言えるか。判断の物差し）

## 起きた事実
（行き詰まりの場合のみ。エラー出力の原文、試した操作とその結果。時系列で）

## 関連ファイル
（パスの列挙。相手が自分で読む。1 行に 1 パス、必要なら行番号）

## 私たちの案
（critique ラウンドのみ。案と、その理由）
```

## 渡すもの / 渡さないもの

| 渡す | 渡さない |
|---|---|
| 問い、制約、成功条件 | 自分の案、推している選択肢 |
| エラー出力の原文 | 「原因はこれだと思う」という解釈 |
| 試した操作と、その結果（事実） | 試した理由の説明（仮説が混ざる） |
| 関連ファイルのパス | 会話の要約、これまでの経緯 |

**線引きの原理:** 相手が同じ事実から自分で推論できる状態にする。こちらの推論を渡すと相手はそれに追従し、独立性が消える。

## 自己検証（independent ラウンドでブリーフを書き終えたら）

- [ ] 「私たちの案」節が無い
- [ ] 「〜だと思う」「〜のはず」「おそらく」が本文に無い
- [ ] 選択肢を列挙している場合、順序や修飾で優劣を示していない
- [ ] 起きた事実に「なぜ」の説明が混ざっていない
- [ ] 関連ファイルはパスだけで、内容の解説を付けていない

1 つでも該当したら書き直してから Phase 1 に進む。

## critique ラウンドの追加ルール

「私たちの案」節を足す。案は事実として書き、擁護しない。相手への要求（弱点 3 つ以上、代替案 1 つ以上）はスクリプトが役割節で足すのでブリーフには書かない。
```

- [ ] **Step 2: output-format.md を書く**

```markdown
# 突き合わせ表の書式

Phase 2 の出力。**相手の原文を必ず全文残し、一致を検証済み扱いしない。**

## テンプレート

```markdown
## セカンドオピニオン: <議題を 1 行で>

- 自分: <モデル名 / ツール名>
- 相手: <モデル名 / ツール名>
- ブリーフ: <.context/second-opinion/brief-....md>
- 回答: <.context/second-opinion/answer-....md>

| 論点 | 自分 | 相手 | 一致/相違 | 根拠を事実に遡れるか |
|---|---|---|---|---|
| <論点 1> | <自分の見解を 1 文> | <相手の見解を 1 文> | 一致 / 相違 | 両者: <コード・仕様・計測のどれか> / 自分のみ / 相手のみ / どちらも推測 |

### 相違点の理由
- <論点 N>: <なぜ結論が分かれたか。前提の違い、重視した制約の違いなど。自分の側に寄せない>

### 相手の原文
<answer ファイルの全文。省略・要約・言い換えをしない>

---
どちらを採るかは人間が決める。
一致は「両者が同じ結論」であって「検証済み」ではない。
```

## 書き方のルール

- 論点は相手の回答に出てきたものを先に立て、自分だけが持っている論点を後に足す（相手の視点を落とさないため）
- 「自分」列は Phase 0 の時点で持っていた案。相手を見て変えない
- 相違の理由で「相手は文脈を知らないから」で片付けない。文脈不足なら「ブリーフに〜が欠けていた」と書く
- 「根拠を事実に遡れるか」は、その結論がコード・仕様・計測のどれに基づくかを書く。どちらも推測なら両方とも推測と書く
- 表の下の定型 2 行は削らない

## critique ラウンドの追記

同じファイルに次を追記する:

```markdown
### 批判ラウンド
| 指摘された弱点 | 妥当か | 対応 |
|---|---|---|
| <弱点 1> | 妥当 / 一部妥当 / 前提が違う | <直す / 受け入れる / 却下と理由> |

代替案: <相手の代替案を 1〜2 文>。<採用 / 不採用と理由>
```
```

- [ ] **Step 3: trigger-rules.md を書く**

```markdown
# 文脈検知で提案する条件

「画面の後ろの先輩」型。黙っているのが既定で、次の 2 パターンだけ口を開く。**実行はしない。提案だけ。**

## 発話するパターン

1. **設計判断の直前**: 方針・ライブラリ・アーキテクチャ・データ構造を決めようとしている発言があり、まだ実装（ファイル編集）に入っていない
   - 例: 「A と B どっちにしようか」「〜で行こうと思う」「〜を採用する」
2. **行き詰まり**: 同じ箇所への修正が 2 回続いて解決していない
   - 例: 同じファイルの同じ関数を 2 回直してもテストが落ちる、同じエラーが 2 回出る

## 発話の形

1 行、問いの形、1 観点のみ。

- 「この判断、別モデルの独立した見解も聞いておきますか？（/second-opinion:ask）」
- 「同じ箇所で 2 回止まっています。見立て自体を別モデルに聞いてみますか？（/second-opinion:ask）」

## 発話しない条件

- typo 修正、lint 修正、フォーマット変更
- 既に決まった方針の範囲内での実装作業
- テスト実行、ビルド、デプロイ
- ユーザーが既に「別モデルに聞く」と言っている、または直前に断っている
- 同じセッションで同じパターンの提案を一度断られた後（以後そのパターンでは再提案しない）

## 誤作動を防ぐために

- 「決めようとしている」の判定は、ユーザーの発言に選択・採用・方針の語があることを条件にする。AI 自身が内部で選んでいるだけの場面では発話しない
- 「2 回続いた」は同一セッション内で数える。前セッションの回数は引き継がない
```

- [ ] **Step 4: 3 ファイルが存在し、節名がテンプレートと一致することを確認する**

Run:
```bash
grep -c "^## " plugins/second-opinion/skills/ask/references/brief-format.md
grep -n "## 問い\|## 制約\|## 成功条件\|## 起きた事実\|## 関連ファイル\|## 私たちの案" plugins/second-opinion/skills/ask/references/brief-format.md | wc -l
```
Expected: 2 行目が `6`

- [ ] **Step 5: コミット**

```bash
git add plugins/second-opinion/skills/ask/references/
git commit -m "docs(second-opinion): ブリーフ・突き合わせ表・文脈検知の参照ファイルを追加

独立性を守る線引き（自分の案を渡さない）、一致を検証済み扱いしない
定型行、沈黙を既定にする発話条件を SKILL.md から分離して自己完結させる。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: SKILL.md

**Files:**
- Create: `plugins/second-opinion/skills/ask/SKILL.md`

**Interfaces:**
- Consumes: `scripts/ask.sh` の契約と終了コード（Task 2〜5）、references の 3 ファイル（Task 6）
- Produces: `/second-opinion:ask` の本体

- [ ] **Step 1: SKILL.md を書く**

```markdown
---
name: ask
description: >
  別系統のモデル（Claude Code なら Codex、Codex なら Claude Code）に問題だけを渡して
  独立に解かせ、自分の案と突き合わせる。実装前の設計判断や、同じ箇所で修正が
  2 回続いて抜けられないときに使う。「セカンドオピニオン」「別のモデルに聞いて」
  「他の見方」「行き詰まった」等で使用。コードレビューには使わない（/codex:review 等を使う）。
argument-hint: "[議題（省略可。省略時は直近の判断を対象にする）]"
---

# Second Opinion — 別モデルの独立した見解

## 設計原則

- **問題は渡す、答えは渡さない。** 相手に自分の案を見せると相手も追従する。先に独立に解かせ、後で突き合わせる
- **一致は検証済みではない。** 別モデルでも誤りは相関する。一致点も根拠を事実に遡れるかで見る
- **決めるのは人間。** 表を出して終わる。どちらを採るかをこのスキルは決めない
- **実行は手動。** 文脈検知で提案はするが、勝手に外部モデルを呼ばない

## いつ使うか

- 方針・アプローチ・トレードオフを決めようとしているとき（実装前）
- 同じ箇所への修正が 2 回続いて解決しないとき（問題の見立てを疑う）
- 実装後に「なぜこう作ったか」の妥当性を別の頭で見たいとき（たまに）

## いつ使わないか

- コード差分のレビュー（`/codex:review`、`/code-review`）
- 答えが 1 つに定まる事実確認（検索や公式ドキュメントで済む）
- typo 修正・lint 修正など判断を含まない作業

## 実行フロー

### Phase 0: ブリーフ作成

1. 会話から「問い・制約・成功条件・起きた事実・関連ファイル」を抜き出す
2. [brief-format.md](references/brief-format.md) のテンプレートで `.context/second-opinion/brief-<YYYYMMDD-HHMMSS>.md` に書く
3. brief-format.md の自己検証を行う。自分の案・仮説・解釈が混ざっていたら書き直す
4. ユーザーに 3 行で見せて承認を取る:
   「別モデルに以下を聞きます。自分の案は渡していません。
   - 問い: 〜
   - 制約/成功条件: 〜
   - 渡すファイル: 〜
   よいですか？」

### Phase 1: 独立回答

`scripts/ask.sh --brief <ブリーフのパス>` を実行する。stdout が相手の回答、stderr の `answer:` 行が保存先。

終了コードごとの対応:

| コード | ユーザーに返す文 |
|---|---|
| 0 | （Phase 2 へ） |
| 2 | 「実行環境を判定できませんでした。`--from claude`（Claude Code から実行中）か `--from codex`（Codex から実行中）を付けて再実行します」と言い、確認して再実行 |
| 3 | 「回答は保存されましたが、相手の実行中に作業ツリーが変わりました。`git status` を確認してください」。Phase 2 は続ける |
| 4 | 「相手の CLI が見つかりません。Codex CLI は https://developers.openai.com/codex/cli 、Claude Code は https://code.claude.com/docs を参照してインストールしてください」 |
| 5 | 「相手の CLI の認証が切れています。`codex login` または `claude` でログインしてから再実行してください」 |
| 6 | 「相手が時間内に応答しませんでした。ブリーフの関連ファイルを減らすか、`--timeout` を延ばして再実行します」 |
| 1 | stderr の内容をそのまま見せる |

### Phase 2: 突き合わせ

[output-format.md](references/output-format.md) の表を作る。

- 「自分」列は Phase 0 の時点で持っていた案。相手を見て変えない
- 相手の原文は全文併記。要約しない
- 相違点で自分の側に寄せる表現をしない
- 表の下の定型 2 行（人間が決める / 一致は検証済みではない）を必ず付ける

### Phase 3: 批判ラウンドの提案

次のいずれかのときだけ、1 行で提案する。それ以外は提案しない。

- 表に相違が 1 つ以上ある
- 議題が事業全体・セキュリティ・後戻りしにくい構造に触れる

「自分の案を見せて弱点を突かせますか？（往復がもう 1 回増えます）」

承認されたら:
1. ブリーフに「私たちの案」節を足した第 2 ブリーフを `.context/second-opinion/brief-<timestamp>-critique.md` に書く
2. `scripts/ask.sh --brief <第 2 ブリーフ> --round critique` を実行する
3. output-format.md の「批判ラウンド」を同じ表のファイルに追記する

## 文脈検知（提案のみ）

[trigger-rules.md](references/trigger-rules.md) の 2 パターンを検知したら 1 行で提案する。実行はしない。それ以外は沈黙する。

## 参照ファイル

| ファイル | 内容 |
|---|---|
| [brief-format.md](references/brief-format.md) | ブリーフの書式、渡す/渡さないの線引き、自己検証 |
| [output-format.md](references/output-format.md) | 突き合わせ表と批判ラウンドの書式 |
| [trigger-rules.md](references/trigger-rules.md) | 文脈検知で提案する条件と、しない条件 |
| `scripts/ask.sh --help` | 呼び出しスクリプトの引数と終了コード |
```

- [ ] **Step 2: frontmatter と参照リンクを確認する**

Run:
```bash
head -8 plugins/second-opinion/skills/ask/SKILL.md
for f in brief-format output-format trigger-rules; do test -f plugins/second-opinion/skills/ask/references/$f.md && echo "ok $f"; done
grep -c "codex exec\|claude -p\|CLAUDECODE\|--sandbox" plugins/second-opinion/skills/ask/SKILL.md
```
Expected: frontmatter が `name: ask` で始まる。3 つとも `ok`。最後の行は `0`（CLI 固有の記述が SKILL.md に無い）

- [ ] **Step 3: コミット**

```bash
git add plugins/second-opinion/skills/ask/SKILL.md
git commit -m "feat(second-opinion): ask スキル本体を追加

Phase 0 で人間がブリーフを確認する関所を置き、Phase 2 で相手の原文を
必ず残す。CLI 固有の記述は ask.sh に閉じ、SKILL.md は判断と手順だけにする。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: 開発ルール、README、ルートへの登録

**Files:**
- Create: `plugins/second-opinion/CLAUDE.md`
- Create: `plugins/second-opinion/README.md`
- Create: `plugins/second-opinion/README.en.md`
- Modify: `README.md`（プラグイン一覧の表とインストールコマンド）
- Modify: `README.en.md`（同上）
- Modify: `CLAUDE.md`（末尾のプラグイン一覧）

**Interfaces:**
- Consumes: Task 1〜7 の成果物

- [ ] **Step 1: plugins/second-opinion/CLAUDE.md を書く**

```markdown
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
```

- [ ] **Step 2: plugins/second-opinion/README.md を書く**

```markdown
[English](./README.en.md) | 日本語

# second-opinion

**AI に相談しているのに、いつも「もっともらしい答え」しか返ってこない。**

設計方針を相談しても、行き詰まりを相談しても、返ってくる答えはたいてい筋が通っていて、反論の余地がないように見える。でも、それは本当に検討し尽くした結果でしょうか。同じモデルは自分の出した案を高く評価し、あなたが示した方向に寄せて答える癖があります。

second-opinion は、**別系統のモデルに「問題だけ」を渡して独立に解かせ、自分の案と突き合わせます。** Claude Code で作業中なら Codex に、Codex で作業中なら Claude Code に聞きます。相手にこちらの案は見せません。だから、相手の答えは追従ではなく独立した見解になります。

## こんな方に

- Claude Code と Codex CLI の両方を使っていて、片方の癖に引きずられている気がする
- 設計判断の前に「別の頭」の意見が欲しいが、チャットに貼り直して聞くのは面倒
- 同じ箇所の修正を何度も繰り返して抜けられない経験がある
- コードレビューは既にやっているが、「考え方」のレビューはやれていない

## 使い方

方針を決めようとしているとき、または行き詰まったときに:

```
/second-opinion:ask
```

AI が会話から「問い・制約・成功条件・起きた事実・関連ファイル」だけを抜き出してブリーフを作り、3 行で確認してきます。

```
AI: 別モデルに以下を聞きます。自分の案は渡していません。
    - 問い: セッション状態を Redis に置くか、DB に置くか
    - 制約/成功条件: 既存の Redis を流用可 / p99 50ms 以下
    - 渡すファイル: src/session.ts, docs/adr/003.md
    よいですか？

あなた: OK
```

相手モデルがリポジトリを読み取り専用で読んで答えると、突き合わせ表が返ります。

```
| 論点 | 自分 | 相手 | 一致/相違 | 根拠を事実に遡れるか |
|---|---|---|---|---|
| 保存先 | Redis | Redis | 一致 | 両者: 既存構成 |
| TTL の扱い | 固定 24h | スライディング | 相違 | 自分: 推測 / 相手: docs/adr/003.md |

### 相手の原文
（全文）

どちらを採るかは人間が決める。
一致は「両者が同じ結論」であって「検証済み」ではない。
```

相違があるときは「自分の案を見せて弱点を突かせますか？」と 1 行で提案します。承認すると、今度はこちらの案を渡して弱点を 3 つ以上挙げさせます。

AI が「この判断、別モデルの独立した見解も聞いておきますか？」と 1 行で提案してくることもあります。実行はあなたが「はい」と言ったときだけです。

## なぜ「問題だけ」を渡すのか

LLM は、自分の生成したものを他より高く評価する傾向（自己選好バイアス）と、相手が示した意見に寄せる傾向（追従性）を持つことが研究で確認されています。同じモデルに「この案どう思う？」と聞いても、大抵は肯定から始まります。

別のモデルに聞けば解決するかというと、それだけでは足りません。相手に自分の案を見せた瞬間、相手もそれに追従します。研究では「誤った同意が正しいモデルを誤らせる方が、正しい同意が誤ったモデルを正すより効果が大きい」ことまで示されています。だから順序が大事です。先に問題だけを渡して独立に解かせ、その後で突き合わせる。

もう一つ。別モデルの答えが自分と一致しても、それは「検証済み」ではありません。異なる会社のモデルでも誤りは相関し、両方が誤るときの 6 割は同じ誤りに収束するという結果があります（ICML 2025）。だから突き合わせ表には「根拠を事実に遡れるか」の列があり、一致点も根拠がコード・仕様・計測のどれに基づくかを見ます。

この考え方は、人間の会議でも使えます。意見を聞く前に自分の案を言わない。全員一致を正解の証拠にしない。

## 前提

- Claude Code から使う場合: [Codex CLI](https://developers.openai.com/codex/cli) がインストール・ログイン済み
- Codex から使う場合: [Claude Code](https://code.claude.com/docs) がインストール・ログイン済み
- 相手モデルの利用料は相手側のプラン・API で発生します

## インストール

### Claude Code

Claude Code の画面で、以下を順番に実行してください。

```
/plugin marketplace add saladdays/agent-skills
```

マーケットプレイスが追加されたら、続けてインストールします。

```
/plugin install second-opinion@saladdays-skills
```

インストールできたら `/second-opinion:ask` で開始します。

> これは Claude Code の「プラグイン」という仕組みです。1回入れたら、あとはずっと使えます。

### Codex CLI

`skills/ask/` の中身を Codex のスキルディレクトリにコピーします。

```bash
mkdir -p ~/.agents/skills/second-opinion
cp -R plugins/second-opinion/skills/ask/. ~/.agents/skills/second-opinion/
chmod +x ~/.agents/skills/second-opinion/scripts/ask.sh
```

Codex セッション内で「セカンドオピニオンを聞いて」と伝えると、Claude Code に問い合わせます。

### Cursor

初版では Cursor からの起動には対応していません（外部 CLI を呼ぶ標準の仕組みが無いため）。

### 他のAIツール

SKILL.md と scripts/、references/ をAIツールのスキルディレクトリにコピーしてください。

## License

MIT
```

- [ ] **Step 3: plugins/second-opinion/README.en.md を書く**

```markdown
[English](./README.en.md) | [日本語](./README.md)

# second-opinion

**You ask the AI for advice, and it always sounds plausible.**

Whether you ask about a design decision or a bug you're stuck on, the answer usually sounds coherent and hard to argue with. But is it really the result of thorough consideration? The same model tends to rate its own proposals highly and to lean toward whatever direction you hinted at.

second-opinion **hands only the problem to a model from a different family, lets it answer independently, and then compares that answer with your own.** From Claude Code it asks Codex; from Codex it asks Claude Code. Your proposal is never shown to the other model, so its answer is an independent view rather than an echo.

## Who this is for

- You use both Claude Code and Codex CLI and suspect one model's habits are steering you
- You want a second brain before a design decision without pasting context into another chat
- You have been stuck fixing the same spot over and over
- You already review code, but you never review the reasoning behind it

## Usage

When you are about to decide on an approach, or when you are stuck:

```
/second-opinion:ask
```

The AI extracts only the question, constraints, success criteria, observed facts, and relevant file paths from the conversation, writes a brief, and confirms it in three lines.

```
AI: I'll ask another model the following. Our own proposal is not included.
    - Question: store session state in Redis or in the DB?
    - Constraints / success: existing Redis available / p99 under 50ms
    - Files: src/session.ts, docs/adr/003.md
    OK?

You: OK
```

The other model reads the repository read-only and answers. You get a comparison table.

```
| Point | Ours | Theirs | Agree/Differ | Traceable to evidence? |
|---|---|---|---|---|
| Storage | Redis | Redis | Agree | Both: existing setup |
| TTL | fixed 24h | sliding | Differ | Ours: guess / Theirs: docs/adr/003.md |

### Their answer, verbatim
(full text)

The human decides which to take.
Agreement means "same conclusion", not "verified".
```

When there are differences, the AI offers one line: "Show our proposal and have them attack its weaknesses?" If you accept, the second round sends your proposal and asks for at least three weaknesses.

The AI may also offer, in one line, "Want an independent view from another model on this decision?" It never runs without your yes.

## Why only the problem is sent

Research shows LLMs favor their own generations (self-preference bias) and lean toward opinions shown in the prompt (sycophancy). Ask the same model "what do you think of this plan?" and it usually starts with agreement.

Asking a different model is not enough on its own. The moment you show it your proposal, it starts agreeing too. One study found that wrong peer agreement misleads a correct model more effectively than correct agreement fixes a wrong one. So the order matters: hand over the problem first, let it answer independently, then compare.

One more thing: when the other model agrees with you, that is not verification. Errors are correlated even across vendors, and when two models are both wrong they converge on the same wrong answer about 60% of the time (ICML 2025). That is why the table has a "traceable to evidence?" column, so even agreements are checked against code, specs, or measurements.

The same principle works in human meetings: don't state your proposal before asking for opinions, and don't treat unanimity as proof.

## Prerequisites

- From Claude Code: [Codex CLI](https://developers.openai.com/codex/cli) installed and logged in
- From Codex: [Claude Code](https://code.claude.com/docs) installed and logged in
- Usage of the other model is billed on that side's plan or API

## Installation

### Claude Code

Run the following in Claude Code, in order.

```
/plugin marketplace add saladdays/agent-skills
```

Once the marketplace is added, install the plugin.

```
/plugin install second-opinion@saladdays-skills
```

Then start with `/second-opinion:ask`.

> This uses Claude Code's plugin system. Install once and it stays available.

### Codex CLI

Copy the contents of `skills/ask/` into Codex's skills directory.

```bash
mkdir -p ~/.agents/skills/second-opinion
cp -R plugins/second-opinion/skills/ask/. ~/.agents/skills/second-opinion/
chmod +x ~/.agents/skills/second-opinion/scripts/ask.sh
```

Inside a Codex session, ask for a "second opinion" and it will consult Claude Code.

### Cursor

Not supported in the first release (Cursor has no standard way to invoke an external CLI).

### Other AI tools

Copy SKILL.md, scripts/, and references/ into your tool's skills directory.

## License

MIT
```

- [ ] **Step 4: ルートの README.md / README.en.md / CLAUDE.md に登録する**

`README.md` の表の context-handoff 行の後に追加:

```markdown
| [second-opinion](./plugins/second-opinion/) | 別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせる | `/second-opinion:ask` |
```

`README.md` のインストールコマンド群の末尾に追加:

```
/plugin install second-opinion@saladdays-skills
```

`README.en.md` の表の context-handoff 行の後に追加:

```markdown
| [second-opinion](./plugins/second-opinion/) | Hand only the problem to a model from a different family, get an independent answer, and compare it with your own | `/second-opinion:ask` |
```

`README.en.md` のインストールコマンド群の末尾に追加:

```
/plugin install second-opinion@saladdays-skills
```

`CLAUDE.md` のプラグイン一覧の末尾に追加:

```markdown
- [second-opinion](./plugins/second-opinion/) — 別系統のモデルに問題だけを渡して独立に解かせ、自分の案と突き合わせる
```

- [ ] **Step 5: 登録漏れを確認する**

Run:
```bash
grep -c "second-opinion" README.md README.en.md CLAUDE.md .claude-plugin/marketplace.json .cursor-plugin/marketplace.json
head -1 plugins/second-opinion/README.md plugins/second-opinion/README.en.md
bash plugins/second-opinion/skills/ask/scripts/ask.test.sh | tail -1
```
Expected: 各ファイルで 1 以上（README.md と README.en.md は 2）。両 README の 1 行目が言語スイッチャー。テストが `passed=N failed=0`

- [ ] **Step 6: コミット**

```bash
git add plugins/second-opinion/CLAUDE.md plugins/second-opinion/README.md plugins/second-opinion/README.en.md README.md README.en.md CLAUDE.md
git commit -m "docs(second-opinion): 開発ルール・README（日英）・ルート一覧への登録を追加

利用者が「なぜ問題だけを渡すのか」を理解して使えるよう、研究に基づく
ロジック解説を README に含める。CLI 仕様は変わりやすいので確認日と
バージョンを CLAUDE.md に残す。

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## 実行後の確認（全タスク完了時）

1. `bash plugins/second-opinion/skills/ask/scripts/ask.test.sh` が `failed=0`
2. Task 5 Step 5 の実 CLI 疎通が両方向で rc=0（ユーザー承認後）
3. `.context/handoff-main.md` の Status に「second-opinion 初版実装完了」を 1 行追記
4. コミット前の区切りとして `/codex:review`（ユーザー起動）を提案する
