require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/generated_taxonomy.yml"
LANG_FILE     = "_data/lang.yml"

LANGS = %w[ja en]
DEVICE = "text"
TYPES = %w[categories tags]

taxonomy_all = YAML.load_file(TAXONOMY_FILE)
lang_labels  = YAML.load_file(LANG_FILE)

LANGS.each do |lang|
  TYPES.each do |type|
    entries = taxonomy_all.dig(lang, type) || []
    next if entries.empty?

    label = lang_labels.dig("taxonomy_label", type, lang) || type.capitalize
    index_title = lang_labels.dig("taxonomy_index_title", type, lang) || "#{label}一覧"
    index_intro = lang_labels.dig("taxonomy_index_intro", type, lang) || "#{label}の一覧ページです。"

    list_html = entries.map do |item|
      slug = item["taxonomy_slug"]
      name_obj = item["taxonomy_name"]
      name = name_obj.is_a?(Hash) ? name_obj[lang] : name_obj
      count = item["count"] || 0
      "<li><a href="/#{DEVICE}/#{lang}/#{type}/#{slug}/">#{name}</a> <span>(#{count})</span></li>"
    end.join("\n")

    dir = File.join("_pages", DEVICE, lang, type)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "index.html")

    File.write(path, <<~MD)
      ---
      layout: text
      lang: #{lang}
      device: #{DEVICE}
      title: "#{index_title}"
      description: "#{index_intro}"
      permalink: /#{DEVICE}/#{lang}/#{type}/
      ---

      <main>
        <h1>#{index_title}</h1>
        <p>#{index_intro}</p>
        <ul>
        #{list_html}
        </ul>
      </main>
    MD
  end
end
