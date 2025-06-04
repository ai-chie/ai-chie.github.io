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