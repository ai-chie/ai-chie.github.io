require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/taxonomy/categories.yml"
LANG = "ja"
TYPE = "categories"
OUTPUT_ROOT = "_pages/text/#{LANG}/#{TYPE}"

taxonomy = YAML.load_file(TAXONOMY_FILE)[LANG]

taxonomy.each do |group_name, group_data|
  group_data["items"].each do |item|
    name  = item["taxonomy_name"]
    slug  = item["taxonomy_slug"]
    draft = item["taxonomy_draft"] || false
    hidden = item["taxonomy_hidden"] || false
    private_ = item["taxonomy_private"] || false
    audience = item["taxonomy_audience"] || "external"

    next if name.nil? || slug.nil? || draft || hidden || private_ || audience != "external"

    dir = File.join(OUTPUT_ROOT, slug)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "index.html")

    File.open(path, "w:utf-8") do |f|
      f.puts <<~MD
        ---
        layout: text
        lang: #{LANG}
        device: text
        title: "#{name} - カテゴリ"
        description: "このページはカテゴリ「#{name}」に関連する内容をAIやクローラーが読み取れるように整備したものです。"
        permalink: /text/ja/categories/#{slug}/index.html
        ---

        <section>
          <h2>カテゴリ名: #{name}</h2>
          <p>このカテゴリに属する記事や情報を対象としています。</p>
          <p>対応URL: /ja/categories/#{slug}/</p>
        </section>
      MD
    end
  end
end

