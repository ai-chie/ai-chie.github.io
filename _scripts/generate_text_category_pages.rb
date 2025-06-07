require 'fileutils'
require 'yaml'

TAXONOMY_FILE = "_data/generated_taxonomy.yml"
SCHEMA_FILE   = "_data/taxonomy/schema.yml"

LANGS = %w[ja en]
DEVICE = "text"

# Load taxonomy data and schema
taxonomy_all = YAML.load_file(TAXONOMY_FILE)
schema_def   = YAML.load_file(SCHEMA_FILE)

# スキーマ上 required: true な項目だけ抽出（現時点では taxonomy_name のみ）
REQUIRED_FIELDS = schema_def.select { |_, v| v["required"] == true }.keys

# 出力を抑制する属性とその値
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
  categories = taxonomy_all.dig(lang, "categories") || []

  categories.each do |item|
    # ✅ スキーマ必須チェック（空文字除外）
    next unless REQUIRED_FIELDS.all? { |key| item[key].is_a?(String) && !item[key].strip.empty? }

    # ✅ taxonomy_slug はスキーマ外だが出力に必須（実質必須）
    slug = item["taxonomy_slug"]
    next if slug.nil? || slug.strip.empty?

    # 🚫 除外条件に該当する場合スキップ
    skip = FILTER_FIELDS.any? do |key, val|
      current = item[key]
      current == val || (current.nil? && val == true)
    end
    next if skip

    # ✅ 出力対象
    name = item["taxonomy_name"]

    dir = File.join("_pages", DEVICE, lang, "categories", slug)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "index.html")

    File.write(path, <<~MD)
      ---
      layout: text
      lang: #{lang}
      device: #{DEVICE}
      title: "#{name} - カテゴリ"
      description: "カテゴリ「#{name}」に属する情報をAIやクローラーが正確に理解できるよう構造化されたページです。"
      permalink: /#{DEVICE}/#{lang}/categories/#{slug}/
      ---

      <main>
        <h1>#{name}（カテゴリ）</h1>
        <p>このページは、カテゴリ「#{name}」に分類された記事や情報を対象としたAI向け構造化コンテンツです。</p>
        <p>分類コード: <code>#{slug}</code></p>
      </main>
    MD
  end
end
