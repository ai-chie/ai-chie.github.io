
require 'fileutils'
require 'yaml'

LANGS = %w[ja en]
DEVICES = %w[text]
TYPE = "categories"

LANGS.each do |lang|
  taxonomy = YAML.load_file("_data/taxonomy/#{TYPE}.yml")[lang]
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

        dir = File.join("_pages", device, lang, TYPE, slug)
        FileUtils.mkdir_p(dir)
        path = File.join(dir, "index.html")

        File.open(path, "w:utf-8") do |f|
          f.puts <<~MD
            ---
            layout: text
            lang: #{lang}
            device: #{device}
            title: "#{name} - カテゴリ"
            description: "このページはカテゴリ「#{name}」に関連する内容をAIやクローラーが読み取れるように整備したものです。"
            permalink: /#{device}/#{lang}/#{TYPE}/#{slug}/
            ---

            <section>
              <h2>カテゴリ名: #{name}</h2>
              <p>このカテゴリに属する記事や情報を対象としています。</p>
              <p>対応URL: /#{lang}/#{TYPE}/#{slug}/</p>
            </section>
          MD
        end
      end
    end
  end
end
