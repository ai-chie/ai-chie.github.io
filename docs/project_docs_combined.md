# File: structure_guide.md

# 📘 Jekyll プロジェクト構成ガイド（Structure Guide）

本プロジェクトは、多言語・マルチデバイス対応、かつAI・クローラーに最適化された静的サイトをGitHub Pages + Jekyllで構築することを目的とします。

## 📁 ディレクトリ構成（概要）

- `_posts/{lang}/{uuid}/`：投稿（UUIDディレクトリ単位、各投稿に1 .md）
- `_pages/{device}/{lang}/`：出力ページ（トップ・カテゴリ・タグ・投稿）
- `_generated/{device}/{lang}/`：自動生成された分類ページ（カテゴリ・タグslug別）
- `_scripts/`：自動生成用Rubyスクリプト
- `_layouts/`, `_includes/`：テンプレート群
- `_data/`：カテゴリ・タグ定義とスキーマ
- `.github/workflows/`：GitHub Actionsワークフロー
- `sitemap.xml`, `sitemap_text.xml`, `robots.txt`：SEO/AI向けメタ情報

## 🌐 モード構成

- `pc`: 人間のPC閲覧向け
- `mobile`: スマートフォン表示用
- `text`: AI/クローラー向け最適化HTML

## 🔤 対応言語

- `ja`（日本語）
- `en`（英語）

## 🔧 今後の拡張予定

- `text/en/` 出力対応
- canonical/alternate対応
- `mobile/{lang}/` における分類ページの専用出力（目的に応じて検討）
- `_pages/pc/{lang}/{uuid}/index.html` 出力対応（必要に応じて）

---

# File: scripts_overview.md

# 🔄 Ruby スクリプト仕様（_scripts/）

| スクリプト名                         | 処理対象            | 出力先                        |
|--------------------------------------|---------------------|-------------------------------|
| generate_text_posts.rb              | `_posts/{lang}/{uuid}/` | `_pages/text/{lang}/{uuid}/index.html` |
| generate_text_category_index.rb     | `_data/taxonomy/`   | `_pages/text/{lang}/categories/index.html` |
| generate_text_category_pages.rb     | categories          | `_pages/text/{lang}/categories/{slug}/index.html` |
| generate_text_tag_index.rb          | `_data/taxonomy/`   | `_pages/text/{lang}/tags/index.html` |
| generate_text_tag_pages.rb          | tags                | `_pages/text/{lang}/tags/{slug}/index.html` |

## フロー概要

- Front MatterからUUID・カテゴリ・タグ・言語を抽出
- 該当分類に分類された投稿の一覧を出力
- 投稿は `_posts/{lang}/{uuid}/post.md` 構成で読み込み

---

# File: workflow_guide.md

# ⚙ GitHub Actions ワークフロー仕様

## 現在のワークフロー

### 📄 generate-text-pages.yml

- トリガー：`_posts/{lang}/**/*.md`, `_data/taxonomy/**`, `_scripts/**`
- 処理内容：
  - Rubyスクリプトを使って `/text/{lang}/` 以下の各ページを再生成
- 出力対象：
  - `_pages/text/{lang}/index.html`
  - `_pages/text/{lang}/categories/index.html`
  - `_pages/text/{lang}/categories/{slug}/index.html`
  - `_pages/text/{lang}/tags/index.html`
  - `_pages/text/{lang}/tags/{slug}/index.html`
  - `_pages/text/{lang}/{uuid}/index.html`

## 将来拡張案

- `generate-pc-pages.yml`
- `generate-mobile-pages.yml`
- `_pages/pc/{lang}/{uuid}/index.html` 出力対応

---

# File: taxonomy_schema_spec.md

# 🧩 taxonomy schema.yml 仕様

## 属性一覧と用途

| 属性名               | 型     | 説明                                        |
|----------------------|--------|---------------------------------------------|
| taxonomy_name        | string | 表示名（slugにも使用）                      |
| taxonomy_hidden      | bool   | 非表示にする場合 true                       |
| taxonomy_draft       | bool   | 下書きとして未公開扱いにする                |
| taxonomy_private     | bool   | 非公開カテゴリ（管理者のみなど）            |
| taxonomy_featured    | bool   | 注目カテゴリ/タグ                          |
| taxonomy_beta        | bool   | ベータ扱いでUIにラベル表示される            |
| taxonomy_deprecated  | bool   | 廃止予定としてマークされる                  |
| taxonomy_audience    | string | 対象（internal / external）                |
| taxonomy_color       | string | 表示用カラーコード                         |
| taxonomy_icon        | string | 表示用アイコン                             |
| taxonomy_link        | string | カスタムリンクを張る場合                    |
| taxonomy_description | string | カテゴリやタグの説明文                     |

## データ構造（例）

```yaml
AI:
  items:
    - name: "GPT"
      taxonomy_description: "OpenAIの大規模言語モデル"
      taxonomy_icon: "🧠"
```

---

# File: build_instructions.md

# 🛠 Jekyll ビルド & プレビュー手順書

## ローカルビルド手順

```bash
bundle install
bundle exec jekyll build
```

### モード別ビルド

```bash
JEKYLL_ENV=production bundle exec jekyll build --config _config.yml,_config_text.yml
```

## サーバープレビュー

```bash
bundle exec jekyll serve --livereload
```

## ビルド対象構成ファイル（例）

- `_config.yml`（デフォルト）
- `_config_text.yml`（text/モード用）
- `_config_mobile.yml`（モバイル表示用）

---

# File: project_purpose_notes.md

# 📐 プロジェクト目的・設計思想（Project Purpose & Design Philosophy）

本プロジェクトは、次の3点を中核目的として設計されています：

## 1. 🎯 AI / クローラー向けの完全対応

- ChatGPTなどのAIツールが読み取れる構造のHTML出力（textモード）を提供
- JavaScript非依存、構造化・セマンティックなHTMLによるアクセシビリティ向上
- 検索エンジンにも明示的に見えるURL・コンテンツ・分類構造を維持

## 2. 🧭 ユーザーUXの最適化

- PC / モバイル端末ごとに適した見た目と操作性を実現
- メディアクエリによるレスポンシブ対応を基本とし、必要に応じて分岐

## 3. ⚙ 自動化と再現性

- GitHub Actionsによる完全自動構築
- Rubyスクリプトによる分類ページの自動生成（カテゴリ/タグ/投稿）
- YAMLとJSONでのデータ構造の明示化とスキーマ管理

---

## 🆕 構造変更の理由（2025年6月更新）

- `_posts/{lang}/{uuid}/post.md` 構成へ移行し、投稿単位で一意なディレクトリを採用
    - タイトルとタイムスタンプによる固有ID
    - 対応するtextページも `{uuid}/index.html` として管理しやすくなる
- Jekyll標準の投稿管理機能は維持しつつ、text用出力との整合性を確保

---

## 🔮 将来展望

- canonical/alternate 対応による多モードSEO統一
- `_pages/pc/{lang}/{uuid}/index.html` 導入によるページ制御強化
- モバイル向け分類ページの最適化と分岐導入（必要に応じて）

---