require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/taxonomy/tags.yml"
LANG = "ja"
TYPE = "tags"
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
        title: "#{name} - タグ"
        description: "このページはタグ「#{name}」に関連する内容をAIやクローラーが読み取れるように整備したものです。"
        ---

        <section>
          <h2>タグ名: #{name}</h2>
          <p>このタグに関連する記事やリソースを対象としています。</p>
          <p>対応URL: /ja/tags/#{slug}/</p>
        </section>
      MD
    end
  end
end

