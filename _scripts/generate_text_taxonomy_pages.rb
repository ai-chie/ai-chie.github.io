require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/generated_taxonomy.yml"
SCHEMA_FILE   = "_data/taxonomy/schema.yml"

LANGS = %w[ja en]
DEVICE = "text"
TYPES = %w[categories tags]

# 言語別表示ラベル
LABELS = {
  "categories" => { "ja" => "カテゴリ", "en" => "Category" },
  "tags"       => { "ja" => "タグ",     "en" => "Tag" }
}

taxonomy_all = YAML.load_file(TAXONOMY_FILE)
schema_def   = YAML.load_file(SCHEMA_FILE)

REQUIRED_FIELDS = schema_def.select { |_, v| v["required"] == true }.keys

FILTER_FIELDS = {
  "taxonomy_draft"        => true,
  "taxonomy_hidden"       => true,
  "taxonomy_private"      => true,
  "taxonomy_admin_only"   => true,
  "taxonomy_audience"     => "internal",
  "taxonomy_deprecated"   => true,
  "taxonomy_beta"         => true
}

LANGS.each do |lang|
  TYPES.each do |type|
    entries = taxonomy_all.dig(lang, type) || []
    label = LABELS.dig(type, lang) || type.capitalize

    entries.each do |item|
      next unless REQUIRED_FIELDS.all? { |key| item[key].is_a?(String) && !item[key].strip.empty? }

      slug = item["taxonomy_slug"]
      next if slug.nil? || slug.strip.empty?

      skip = FILTER_FIELDS.any? do |key, val|
        current = item[key]
        current == val || (current.nil? && val == true)
      end
      next if skip

      name = item["taxonomy_name"]

      dir = File.join("_pages", DEVICE, lang, type, slug)
      FileUtils.mkdir_p(dir)
      path = File.join(dir, "index.html")

      File.write(path, <<~MD)
        ---
        layout: text
        lang: #{lang}
        device: #{DEVICE}
        title: "#{name} - #{label}"
        description: "#{label}「#{name}」に属する情報をAIやクローラーが正確に理解できるよう構造化されたページです。"
        permalink: /#{DEVICE}/#{lang}/#{type}/#{slug}/
        ---

        <main>
          <h1>#{name}（#{label}）</h1>
          <p>このページは、#{label}「#{name}」に分類された記事や情報を対象としたAI向け構造化コンテンツです。</p>
          <p>分類コード: <code>#{slug}</code></p>
        </main>
      MD
    end
  end
end
