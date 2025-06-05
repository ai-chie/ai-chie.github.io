require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/taxonomy/categories.yml"
LANGS   = %w[ja en]
DEVICES = %w[text]

taxonomy_data = YAML.load_file(TAXONOMY_FILE)

LANGS.each do |lang|
  taxonomy = taxonomy_data[lang]
  next unless taxonomy

  DEVICES.each do |device|
    taxonomy.each do |group_name, group_data|
      group_data["items"].each do |item|
        name  = item["taxonomy_name"]
        slug  = item["taxonomy_slug"]
        draft = item["taxonomy_draft"] || false
        hidden = item["taxonomy_hidden"] || false
        private_ = item["taxonomy_private"] || false
        audience = item["taxonomy_audience"] || "external"

        next if name.nil? || slug.nil? || draft || hidden || private_ || audience != "external"

        dir = File.join("_pages", device, lang, "categories", slug)
        FileUtils.mkdir_p(dir)
        path = File.join(dir, "index.html")

        File.write(path, <<~MD)
          ---
          layout: text
          lang: #{lang}
          device: #{device}
          title: "#{name} - カテゴリ"
          description: "このページはカテゴリ「#{name}」に関連する内容をAIやクローラーが読み取れるように整備したものです。"
          permalink: /#{device}/#{lang}/categories/#{slug}/
          ---

          <section>
            <h2>カテゴリ名: #{name}</h2>
            <p>このカテゴリに属する記事や情報を対象としています。</p>
            <p>対応URL: /#{lang}/categories/#{slug}/</p>
          </section>
        MD
      end
    end
  end
end
