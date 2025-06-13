# Jekyll構成統一設計案（taxonomy/_pages統合 + _posts共通化 + text出力統一）【修正版】

本ドキュメントは、現在のコードベース構成および要望に基づき、taxonomyや投稿出力の最適構成を定義するものです。

---

## ✅ 全体方針（概要）

| 項目 | 設計方針 |
|------|----------|
| `text/` | スクリプト出力を廃止し、_pages/{device}/{lang}/... にJekyllテンプレートとして統一 |
| `taxonomy/` | _generated/廃止 → _pages/{device}/{lang}/{type}/{slug}.md に静的統合 |
| `_pages/`構成 | 現状維持（device/lang/type/...階層構成） |
| `_posts/` | `ja`/`en`サブディレクトリを廃止 → _posts/直下に集約し、Front Matterで分岐制御 |
| 出力分岐 | `layout_*`, `permalink_*` を Front Matter で記述し、端末・言語対応を統合管理 |

---

## ✅ _posts/ 投稿ファイル構成例（統合形式）

```
_posts/
├── 2025-06-08-example.ja.md
├── 2025-06-08-example.en.md
```

```yaml
# _posts/2025-06-08-example.ja.md の Front Matter（スキーマ定義：_data/post/post_schema.yml）
---
# _data/post/post_schema.yml
id: yyyymmddhhmm+0900_uuid_ja
title: サンプル記事（日本語）
description: サンプル記事の説明
authors: [author1, author2]
lang: ja
categories: [テスト, テスト２]
tags: [サンプル, 記事]
created_timestamp: yyyymmddhhmm
modified_timestamp: yyyymmddhhmm
images: [image1, imgae2]
related_posts_lang: [id1, id2]
priority: 5
featured: true
draft: false
device: # 自動複製出力時に自動設定
output_pc: true # trueで自動複製出力
layout: post
permalink: /pc/ja/example/
output_mobile: true
layout_mobile: mobile-post
permalink_mobile: /mobile/ja/example/
output_text: true
layout_text: text-post
permalink_text: /text/ja/example/
---
```

---

## ✅ taxonomyページ構成（_pages に静的統合）

| パス | 内容 |
|------|------|
| `_pages/text/ja/categories/test.md` | text構成 taxonomyページ |
| `_pages/pc/en/tags/sample.md`       | PC構成 英語タグページ |
| `_pages/mobile/ja/index.md` | モバイルの日本語のトップページ：ウエルカムメッセージ＋カテゴリとタグの一覧など |

```yaml
# _pages/text/ja/categories/test.md
---
# _data/taxonomy/{type}.yml, _data/taxonomy/taxonomy_schema.yml
device: # 設定がない場合はpathから取得
lang: ja # 設定がない場合はpathから取得
type: # 設定がない場合はpathから取得
slug: test
name: # 設定がない場合は_data/taxonomy/{type}.ymlから取得（slugで照合）
description: # 設定がない場合は_data/taxonomy/{type}.ymlから取得（slugで照合）
icon: ""
priority: 5
featured: true
output_pc: true # trueで出力。{device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
layout: text-taxonomy # {device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
permalink: /pc/ja/categories/test/ # {device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
output_mobile: true
layout_mobile: text-taxonomy
permalink_mobile: /mobile/ja/categories/test/
output_text: true
layout_text: text-taxonomy
permalink_text: /text/ja/categories/test/
---
```

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
| `mobile-taxonomy`     | モバイル向けtaxonomy個別ページ（slugごと） |
| `mobile-taxonomy-index` | モバイル向けtaxonomy一覧ページ（type単位） |
| `text-taxonomy`     | AI/text向けtaxonomy個別ページ（slugごと） |
| `text-taxonomy-index` | AI/text向けtaxonomy一覧ページ（type単位） |

---

## ✅ 自動生成の位置づけと目的（補足）

| 種別 | 内容 |
|------|------|
| `layout_*` + `permalink_*` | `_posts/*.md` に出力設定を記述する方法（論理構造） |
| 自動展開スクリプト | `_posts/*.md` を元に `_pages/text/...` に `.md` を複製出力（物理展開） |
| 主目的 | 投稿は1ファイルで管理しつつ、出力は device/lang に分岐させるため |

---

## ✅ 仕様項目と推奨値

| 項目 | 推奨値 | 理由 |
|------|--------|------|
| 投稿のlang判定 | `lang: ja/en` をFront Matterに明記 | 多言語切替や一覧抽出に必要 |
| taxonomy定義管理 | `_data/taxonomy/{categories,tags}.yml`, `_data/taxonomy/taxonomy_schema.yml` | 表示名・説明・色などを集中管理 |
| post定義管理 | `_data/post/post_schema.yml` | 属性を定義 |
| permalink設計 | `/text/{lang}/...`, `/pc/{lang}/...` | 出力ルートを一貫して管理 |
| `_config.yml` defaults | 投稿レベルで `layout`, `lang`, `permalink` を補完 | 記述の冗長性削減・共通化 |
| layout内での device/lang 判定 | `page.device`, `page.lang` の分岐使用 | 汎用テンプレートの最小化に有効 |

---

## ✅ 今後の移行支援

- ✅ `_posts/*.md` → 各デバイス出力用 `_pages/` テンプレート展開スクリプト
- ✅ `_includes/` テンプレートの text/pc/mobile 共通化

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

この構成により、**投稿は統合管理されながら、出力は完全に device/lang に分岐可能**となり、保守性・CI連携・i18n対応のすべてにおいて最適化されます。
