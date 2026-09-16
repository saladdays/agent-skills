# セットアップガイド

## Claude Code

### 1. フック設定

`.claude/settings.json`（プロジェクトルート）に以下を追加する。
既存の settings.json がある場合は、`hooks` と `permissions` の各キーをマージすること。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .context/hooks/session-start.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .context/hooks/pre-compact.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .context/hooks/post-compact.sh"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Edit(.context/*)",
      "Write(.context/*)"
    ]
  }
}
```

### 2. フックスクリプトの配置

`.context/hooks/` に以下の3ファイルを作成する。

#### .context/hooks/session-start.sh

```bash
#!/bin/bash
# SessionStart: ブランチ別handoff.mdのリンク + 鮮度チェック + AI指示注入

BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
SAFE_BRANCH=$(echo "$BRANCH" | sed 's/[\/:]/-/g')
HANDOFF=".context/handoff-${SAFE_BRANCH}.md"

# ブランチ別ファイルへのシンボリックリンクを更新
ln -sf "handoff-${SAFE_BRANCH}.md" .context/handoff.md 2>/dev/null

# ファイルの経過時間を人間向けに整形（macOS/Linux 両対応）
age_of() {
  local mtime=""
  if stat --version 2>/dev/null | grep -q GNU; then
    mtime=$(stat -c %Y "$1" 2>/dev/null)
  else
    mtime=$(stat -f %m "$1" 2>/dev/null)
  fi
  if [ -z "$mtime" ]; then echo "不明"; return; fi
  local diff=$(( ($(date +%s) - mtime) / 60 ))
  if [ $diff -lt 60 ]; then echo "${diff}分前"
  elif [ $diff -lt 1440 ]; then echo "$((diff/60))時間前"
  else echo "$((diff/1440))日前"; fi
}

if [ ! -f "$HANDOFF" ]; then
  # 現ブランチ用のファイルがない場合は、最新の他ブランチ用ファイルへ誘導する
  # （ブランチをマージして main に戻った直後などに引き継ぎが途切れるのを防ぐ）
  LATEST=$(ls -t .context/handoff-*.md 2>/dev/null | head -1)
  if [ -z "$LATEST" ]; then
    echo "{}"
    exit 0
  fi
  LATEST_BRANCH=$(grep -m1 "^branch:" "$LATEST" 2>/dev/null | sed 's/^branch: *//;s/"//g')
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"現在のブランチ %s 用の引き継ぎファイルはありませんが、ブランチ %s の引き継ぎ（%sに保存）が %s にあります。読んで3行サマリを表示し、現ブランチに引き継ぐ内容があれば %s として保存してよいか確認してください。"}}' "$BRANCH" "${LATEST_BRANCH:-不明}" "$(age_of "$LATEST")" "$LATEST" "$HANDOFF"
  exit 0
fi

AGE=$(age_of "$HANDOFF")

# git HEAD の突合
HEAD=$(grep -m1 "git_head" "$HANDOFF" 2>/dev/null | sed 's/.*: *//;s/"//g;s/ //g')
CURRENT=$(git rev-parse --short HEAD 2>/dev/null)
WARN=""
if [ -n "$HEAD" ] && [ -n "$CURRENT" ] && [ "$HEAD" != "$CURRENT" ]; then
  WARN=" 注意: 保存後にコミットが追加されています。"
fi

# additionalContext で AI に指示を注入
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"前回のセッションから引き継ぎ情報があります（%sに保存、ブランチ: %s）。.context/handoff.md を読んで3行サマリを表示し、この認識で合っていますか？と確認してください。%s"}}' "$AGE" "$BRANCH" "$WARN"
```

#### .context/hooks/pre-compact.sh

```bash
#!/bin/bash
# PreCompact: 機械的スナップショットを退避

mkdir -p .context
{
  echo "--- PreCompact Snapshot $(date -u +%Y-%m-%dT%H:%M:%SZ) ---"
  echo "branch: $(git branch --show-current 2>/dev/null)"
  echo "head: $(git rev-parse --short HEAD 2>/dev/null)"
  echo ""
  git diff --stat 2>/dev/null | head -20
  echo ""
  git log --oneline -5 2>/dev/null
} > .context/.pre-compact-snapshot.tmp
```

#### .context/hooks/post-compact.sh

```bash
#!/bin/bash
# PostCompact: AI にhandoff.md更新を指示

printf '{"hookSpecificOutput":{"hookEventName":"PostCompact","additionalContext":"コンテキストがコンパクションされました。他の応答に先立ち、.context/handoff.md を最新の作業状態で更新してください。.context/.pre-compact-snapshot.tmp に機械的スナップショットがあります。既存の handoff.md の Dead Ends セクションは棄却理由を保持したまま更新してください。更新が完了したら保存結果を1行で報告してください。"}}'
```

### 3. 自動保存ルールを配置

`.claude/rules/context-handoff.md` を作成し、[auto-save-rules.md](auto-save-rules.md) の「ファイルの内容」セクションをそのまま書き込む。

プロジェクトの CLAUDE.md は変更しない。`.claude/rules/` のファイルは CLAUDE.md と同等に自動読み込みされる。

### 4. 初回の handoff.md 生成

`/context-handoff:save` を実行すると、現在の作業状態から handoff.md が自動生成される。

---

## Cursor

Cursor のルールファイル（`.cursor/rules`）に以下を追加:

```
セッション開始時に .context/handoff.md が存在すれば読み込み、3行サマリを表示すること。
重要な設計判断・アプローチ棄却時に .context/handoff.md に1行追記すること。
```

フック機構は Cursor には存在しないため、L2（PostCompact）は利用不可。
L1（差分追記）と L3（手動保存）で運用する。

---

## 他の AI ツール

1. `skills/save/SKILL.md` を AI ツールのスキルディレクトリにコピー
2. セッション開始時に `.context/handoff.md` を読み込むよう設定
3. 作業中に判断・棄却があれば handoff.md に追記するルールを設定

---

## トラブルシューティング

### handoff.md が壊れた / 内容が不正確な場合

```bash
rm .context/handoff.md .context/handoff-*.md
```

その後 `/context-handoff:save` を実行して再生成してください。
`.context/archive/` に過去のスナップショットがあれば参照できます。

### シンボリックリンクが壊れた場合

`.context/handoff.md` が読み込めない場合、リンクが壊れている可能性がある:

```bash
rm .context/handoff.md
```

次の SessionStart フック実行時（新セッション開始時）に自動で再作成される。
すぐに修復したい場合:

```bash
BRANCH=$(git branch --show-current | sed 's/[\/:]/-/g')
ln -sf "handoff-${BRANCH}.md" .context/handoff.md
```

### ブランチを切り替えたら引き継ぎが表示されなくなった場合

handoff.md はブランチ別ファイル（`handoff-{branch}.md`）なので、ブランチをマージして main に戻った直後は main 用のファイルが存在しない。
SessionStart フックは、その場合に最新の他ブランチ用ファイルを案内するので、指示に従って main 用として保存し直せばよい。
不要になった旧ブランチ用ファイルは `.context/archive/` へ移動する。

### フックが動作しない場合

`.context/hooks/` のスクリプトに実行権限があるか確認:

```bash
chmod +x .context/hooks/*.sh
```

---

## マルチユーザー環境での運用

### 個人開発（1人で複数 PC）

`.context/` を git 追跡する（デフォルト）。ブランチ別ファイルなのでコンフリクトしにくい。

```
git push   （PC-A で）
git pull   （PC-B で）
```

### チーム開発（複数人で同一リポジトリ）

handoff.md は個人の作業状態を含むため、チームメンバー間でコンフリクトが起きうる。
以下のいずれかの方式を選択:

**方式 A: .gitignore に追加（推奨）**

```bash
echo ".context/" >> .gitignore
```

チームで共有すべき情報（設計判断等）は CLAUDE.md や DESIGN.md に書く。
handoff.md は個人のローカル作業メモとして扱う。

**方式 B: ユーザー別ファイル**

handoff.md のファイル名にユーザー名を含める:
- `.context/handoff-{branch}-{username}.md`
- SessionStart フックの `SAFE_BRANCH` 行の後に `SAFE_BRANCH="${SAFE_BRANCH}-$(whoami)"` を追加

この方式なら git 追跡しても他のメンバーとコンフリクトしない。
