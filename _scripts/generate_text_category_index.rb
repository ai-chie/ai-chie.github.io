require 'fileutils'

output_path = "_pages/text/ja/categories/index.html"
FileUtils.mkdir_p(File.dirname(output_path))

File.open(output_path, "w:utf-8") do |f|
  f.puts <<~TEXT
    ---
    layout: text
    lang: ja
    device: text
    title: "カテゴリ一覧 - テキスト版"
    description: "このページはAIや検索エンジン向けのカテゴリ一覧ページです。"
    ---

    {% include taxonomy-list-text.html type="categories" lang="ja" %}
  TEXT
end

