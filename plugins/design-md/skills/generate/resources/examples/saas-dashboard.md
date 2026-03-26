---
generated: 2026-03-24
mode: conversation
version: 1
platform: web
token_source: inline
---

# Design System: Taskflow Dashboard

## TL;DR

- 北極星: 「管制塔のコックピット」— 大量の情報を秩序立てて一覧し、即座に判断できる
- カラー: ニュートラルグレー基調、アクションは Indigo-600 の1色。ステータスは4色の意味色で表現
- タイポ: Inter、6段階、14px基準（情報密度のため標準より1段小さい）
- スペーシング: 4px基準の高密度リズム。カード内は詰め、セクション間で呼吸させる
- 避けること: 装飾的な影、角丸の過剰使用、情報を隠すアコーディオン

## Design Principles

### Creative North Star

**Metaphor:** 「管制塔のコックピット」— すべてのプロジェクト状況が一望でき、異常は自ら浮かび上がる。操作者は冷静に、最小限の動作で判断を下す。

**This means:**
- 情報密度: 1画面に多くのデータポイントを表示する。スクロールより一覧性を優先
- 視覚的階層: 数値・ステータスが最も目立ち、UIクロム（枠線・ラベル等）は控えめに
- 状態の可視化: 正常は静か、異常は色とアイコンで即座に視認できる
- 操作効率: よく使うアクションは1クリック以内。バッチ操作を積極的にサポート

**This does NOT mean:**
- 航空管制のようなダークテーマやレトロUIにすることではない
- 余白をゼロにして要素を詰め込むことではない（密度には秩序が必要）
- すべてをリアルタイム更新するダッシュボードウィジェットにすることではない
- グラフやチャートを主役にすることではない（主役はタスクとステータスの一覧）

### When Principles Conflict

- 情報密度を上げると可読性が下がる → 可読性を取る（14px未満にしない。行間を1.4以上に保つ）
- 一覧性を上げると個別の詳細が見えない → 一覧を取る（詳細はドロワーかサイドパネルで対応）
- 一貫性を崩すが業務フローに最適 → 業務フローを取る（ただし例外として本ファイルに追記）
- 美しいレイアウトだが操作ステップが増える → 操作効率を取る（PMの時間は最も高コストなリソース）

### Global Constraints

- 純黒 (#000000) をテキストに使わない → `--color-on-surface` (#1E293B) を使用。理由: 長時間利用で目の疲労を軽減するため
- 影は最大2段階まで → ドロップダウンとモーダルのみ。カードには影を使わず、ボーダーで区切る。理由: 情報密度の高い画面で影が重なると視覚ノイズになるため
- アクセシビリティ: WCAG 2.2 AA 準拠。コントラスト比 4.5:1 を最低基準とする
- アニメーション: `prefers-reduced-motion` を尊重する。装飾アニメーションは一切使わない
- 最小タップターゲット: 32px（デスクトップ主体のため44pxではなく32px。ただしモバイル対応時は44px）

## Visual Language

### Mood & Tone
落ち着き、信頼、効率。プロフェッショナルな道具としての質実剛健さ。親しみやすさより正確さを優先する。

### Visual Characteristics
- **角丸:** 控えめ。`radius-sm`(4px) を基本とし、`radius-md`(6px) をカードに使用。ピル型はタグのみ許可
- **ボーダー:** 1px solid、色は `--color-border`。区切りの主要手段。影の代替
- **密度:** 高め。テーブル行は compact(36px) をデフォルトとし、必要に応じて comfortable(44px) に切り替え
- **コントラスト:** 中〜高。データ部分は高コントラスト、UIクロム部分は低コントラスト
- **アイコン:** 線画スタイル、1.5px stroke、16px基準。塗りアイコンはアクティブ状態のナビゲーションのみ

## Color Strategy

### Palette

| Intent | Token | Value | Do | Don't |
|---|---|---|---|---|
| Primary action | `--color-primary` | #4F46E5 (Indigo-600) | CTA、主要ボタン、アクティブタブ | 背景、装飾、テキスト色 |
| Primary hover | `--color-primary-hover` | #4338CA (Indigo-700) | Primary のホバー・アクティブ状態 | 単独使用（Primaryとペアで使う） |
| Surface base | `--color-surface` | #F8FAFC (Slate-50) | ページ全体の背景 | カード背景（raisedを使う） |
| Surface raised | `--color-surface-raised` | #FFFFFF | カード、パネル、テーブル背景 | ページ背景に使わない |
| Surface inset | `--color-surface-inset` | #F1F5F9 (Slate-100) | 入力フィールド背景、サイドバー背景 | 主要コンテンツ領域の背景 |
| On surface | `--color-on-surface` | #1E293B (Slate-800) | 本文テキスト、見出し | — |
| On surface secondary | `--color-on-surface-secondary` | #475569 (Slate-600) | 補助テキスト、プレースホルダー | 小サイズテキスト(label-sm以下)には使わない |
| Border | `--color-border` | #E2E8F0 (Slate-200) | カード境界、テーブル罫線、ディバイダー | テキスト色、背景 |
| Danger | `--color-danger` | #DC2626 (Red-600) | 削除ボタン、エラーメッセージ、期限超過 | 警告に使わない（warningを使う） |
| Warning | `--color-warning` | #D97706 (Amber-600) | 期限接近、注意喚起バッジ | エラー表示（dangerを使う） |
| Success | `--color-success` | #059669 (Emerald-600) | 完了ステータス、成功トースト | 装飾（緑は意味色として限定使用） |
| Info | `--color-info` | #0284C7 (Sky-600) | ヒント、進行中ステータス | Primary の代替にしない |

### Rules

#### Single-Accent Rule
アクセントカラーは `--color-primary` (Indigo-600) の1色のみ。ステータス色（danger/warning/success/info）は意味色であり、装飾には使わない。

**Exception:** プロジェクトごとのラベルカラー（最大8色）。理由: プロジェクトの識別にはカラーコーディングが業務効率に直結するため。ラベルカラーは彩度を落とした Pastel 系で統一し、テキストは対応する Dark 色を使う。

#### Status Color Priority Rule
ステータス色は以下の優先順位で適用する。同一要素に複数ステータスが該当する場合、上位を採用する。
1. Danger（期限超過、エラー）→ 即時対応が必要
2. Warning（期限接近、要注意）→ 近日中の対応が必要
3. Info（進行中、レビュー待ち）→ 状況の把握
4. Success（完了）→ 対応不要の確認

Avoid: ステータス色を背景全体に塗る → 代わりに左ボーダー(3px)またはバッジで表現する。理由: 背景塗りは情報密度が高い画面でノイズになるため

## Typography

### Scale

**原則:** 14pxを本文基準とする。業務ツールでは情報密度が価値であり、16px基準では1画面の情報量が不足する。ただし最小は12pxを下限とする。

| Context | Token | Font | Size | Weight | Line Height | Reasoning |
|---|---|---|---|---|---|---|
| Page title | `heading-xl` | Inter | 1.5rem (24px) | 600 | 1.3 | ページの識別。大きすぎると面積を浪費する |
| Section heading | `heading-lg` | Inter | 1.25rem (20px) | 600 | 1.35 | カードやパネルの見出し |
| Card title | `heading-md` | Inter | 1rem (16px) | 600 | 1.4 | カード内の小見出し、サイドバーセクション |
| Body text | `body-md` | Inter | 0.875rem (14px) | 400 | 1.6 | 本文の基準。タスク説明、コメント |
| Table cell | `body-sm` | Inter | 0.8125rem (13px) | 400 | 1.5 | テーブルデータ。密度と可読性のバランス |
| Caption/badge | `caption` | Inter | 0.75rem (12px) | 500 | 1.4 | ステータスバッジ、タイムスタンプ、メタデータ |

#### Monospace Exception Rule
数値データ（工数、金額、日付）には `font-variant-numeric: tabular-nums` を適用する。テーブルの数値列が縦に揃い、走査性が向上するため。

Avoid: 0.75rem (12px) 未満のテキスト → 使わない。可読性の限界であり、AA基準を満たすコントラスト確保も困難になるため

## Spacing & Layout

### Spacing Scale

**原則:** 4px基準の密なリズム。業務ツールでは余白の広さより情報の近接性が重要。関連する要素は近く、無関係な要素は遠くに配置する（近接の法則）。

| Token | Value | Use case |
|---|---|---|
| `space-1` | 4px | アイコンとラベルの間、バッジ内パディング |
| `space-2` | 8px | 関連する要素のグループ内、テーブルセルのパディング |
| `space-3` | 12px | フォームフィールド間、リストアイテム間 |
| `space-4` | 16px | カード内パディング、ツールバーの左右パディング |
| `space-5` | 20px | カード間のギャップ |
| `space-6` | 24px | セクション内の要素間 |
| `space-8` | 32px | セクション間、ページヘッダーとコンテンツの間 |
| `space-10` | 40px | ページ上部のマージン |

### Layout Philosophy

#### Content-First Rule
コンテンツ領域は常に最大幅を確保する。ナビゲーションやツールバーは固定幅で、残りすべてをコンテンツに割り当てる。

- サイドバー: 固定幅 240px（折りたたみ時 56px）
- コンテンツ領域: 残り全幅（max-widthは設けない）
- 右サイドパネル（詳細表示）: 固定幅 400px、必要時のみ表示

**Exception:** 設定画面ではコンテンツ最大幅を 720px に制限する。理由: フォーム入力は幅が広すぎると視線の移動距離が長くなり、操作効率が下がるため。

#### Grid System
- テーブルビュー: 単一カラム、フル幅
- カードビュー: `auto-fill, minmax(320px, 1fr)` のレスポンシブグリッド
- ダッシュボード概要: 12カラムグリッド、ウィジェットは `colspan` で幅を調整

### Surface Hierarchy

| Level | Surface | Border | Use case | Reasoning |
|---|---|---|---|---|
| 0 | `--color-surface` | なし | ページ背景 | 最下層。他の要素の土台 |
| 1 | `--color-surface-raised` | `--color-border` 1px | カード、テーブル、パネル | 情報のグルーピング。影ではなくボーダーで区切る |
| 1.5 | `--color-surface-raised` | `--color-primary` 2px left | 選択中・アクティブなカード | 選択状態の明示。左ボーダーで控えめに |
| 2 | `--color-surface-raised` | shadow-sm | ドロップダウン、ポップオーバー、ツールチップ | 一時的な浮遊要素。影で浮きを表現 |
| 3 | `--color-surface-raised` | shadow-md + overlay | モーダル、コマンドパレット | ユーザーの注意を占有する最上位層 |

#### Elevation Tokens

| Token | Value | Use case |
|---|---|---|
| `shadow-sm` | `0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04)` | ドロップダウン、ポップオーバー |
| `shadow-md` | `0 4px 12px rgba(0,0,0,0.10), 0 2px 4px rgba(0,0,0,0.04)` | モーダル |
| `overlay` | `rgba(15, 23, 42, 0.4)` | モーダルの背景オーバーレイ |

## Component Patterns

### Selection Guide

**選択肢の提示:**
- 2-3個の排他的選択 → SegmentedControl（ビュー切替: リスト/ボード/ガント等）
- 4-7個 → Select。理由: 認知負荷の閾値
- 8個以上 → Combobox（検索付き）。理由: スクロールより検索が速い
- 複数選択 → Checkbox group（5個以下）/ Multi-select Combobox（6個以上）

**フィードバック:**
- 成功・軽微な通知 → Toast（4秒で自動消去、右上配置）
- 破壊的操作の確認 → ConfirmDialog（「削除」ボタンは danger スタイル）
- フィールドレベルのエラー → Inline Error（フィールド直下、即時表示）
- バッチ操作の結果 → Banner（ページ上部、手動で閉じる）

**ナビゲーション:**
- メインセクション → 左サイドバー（固定、折りたたみ可能）
- セクション内の切り替え → Tab（5個以下）
- 階層の位置表示 → Breadcrumb
- 頻用アクション・ページ遷移 → CommandPalette（Cmd+K）

**データの詳細表示:**
- 一覧から詳細を見る → サイドパネル（右スライド、400px固定幅）。理由: 一覧を維持しながら詳細を確認できる
- 編集が必要 → フルページ遷移。理由: 編集には十分な作業領域が必要
- 軽微な情報確認 → ツールチップまたはポップオーバー

### Composition Rules

#### Card-Flat Rule
Card 内に Card をネストしない。代わりにセクションをボーダーで区切る。理由: ネストされたカードは視覚的階層を複雑にし、情報密度が下がるため。

#### Modal Escape Rule
Modal 内で別の Modal を開かない。代わりに Modal 内コンテンツを差し替えるか、元の Modal を閉じて新しい Modal を開く。理由: 重なったモーダルはユーザーの現在位置を見失わせるため。

#### Table-First Rule
5件以上の構造化データはテーブルで表示する。カードグリッドはプロジェクト概要など視覚的な識別が重要な場面のみ使用する。理由: PMの主要タスクはデータの走査と比較であり、テーブルが最も効率的なため。

**Exception:** カンバンボード（ボードビュー）はカードで表示する。理由: ドラッグ&ドロップによるステータス変更が主要操作であり、カードがその操作に適しているため。

### State Handling

**原則:** すべてのインタラクティブ要素は5状態を持つ。状態変化は控えめに、かつ確実に視認できること。

| State | Visual Change | Transition | Reasoning |
|---|---|---|---|
| Default | — | — | 基準状態 |
| Hover | 背景色を1段階暗く (`--color-surface-inset`) | 120ms ease-out | 即応感。遅すぎると鈍く感じる |
| Focus | `--color-primary` のフォーカスリング (2px, offset 2px) | 0ms（即時） | キーボード操作の現在位置を明示 |
| Active | 背景色をさらに1段階暗く、scale(0.98) | 80ms ease-in | クリックの確実な応答感 |
| Disabled | opacity 0.5, cursor: not-allowed | なし | 操作不可の明示。tooltipで理由を表示 |

#### Loading State Rule
データ取得中は Skeleton を表示する。Spinner は使わない。理由: Skeleton はレイアウトを維持し、読み込み完了後のレイアウトシフトを防ぐため。

**Exception:** ボタンの送信中状態には Spinner を使う（ボタン内、16px）。理由: ボタンは固定サイズであり、Skeleton よりSpinner が自然なため。

### Density Guide

| Context | Row Height | Inner Padding | Font | Reasoning |
|---|---|---|---|---|
| Data table | 36px (compact) | `space-2` (8px) | `body-sm` (13px) | 大量データの走査。密度最優先 |
| Task list | 44px (comfortable) | `space-3` (12px) | `body-md` (14px) | タスク名の可読性を確保しつつ密度を維持 |
| Form | 40px input height | `space-3` (12px) | `body-md` (14px) | 入力フィールドの操作しやすさ |
| Dashboard card | — | `space-4` (16px) | `body-md` (14px) | KPIの視認性。カード内は若干ゆとりを持たせる |

#### Density Toggle Rule
テーブルビューにはユーザーが Compact / Comfortable を切り替えられるトグルを提供する。デフォルトは Compact。理由: PMごとに情報密度の好みが異なり、8時間使うツールでは個人設定が重要なため。

## Design Token References

### Token Format
すべてのトークンは CSS Custom Properties として定義する。

```css
:root {
  /* Color */
  --color-primary: #4F46E5;
  --color-primary-hover: #4338CA;
  --color-surface: #F8FAFC;
  --color-surface-raised: #FFFFFF;
  --color-surface-inset: #F1F5F9;
  --color-on-surface: #1E293B;
  --color-on-surface-secondary: #475569;
  --color-border: #E2E8F0;
  --color-danger: #DC2626;
  --color-warning: #D97706;
  --color-success: #059669;
  --color-info: #0284C7;

  /* Typography */
  --font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-size-xl: 1.5rem;
  --font-size-lg: 1.25rem;
  --font-size-md: 1rem;
  --font-size-base: 0.875rem;
  --font-size-sm: 0.8125rem;
  --font-size-xs: 0.75rem;

  /* Spacing */
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 20px;
  --space-6: 24px;
  --space-8: 32px;
  --space-10: 40px;

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-full: 9999px;

  /* Shadow */
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
  --shadow-md: 0 4px 12px rgba(0,0,0,0.10), 0 2px 4px rgba(0,0,0,0.04);
  --overlay: rgba(15, 23, 42, 0.4);
}
```
