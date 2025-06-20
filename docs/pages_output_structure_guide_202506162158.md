# `_pages/` 出力構造の標準設計ドキュメント

## ▶ 目的
`_pages/` 配下に置かれる taxonomy と post のページ生成結果について、構造の解析とディレクトリ分配ポリシーを明斎にする。

## ▶ 概要

| 端末 / 言語 / タイプ | taxonomy | post |
|----------------|-----------|-------|
| PC 日本語     | `_pages/pc/ja/categories/`, `_pages/pc/ja/tags/` | `_pages/pc/ja/*.md` |
| Mobile 英語   | `_pages/mobile/en/categories/`, `_pages/mobile/en/tags/` | `_pages/mobile/en/*.md` |
| Text 日本語    | `_pages/text/ja/categories/`, `_pages/text/ja/tags/` | `_pages/text/ja/*.md` |

## ▶ ディレクトリ構造

```
_pages/
  ├▲ pc/
  │   ├▲ ja/
  │   │   ├▲ categories/      # taxonomy
  │   │   ├▲ tags/            # taxonomy
  │   │   └▲ *.md             # post
  │   └▲ en/
  │       ...
  ├▲ mobile/
  │   ├▲ ja/
  │   │   ...
  │   └▲ en/
  └▲ text/
      ├▲ ja/
      └▲ en/
```

## ▶ taxonomy の出力
### 出力元
- `_data/taxonomy/categories.yml`
- `_data/taxonomy/tags.yml`
### schema
- `_data/taxonomy/taxonomy_schema.yml`
### 補足
- 1 post あたり: `device` 分の .md を `_pages/{device}/{lang}/{basename}.md`に出力
- layout, permalink は `output_layout_setting`, `output_permalink_setting` の各 device 値により生成

## ▶ post の出力
### 出力元
- `_posts/` 配下の markdown ファイル
### schema
- `_data/post/post_schema.yml`
### 補足
- 1 post あたり: `device` 分の .md を `_pages/{device}/{lang}/{basename}.md`に出力
- lang = ja/en はファイル側で明示
- device は `output_device` より multiple 出力

## ▶ 保存紙数
- taxonomy: type x device x lang x slug の結合だけ
- post: post x device 分
- taxonomy の方が *.md の紙数は多くなる

## ▶ 補足
- taxonomy は slug ごとに `categories/slug.md` として出力
- post は 基本として `basename.md` (例: `2025-05-30-example.ja.md`) の名前を残したまま

## ▶ 注意
- taxonomy の削除処理は dir 単位 (ファイル分野シギ)
- post の削除処理は *.md 単位 (文書単位シギ)
- 2者は `_pages/` 配下では相互に互いに削除しないように分離されている

