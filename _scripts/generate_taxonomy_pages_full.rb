require 'fileutils'
require 'yaml'
require 'date'
require 'i18n'

# I18n transliteration for slugging
I18n.available_locales = [:en, :ja]

POSTS_DIR        = '_posts'
OUTPUT_ROOT      = '_generated'
LAYOUT           = 'default'
SCHEMA_PATH      = '_data/taxonomy/schema.yml'
TAXONOMY_YML     = '_data/generated_taxonomy.yml'
OVERRIDES_PATH   = '_data/slug_overrides.yml'
MISSING_OVERRIDES = '_data/missing_slug_overrides.yml'
DUPLICATES_PATH  = '_log/duplicate_slugs.yml'
GENERATED_SLUGS  = '_log/generated_slugs.yml'

# 読み込みまたは空ハッシュ
def load_yaml_safe(path)
  File.exist?(path) ? YAML.load_file(path) : {}
end

def normalize_slug(name, lang, type, overrides, generated, missing)
  overrides_for_lang = overrides.dig(lang, type.to_s) || {}
  return overrides_for_lang[name] if overrides_for_lang[name]

  # フォールバックで生成
  slug = I18n.transliterate(name.to_s).downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
  slug = slug.empty? ? name.to_s.parameterize : slug

  # ログ用に記録
  generated[lang][type.to_s][name] = slug
  missing[lang][type.to_s] << name unless missing[lang][type.to_s].include?(name)
  slug
end

def parse_front_matter(file_path)
  content = File.read(file_path)
  if content =~ /\A---\s*
(.*?)
---/m
    yaml = Regexp.last_match(1)
    YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
  else
    {}
  end
rescue Psych::SyntaxError => e
  warn "YAML parse error in #{file_path}: #{e.message}"
  {}
end

schema = load_yaml_safe(SCHEMA_PATH)
overrides = load_yaml_safe(OVERRIDES_PATH)
taxonomy = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }
generated_slugs = Hash.new { |h, k| h[k] = { 'categories' => {}, 'tags' => {} } }
missing_slugs = Hash.new { |h, k| h[k] = { 'categories' => [], 'tags' => [] } }
duplicates = Hash.new { |h, k| h[k] = { 'categories' => {}, 'tags' => {} } }
seen_slugs = Hash.new { |h, k| h[k] = { 'categories' => {}, 'tags' => {} } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      name = term.to_s.strip
      next if name.empty?
      taxonomy[lang][type] << name
      counts[lang][type][name] += 1
    end
  end
end

generated_data = {}

taxonomy.each do |lang, types|
  generated_data[lang] = {}

  types.each do |type, terms|
    key = type.to_s.chop
    items = {}

    terms.uniq.sort.each do |name|
      slug = normalize_slug(name, lang, type, overrides, generated_slugs, missing_slugs)

      # 重複検出
      if seen_slugs[lang][type].key?(slug)
        (duplicates[lang][type.to_s][slug] ||= []) << name
        next
      end
      seen_slugs[lang][type][slug] = name

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count' => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if %w[taxonomy_name taxonomy_slug].include?(attr) || meta['unused']
        item[attr] = meta['type'] == 'enum' ? (meta['values'].include?(meta['default']) ? meta['default'] : meta['values'].first) : meta['default']
      end

      items[slug] = item

      # 出力
      dir = "#{OUTPUT_ROOT}/#{lang}/#{type}/#{slug}.md"
      FileUtils.mkdir_p(File.dirname(dir))
      File.write(dir, <<~MD)
        ---
        layout: #{LAYOUT}
        title: #{type.to_s.capitalize.chop}: #{name}
        #{key}: #{name}
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---

        <h1>#{type.to_s.capitalize.chop}: #{name}</h1>
        <p>{{ site.data.taxonomy.#{type}.#{lang}['#{name}'].taxonomy_description | default: 'この#{type.to_s.chop}に関する記事を紹介します。' }}</p>

        {% assign posts = site.#{type}[page.#{key}] | where: 'lang', '#{lang}' | where_exp: 'post', 'post.hidden != true and post.draft != true' %}

        {% if posts.size > 0 %}
        <h2>おすすめ記事</h2>
        <ul>
        {% for post in posts limit: 2 %}
          <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
        {% endfor %}
        </ul>
        <h2>すべての記事</h2>
        <ul>
        {% for post in posts offset: 2 %}
          <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
        {% endfor %}
        </ul>
        {% else %}
        <p>現在この#{type.to_s.chop}に該当する記事はありません。</p>
        {% endif %}
      MD
    end

    generated_data[lang][type] = items.values
  end
end

FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated_data.to_yaml)
File.write(MISSING_OVERRIDES, missing_slugs.to_yaml)
File.write(DUPLICATES_PATH, duplicates.to_yaml)
File.write(GENERATED_SLUGS, generated_slugs.to_yaml)

puts "✅ taxonomy YAML 書き出し完了: #{TAXONOMY_YML}"
puts "🔎 重複slug: #{DUPLICATES_PATH}"
puts "🔧 自動生成slug: #{GENERATED_SLUGS}"
puts "📝 辞書未定義: #{MISSING_OVERRIDES}"
