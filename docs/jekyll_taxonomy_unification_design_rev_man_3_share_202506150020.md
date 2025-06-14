# Jekyll構成統一設計案（taxonomy/_pages統合 + _posts共通化 + text出力統一）【修正版】

本ドキュメントは、現在のコードベース構成および要望に基づき、taxonomyや投稿出力の最適構成を定義するものです。

---

## ✅ 全体方針（概要）

| 項目 | 設計方針 |
|------|----------|
| `text/` | スクリプト出力を廃止し、_pages/{device}/{lang}/... にJekyllテンプレートとして統一 |
| `_pages/`構成 | 現状維持（device/lang/type/...階層構成） |
| `_posts/` | `ja`/`en`サブディレクトリを廃止 → _posts/直下に集約し、Front Matterで分岐制御 |
| `_posts/`出力分岐 | Front Matter の記述で、端末・言語対応を統合管理 |
| `taxonomy/` | _generated/廃止 → _pages/{device}/{lang}/{type}/{slug}.md に統合 |
| `taxonomy/`分岐出力 | `_data/`を元に`_pages/`taxonomyを分岐出力 |

---

## ✅ _posts/ 投稿ファイル構成例（統合形式）

```
_posts/
├── 2025-06-08-example.ja.md
├── 2025-06-08-example.en.md
```
# _posts/のFront Matter

`_posts/`のFront Matterのスキーマ定義：`_data/post/post_schema.yml`
`_posts/`のFront Matterの例：`2025-05-30-example.ja.md`

---

## ✅ taxonomyページ構成（_pages に統合）

| パス | 内容 |
|------|------|
| `_pages/text/ja/categories/test.md` | text構成 taxonomyページ |
| `_pages/pc/en/tags/sample.md`       | PC構成 英語タグページ |

---

## ✅ デバイス別・言語別のトップページ

`_pages/mobile/ja/index.md` | モバイルの日本語のトップページ：ウエルカムメッセージ + カテゴリとタグの一覧など

---

## ✅ layout 設計（テンプレートの役割分担）

| layout名 | 用途 |
|----------|------|
| `base`         | ベースレイアウト |
| `default`      | PC向け。baseを継承 |
| `post`         | PC向け投稿記事（通常）。defaultを継承 |
| `text-post`    | AI/text向け投稿記事 |
| `mobile-post`  | モバイル向け投稿記事 |
| `taxonomy`     | taxonomy個別ページ（slugごと） |
| `taxonomy-index` | taxonomy一覧ページ（type単位） |

---

## ✅ 記事自動生成の位置づけと目的（補足）

| 種別 | 内容 |
|------|------|
| 出力分岐 | `post_schema.yml`（Front Matterスキーマ定義・デフォルト値）、`_posts/*.md`のFront Matterに出力設定を記述する方法（論理構造） |
| 自動展開スクリプト | `post_schema.yml`と`_posts/*.md`を元に_pages/{device}/{lang}に`.md`を複製出力（物理展開） |
| 主目的 | 投稿は1ファイルで管理しつつ、出力はdevice/langに分岐させるため |

---

## ✅ taxonomy自動生成の位置づけと目的（補足）

| 種別 | 内容 |
|------|------|
| 出力分岐 | `taxonomy_schema.yml`（taxonomy属性スキーマ定義・デフォルト値）、type{categories,tags}.ymlに出力設定を記述する方法（論理構造） |
| 自動展開スクリプト | `taxonomy_schema.yml`とtype{categories/tags}.ymlを元に_pages/{device}/{lang}/{type}/に`.md`を複製出力（物理展開） |
| 主目的 | taxonomyを`_data/`で管理しつつ、出力は device/lang/typeに分岐させるため |

---

## ✅ 仕様項目と推奨値

| 項目 | 推奨値 | 理由 |
|------|--------|------|
| 投稿のlang判定 | `lang: ja/en` をFront Matterに明記 | 多言語切替や一覧抽出に必要 |
| taxonomy定義管理 | `_data/taxonomy/{categories,tags}.yml`, `_data/taxonomy/taxonomy_schema.yml` | 表示名・説明・色・自動出力設定などを集中管理 |
| post定義管理 | `_data/post/post_schema.yml` | 属性を定義 |
| permalink設計 | `/text/{lang}/...`, `/pc/{lang}/...` | 出力ルートを一貫して管理 |
| `_config.yml` defaults | 投稿レベルで `layout`, `lang`, `permalink` を補完 | 記述の冗長性削減・共通化 |
| layout内での device/lang 判定 | `page.device`, `page.lang` の分岐使用 | 汎用テンプレートの最小化に有効 |

---

## ✅ 今後の支援

- ✅ 各schema関連設定
- ✅ `_data/` → 各デバイス・各言語出力用 `_pages/`展開スクリプト
- ✅ `_posts/*.md` → 各デバイス出力用 `_pages/`展開スクリプト
- ✅ `_includes/`テンプレートの修正、最適化、text/pc/mobile共通化 or 分離支援
- ✅ `_layout/`設計、最適化

---

## ✅ 最終構成図（例）

```
_posts/
  2025-06-08-example.ja.md

_pages/
├── text/
│   └── ja/
│       └── categories/
│           └── test.md
├── pc/
│   └── ja/
│       └── categories/
│           └── test.md
├── mobile/
│   └── ja/
│       └── tags/
│           └── tag1.md
```

---
