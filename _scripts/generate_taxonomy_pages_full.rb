#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'date'
require 'i18n'
require 'active_support/core_ext/string/inflections'

POSTS_DIR       = '_posts'
OUTPUT_ROOT     = '_generated'
LAYOUT          = 'default'
TAXONOMY_YML    = '_data/generated_taxonomy.yml'
SCHEMA_PATH     = '_data/taxonomy/schema.yml'
SLUG_DICT_FILE  = '_data/slug_overrides.yml'
MISSING_FILE    = '_data/missing_slug_terms.yml'
CONFLICT_FILE   = '_data/slug_conflicts.yml'

# YAML safe load with fallback
def safe_load_yaml(path)
  YAML.load_file(path)
rescue => e
  warn "YAML load error in #{path}: #{e.message}"
  {}
end

# カスタムスラッグの生成
def generate_slug(term, lang, override_dict, used_slugs)
  if override_dict.dig(lang, term)
    slug = override_dict[lang][term]
    source = 'override'
  else
    base = I18n.transliterate(term.to_s)
    slug = base.parameterize
    source = 'auto'
  end

  original = slug.dup
  if used_slugs.include?(slug)
    slug = "#{lang}-#{slug}"
    source += ' (conflict-resolved)'
  end
  used_slugs << slug

  [slug, source]
end

# フロントマター抽出
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
  warn "YAML error in #{file_path}: #{e.message}"
  {}
end

# 初期ロード
schema = safe_load_yaml(SCHEMA_PATH)
slug_dict = safe_load_yaml(SLUG_DICT_FILE)

taxonomy = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts   = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }

# 投稿処理
Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']

  lang = data['lang']
  next unless %w[ja en].include?(lang)

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      term_str = term.to_s.strip
      next if term_str.empty?
      taxonomy[lang][type] << term_str
      counts[lang][type][term_str] += 1
    end
  end
end

# 辞書未定義語・スラッグ衝突管理
missing_terms = Hash.new { |h, k| h[k] = [] }
conflicts = Hash.new { |h, k| h[k] = {} }

generated_data = {}
used_slugs = {}

taxonomy.each do |lang, types|
  generated_data[lang] = {}

  types.each do |type, terms|
    key = type.to_s.chop
    items = []
    seen = {}

    terms.uniq.sort.each do |name|
      slug, source = generate_slug(name, lang, slug_dict, used_slugs)

      missing_terms[lang] << name if source.start_with?('auto') && !slug_dict.dig(lang, name)
      conflicts[lang][slug] = [] if conflicts[lang].key?(slug)
      conflicts[lang][slug] ||= []
      conflicts[lang][slug] << name if seen[slug]
      seen[slug] = true

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count' => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if %w[taxonomy_name taxonomy_slug].include?(attr) || meta['unused']
        if meta['type'] == 'enum'
          item[attr] = meta['values'].include?(meta['default']) ? meta['default'] : meta['values'].first
        else
          item[attr] = meta['default']
        end
      end

      items << item

      # ページ出力
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
      MD
    end
    generated_data[lang][type] = items
  end
end

# 出力
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated_data.to_yaml)

File.write(MISSING_FILE, missing_terms.to_yaml)
File.write(CONFLICT_FILE, conflicts.to_yaml)
puts "✅ Taxonomy data written to #{TAXONOMY_YML}, #{MISSING_FILE}, #{CONFLICT_FILE}"
