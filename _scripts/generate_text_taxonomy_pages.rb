require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/generated_taxonomy.yml"
SCHEMA_FILE   = "_data/taxonomy/schema.yml"
LANG_FILE     = "_data/lang.yml"

LANGS = %w[ja en]
DEVICE = "text"
TYPES = %w[categories tags]

taxonomy_all = YAML.load_file(TAXONOMY_FILE)
schema_def   = YAML.load_file(SCHEMA_FILE)
lang_labels  = YAML.load_file(LANG_FILE)

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

    label = lang_labels.dig("taxonomy_label", type, lang) || type.capitalize
    desc_template = lang_labels.dig("taxonomy_description_template", lang) || "%{label}「%{name}」の説明ページです。"

    entries.each do |item|
      name_obj = item["taxonomy_name"]
      next unless name_obj.is_a?(String) || (name_obj.is_a?(Hash) && name_obj[lang].is_a?(String) && !name_obj[lang].strip.empty?)
      name = name_obj.is_a?(Hash) ? name_obj[lang] : name_obj

      slug = item["taxonomy_slug"]
      next if slug.nil? || slug.strip.empty?

      skip = FILTER_FIELDS.any? do |key, val|
        current = item[key]
        current == val || (current.nil? && val == true)
      end
      next if skip

      description = desc_template.gsub("%{label}", label).gsub("%{name}", name)

      dir = File.join("_pages", DEVICE, lang, type, slug)
      FileUtils.mkdir_p(dir)
      path = File.join(dir, "index.html")

      File.write(path, <<~MD)
        ---
        layout: text
        lang: #{lang}
        device: #{DEVICE}
        title: "#{name} - #{label}"
        description: "#{description}"
        permalink: /#{DEVICE}/#{lang}/#{type}/#{slug}/
        ---

        <main>
          <h1>#{name}（#{label}）</h1>
          <p>#{description}</p>
          <p>分類コード: <code>#{slug}</code></p>
        </main>
      MD
    end
  end
end
