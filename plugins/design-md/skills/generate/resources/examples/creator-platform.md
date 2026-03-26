---
generated: 2026-03-24
mode: conversation
version: 1
platform: web
token_source: inline
---

# Design System: Atelier

## TL;DR

- 北極星: 「静かな書斎」— UIは消え、作品だけが読者の目に映る
- カラー: ウォームグレー基調、アクセントは Terracotta (#C2705B) の1色のみ
- タイポ: 本文は Noto Serif JP、UIは Noto Sans JP。16px基準、行間1.8の長文特化
- スペーシング: 8px単位、コンテンツ領域は余白を贅沢に使う
- 避けること: UIの自己主張、4色以上の同時使用、コンテンツ幅 720px 超え

---

## Design Principles

### Creative North Star

**Metaphor:** 「静かな書斎」— 良い書斎は本棚と机と光だけでできている。照明は本を照らし、机は書くことに集中させ、本棚は探しているものを自然に差し出す。

**This means:**
- UIクロムは最小限。ナビゲーションやツールバーはコンテンツの邪魔をしない
- サーフェスはウォームグレーの紙のような質感。冷たいデジタル感を避ける
- 投稿エディタでは書くことだけに集中できる。装飾メニューはインラインで控えめに出す
- 読者ビューではコンテンツ以外のUI要素を極力排除する

**This does NOT mean:**
- レトロな紙テクスチャやスキューモーフィズムを使うことではない
- 機能を削りすぎてナビゲーションが困難になることではない
- 茶色い配色にすることではない
- アニメーションを一切使わないことではない

### When Principles Conflict

- コンテンツの可読性 vs UIの統一感 → 可読性を取る（長文体験がプロダクトの核心）
- クリエイターの自由度 vs プラットフォームの統一感 → 統一感を取る（読者体験の一貫性を守る。ただしカバー画像やプロフィールで個性を出す余地は残す）
- ミニマリズム vs 発見しやすさ → 発見しやすさを取る（コンテンツの可視性がクリエイターの価値に直結するため）
- 美しい余白 vs 情報密度 → 場面で分ける。読書ビュー=余白優先、フィード/検索=密度優先

### Global Constraints

- コンテンツ本文には純黒 (#000000) を使わない → `--color-on-surface` (#2C2825) で柔らかいコントラストを保つ
- 角丸のピル型 (border-radius: 9999px) を大きなサーフェスに使わない → `radius-sm` (4px) または `radius-md` (8px) で控えめにまとめる
- ドロップシャドウを2段以上重ねない → サーフェス色差で階層を表現する
- アクセシビリティ: WCAG 2.2 AA 準拠。長文コンテンツのコントラスト比は 7:1 を目標とする
- レスポンシブ: 320px から対応。コンテンツ領域の最大幅は全画面幅で固定

---

## Visual Language

### Mood & Tone
温かく、落ち着いていて、控えめ。図書館の閲覧室のような静けさと、お気に入りのカフェのような親しみやすさの間。UIは背景に溶け、クリエイターの作品が前面に出る。

### Visual Characteristics
- **角丸:** 小さめ (4-8px)。サーフェスの柔らかさを演出するが、主張しない
- **影:** ほぼ使わない。ドロップダウンやモーダルなど浮遊要素のみ最小限で使用
- **線:** 薄く控えめな区切り線 (`--color-border`: 1px solid)。存在を感じさせない濃度
- **密度:** 読書体験では余白を贅沢に。フィード画面では適度な密度を保つ
- **画像:** コンテンツ画像はフル幅表示可能。UIアイコンは線画スタイルで統一

---

## Color Strategy

### Palette

| Intent | Token | Value | Do | Don't |
|---|---|---|---|---|
| Primary action | `--color-primary` | #C2705B | フォローボタン、公開ボタン、重要なCTA | 背景全体、装飾、大面積に使わない。白テキスト(#FFF)を直接載せない。ボタン背景には `--color-primary-hover` (#A85C49) をデフォルトにし、テキストは `--color-on-primary` (#FFFFFF) を使う |
| Primary hover | `--color-primary-hover` | #A85C49 | Primary のホバー状態のみ | 通常状態での使用 |
| Surface base | `--color-surface` | #FAF8F5 | ページ背景 | テキスト色としての使用 |
| Surface raised | `--color-surface-raised` | #FFFFFF | カード、エディタ領域、モーダル | ページ背景（base と区別するため） |
| Surface inset | `--color-surface-inset` | #F3F0EB | コードブロック背景、引用背景、入力フィールド | カードやボタンの背景 |
| On surface | `--color-on-surface` | #2C2825 | 本文テキスト、見出し | 純黒 (#000) は使わない |
| On surface muted | `--color-on-surface-muted` | #6B6560 | 日付、メタ情報、補助テキスト | 本文テキスト（コントラスト不足） |
| Border | `--color-border` | #E8E4DF | セクション区切り、カード境界 | 強調の手段として太くしない |
| Danger | `--color-danger` | #C53030 | 削除確認、エラーメッセージ | 警告に流用しない → warning を使う |
| Success | `--color-success` | #2F855A | 公開完了、保存完了 | 装飾、常時表示 |

### Rules

#### Warm Neutral Rule
すべてのグレー系カラーは暖色寄り (黄〜オレンジのアンダートーン) にする。青みがかったクールグレーは使用しない。
理由: クリエイターの作品を引き立てる温かみのある背景を維持するため。

#### Single Accent Rule
アクセントカラーは `--color-primary` (Terracotta) の1色のみ。セマンティックカラー (danger/success) は機能的用途に限定し、装飾として複数色を同時に使わない。

**Exception:** クリエイターのプロフィールページではカバー画像の色がアクセントに影響してよい。
理由: クリエイターの個性表現の場であり、プラットフォームの色制約よりも個人の世界観を尊重するため。

⚠️ Avoid: サーフェス上に3色以上のアクセントを同時配置 → 色の役割が曖昧になり、視線誘導が破綻する

---

## Typography

### Scale

**原則:** 本文コンテンツには明朝体 (Serif) で文学的な読書体験を提供する。UIラベルやナビゲーションにはゴシック体 (Sans-serif) で機能性を確保する。

| Context | Token | Font | Size | Weight | Line Height | Reasoning |
|---|---|---|---|---|---|---|
| 記事タイトル | `display-lg` | Noto Serif JP | 2rem | 700 | 1.4 | 作品の顔。読者の最初の接点 |
| セクション見出し | `heading-lg` | Noto Serif JP | 1.5rem | 700 | 1.5 | 長文中の構造。スクロール中の視認性 |
| 小見出し | `heading-md` | Noto Serif JP | 1.25rem | 600 | 1.5 | コンテンツの細かい区切り |
| 本文 | `body-lg` | Noto Serif JP | 1rem | 400 | 1.8 | 長文可読性の最適値。日本語は行間広め |
| UI本文 | `body-md` | Noto Sans JP | 1rem | 400 | 1.6 | フィードの説明文、プロフィール |
| キャプション | `body-sm` | Noto Sans JP | 0.875rem | 400 | 1.5 | 日時、メタ情報、写真キャプション |
| UIラベル | `label-md` | Noto Sans JP | 0.875rem | 500 | 1.4 | ボタン、タブ、ナビゲーション |
| UIラベル小 | `label-sm` | Noto Sans JP | 0.75rem | 500 | 1.4 | タグ、バッジ、補助ラベル |

### Rules

#### Serif/Sans Split Rule
コンテンツ領域 (記事本文・見出し) は Serif、UI領域 (ナビ・ボタン・フォーム) は Sans-serif。混在させない。
理由: 読書体験とUI操作の境界を書体で暗黙的に示し、読者が「今読んでいる」か「操作している」かを意識せず区別できるようにするため。

**Exception:** クリエイターのプロフィール自己紹介文は `body-lg` (Serif) を使ってよい。
理由: 自己紹介は作品の延長であり、UI操作ではなくコンテンツとして扱うため。

#### Reading Comfort Rule
本文 (`body-lg`) の1行あたりの文字数は 35-45文字 (日本語) を目安にする。コンテンツ幅の上限 680px はこの基準から逆算した値。

⚠️ Avoid: 0.75rem 未満のテキスト → アクセシビリティと可読性の限界値。使用しない

### Special Content Blocks

**原則:** 引用やコードブロックは「書斎の本棚から引き出した参照」として扱う。本文と地続きだが、別の声・別の文脈であることを視覚的に示す。

#### Margin Note Rule
特殊コンテンツブロックは、本文との区別が即座にできることを基準とする。装飾は最小限に、サーフェス色差と書体変化で区別する。

| Block | Background | Border | Font | Padding | Radius | Reasoning |
|---|---|---|---|---|---|---|
| Blockquote | `--color-surface-inset` | left 3px solid `--color-border` | Noto Serif JP italic, `body-lg` | `space-4` `space-6` | `radius-sm` | 本文と同じ Serif だが italic で「別の声」を示す。左ボーダーは引用の伝統的な視覚記号 |
| Code block (inline) | `--color-surface-inset` | none | Monospace, 0.875em | 2px `space-1` | `radius-sm` | 本文中の技術用語。背景色だけで区別する最小限の処理 |
| Code block (multi-line) | `--color-surface-inset` | none | Monospace, `body-sm` (0.875rem) | `space-4` | `radius-md` | 技術的な引用。書体とサーフェスの沈みで本文から分離する |
| 埋め込みコンテンツ | `--color-surface-raised` | 1px solid `--color-border` | — | `space-4` | `radius-md` | 外部リンクのプレビュー。カードと同じサーフェスで「参照」の印象を統一する |

**Exception:** クリエイターが記事内でカスタム装飾を施した引用は、プラットフォームのスタイルを上書きしない。
理由: クリエイターの表現の自由を尊重する。ただしフォントファミリーの変更は Serif/Sans Split Rule に従い制限する。

---

## Spacing & Layout

### Spacing Scale

**原則:** 8px基準のリズム。コンテンツ間の余白は関係性の距離を表す。同じ作品の要素は近く、異なる作品は遠く。

| Token | Value | Use case |
|---|---|---|
| `space-1` | 4px | アイコンとラベルの間、テキスト内の微調整 |
| `space-2` | 8px | タグ間、メタ情報の要素間 |
| `space-3` | 12px | フォームフィールド間、リスト項目間 |
| `space-4` | 16px | カード内パディング、段落間 |
| `space-6` | 24px | カード内セクション間 |
| `space-8` | 32px | フィード内の記事カード間 |
| `space-12` | 48px | ページ内の主要セクション間 |
| `space-16` | 64px | ヘッダーとコンテンツ間、フッター前 |
| `space-24` | 96px | 記事本文中の大きなセクション区切り |

### Layout Philosophy

#### Content-First Layout Rule
コンテンツ領域は常に最大幅を確保し、UIクロムは最小限に抑える。

- 記事本文の最大幅: 680px（日本語35-45字/行の最適値）
- 記事内画像の最大幅: 960px（本文より広くとって視覚的アクセントにする）
- フィードの最大幅: 720px（カード1列。一覧性より可読性を優先）
- ブレイクポイント: `sm` 640px / `md` 768px / `lg` 1024px / `xl` 1280px

**Exception:** クリエイターのダッシュボード (統計・管理画面) ではサイドバー 240px を許容する。
理由: 複数メニューの同時アクセスが管理効率に直結するため。

#### Responsive Behavior
- モバイル (< 640px): シングルカラム。ナビはハンバーガーメニュー。記事は全幅パディング `space-4`
- タブレット (640-1023px): シングルカラム。ナビは上部固定。余白が広がる
- デスクトップ (≥ 1024px): コンテンツ中央配置。余白が十分にとれる

### Surface Hierarchy

| Level | Surface | Use case | Elevation |
|---|---|---|---|
| 0 | `--color-surface` | ページ背景 | なし |
| 1 | `--color-surface-raised` | 記事カード、エディタ、プロフィールカード | 色差のみ |
| 1.5 | `--color-surface-inset` | コードブロック、引用、入力フィールド | 内側に沈む色差 |
| 2 | Dropdown / Tooltip | ユーザーメニュー、書式ツールバー | `shadow-sm` (0 1px 3px rgba(0,0,0,0.08)) |
| 3 | Modal / Dialog | 公開確認、削除確認 | `shadow-md` (0 4px 12px rgba(0,0,0,0.12)) + overlay |

---

## Component Patterns

### Selection Guide

**コンテンツ表示:**
- 単一記事 → 記事ビュー（全幅・Serif本文）
- 記事一覧 → フィードカード（縦スクロール・1カラム）
- クリエイター紹介 → プロフィールカード（アバター + 自己紹介 + 最新作品）
- 理由: コンテンツの種類ごとに最適な情報密度と読書体験が異なるため

**アクション:**
- 主要CTA（フォロー・公開） → Filled Button (`--color-primary`)
- 副次アクション（下書き保存・シェア） → Outlined Button / Ghost Button
- 3個以上の操作 → ドロップダウンメニューにまとめる
- 理由: 視覚的階層でアクションの重要度を伝え、選択の迷いを減らす

**フィードバック:**
- 保存完了・公開完了 → Toast（自動消去 3秒）
- 削除・非公開化 → 確認 Dialog（不可逆操作は明示的同意を求める）
- フォーム入力エラー → Inline Error（フィールド直下に赤テキスト）
- 理由: 操作の重大度と可逆性に応じて中断のレベルを変える

**ナビゲーション:**
- グローバルナビ → 上部バー。ロゴ + 検索 + ユーザーメニューの3要素に絞る
- コンテンツ内ナビ → 目次 (Table of Contents)。長文記事ではスクロール追従
- カテゴリ/タグ → フィルターチップ。横スクロールで省スペース化
- 理由: ナビゲーションの存在感を最小化し、コンテンツへの没入を守る

### Composition Rules

#### Flat Card Rule
Card 内に Card をネストしない。記事カード内のクリエイター情報はカードではなくインラインで表示する。
理由: サーフェスのネストは視覚的階層を複雑にし、書斎の静けさを損なうため。

- Modal 内で別の Modal を開かない → 画面遷移またはモーダル内コンテンツの差し替えで対応
- エディタのツールバーは固定表示しない → テキスト選択時にインラインで出現する（フローティングツールバー）
- フォームは1カラム。ラベルはフィールドの上に配置する

### State Handling

**原則:** インタラクティブ要素は5状態を必ず定義する。状態変化は控えめに、しかし確実にフィードバックする。

| State | Visual Treatment | Reasoning |
|---|---|---|
| Default | 定義済みスタイル | 静止状態 |
| Focus | `--color-primary` のフォーカスリング (2px, offset 2px) | キーボード操作のアクセシビリティ |
| Active | 背景色をさらに1段暗く + scale(0.98) | 押下フィードバック |
| Disabled | opacity 0.4, cursor: not-allowed | 操作不可の明示 |

#### Hover by Element Category

| Element | Hover Treatment | Reasoning |
|---|---|---|
| 記事カード | `--color-surface-raised` → `--color-surface` に沈む + `shadow-sm` 消失 | 書斎で本の背表紙に手が触れる感覚。派手な変化ではなく、静かに「選んでいる」ことを伝える |
| テキストリンク | 下線出現 (`text-decoration: underline`, `--color-primary`) | 本文中のリンクは控えめに。下線だけで操作可能を示す |
| アイコンボタン | 背景に円形ハイライト (`--color-surface-inset`, radius: 50%) | タップ領域を可視化しつつ、書斎のトーンを壊さない |
| CTA ボタン (Filled) | `--color-primary` → `--color-primary-hover` に切替 | 主要アクションの明確なフィードバック |
| Ghost / Outlined ボタン | 背景色を `--color-surface-inset` で薄く塗る | 副次アクションの控えめなフィードバック |

### Emotional Interaction

**原則:** 機能的操作と感情的操作を同じ処理にしない。感情が伴うインタラクションには、書斎で本にしおりを挟むような「静かだが確かな手応え」を返す。

#### Bookmark Moment Rule
感情的インタラクション（スキ・フォロー・ブックマーク）は、機能的ホバーとは別の状態遷移を持つ。視覚的な変化はメタファーに沿い、小さくても印象に残る演出にする。

| Action | Default | Hover | Active (実行) | Completed | Reasoning |
|---|---|---|---|---|---|
| スキ | ハートアイコン (線画, `--color-on-surface-muted`) | アイコン色が `--color-primary` に変化 | scale(1.2→1.0) バウンス + 色塗りつぶし (`--color-primary`) | 塗りつぶし状態を維持 | しおりを挟む瞬間の「パタン」という手応え。静かだが確実な変化 |
| フォロー | Outlined ボタン「フォロー」 | ボーダー色が `--color-primary` に変化 | Filled ボタンに切替 (`motion-standard`) | Filled 状態 + テキスト「フォロー中」 | 書斎の本棚に新しい著者を迎え入れる。状態の切替が明確 |
| ブックマーク | リボンアイコン (線画, `--color-on-surface-muted`) | アイコン色が `--color-primary` に変化 | アイコン塗りつぶし + 微細な下方移動 (2px, `motion-micro`) | 塗りつぶし状態を維持 | 本にしおりを差し込む動き。下方向の移動で「挟む」を暗示 |

**Exception:** 取り消し操作 (スキ解除・フォロー解除) は即座に静かに戻す。バウンスや演出はつけない。
理由: 感情の「引き」は静かであるべき。派手な取り消し演出はユーザーに罪悪感を与えるため。

### Density Guide

| Context | Size | Inner Padding | Font | Reasoning |
|---|---|---|---|---|
| 記事読書ビュー | lg | `space-8` - `space-12` | Serif `body-lg` | 没入型の読書体験 |
| フィード/一覧 | md | `space-4` - `space-6` | Sans `body-md` | 一覧性と可読性のバランス |
| エディタ | lg | `space-6` - `space-8` | Serif `body-lg` | 執筆中の集中と可読性 |
| ダッシュボード | sm | `space-3` - `space-4` | Sans `body-sm` | 情報密度を優先した管理画面 |
| ヘッダー/ナビ | sm | `space-2` - `space-3` | Sans `label-md` | 存在感を抑えたUI領域 |

---

## Motion & Transitions

**原則:** 動きはコンテンツの登場と退場を自然にするためだけに使う。装飾的なアニメーションは書斎の静けさを壊す。

| Token | Duration | Easing | Use case |
|---|---|---|---|
| `motion-micro` | 100ms | ease-out | ボタンホバー、トグル切替 |
| `motion-standard` | 200ms | ease-out | Toast出現、ドロップダウン展開 |
| `motion-emphasis` | 300ms | ease-in-out | モーダル開閉、ページ遷移 |

### Rules

#### Content Appear Rule
コンテンツの初回表示は fade-in (opacity 0→1, `motion-standard`) のみ。スライドやスケールは使わない。
理由: コンテンツが「現れる」のではなく「そこにあったものが見える」感覚を演出するため。

⚠️ Avoid: バウンスやスプリングアニメーション → 代わりに ease-out で静かに着地させる

---

## Design Token References

### Token Source
`token_source: inline`

すべてのトークンはこのファイル内で定義。将来的に CSS Custom Properties へ移行する場合は以下の命名規則に従う。

### Naming Convention

```
--atelier-{category}-{variant}
```

| Category | Example |
|---|---|
| color | `--atelier-color-primary`, `--atelier-color-surface` |
| font | `--atelier-font-serif`, `--atelier-font-sans` |
| size | `--atelier-size-body-lg`, `--atelier-size-heading-lg` |
| space | `--atelier-space-4`, `--atelier-space-8` |
| radius | `--atelier-radius-sm`, `--atelier-radius-md` |
| shadow | `--atelier-shadow-sm`, `--atelier-shadow-md` |
| motion | `--atelier-motion-standard`, `--atelier-motion-emphasis` |

### Border Radius Scale

| Token | Value | Use case |
|---|---|---|
| `radius-sm` | 4px | ボタン、入力フィールド、タグ |
| `radius-md` | 8px | カード、ドロップダウン、モーダル |
| `radius-lg` | 12px | 画像コンテナ、カバー画像の角 |
