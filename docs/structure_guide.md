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