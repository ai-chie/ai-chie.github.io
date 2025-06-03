require 'fileutils'

output_path = "_pages/text/ja/tags/index.html"
FileUtils.mkdir_p(File.dirname(output_path))

File.open(output_path, "w:utf-8") do |f|
  f.puts <<~TEXT
    ---
    layout: text
    lang: ja
    device: text
    title: "タグ一覧 - テキスト版"
    description: "このページはAIや検索エンジン向けのタグ一覧ページです。"
    ---

    {% include taxonomy-list-text.html type="tags" lang="ja" %}
  TEXT
end

