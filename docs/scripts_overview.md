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