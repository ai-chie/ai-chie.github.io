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

# ---------- ユーティリティ ----------

def safe_load_yaml(path)
  return {} unless File.exist?(path)
  YAML.load_file(path)
rescue => e
  warn "YAML load error in #{path}: #{e.message}"
  {}
end

def parse_front_matter(path)
  content = File.read(path)
  if content =~ /\A---\s*\n(.*?)\n---/m
    yaml = Regexp.last_match(1)
    YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
  else
    {}
  end
rescue Psych::SyntaxError => e
  warn "YAML syntax error in #{path}: #{e.message}"
  {}
end

def generate_slug(term, lang, overrides, used)
  return [overrides.dig(lang, term), 'override'] if overrides.dig(lang, term)

  slug = I18n.transliterate(term.to_s).parameterize
  source = 'auto'

  if used.include?(slug)
    slug = "#{lang}-#{slug}"
    source += '+conflict'
  end

  used << slug
  [slug, source]
end

# ---------- データ準備 ----------

schema     = safe_load_yaml(SCHEMA_PATH)
overrides  = safe_load_yaml(SLUG_DICT_FILE)
taxonomy   = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts     = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      str = term.to_s.strip
      next if str.empty?
      taxonomy[lang][type] << str
      counts[lang][type][str] += 1
    end
  end
end

# ---------- 出力処理 ----------

generated  = {}
missing    = Hash.new { |h, k| h[k] = [] }
conflicts  = Hash.new { |h, k| h[k] = {} }
used_slugs = {}

taxonomy.each do |lang, types|
  generated[lang] = {}

  types.each do |type, terms|
    key = type.to_s.chop  # 'category' or 'tag'
    items = []
    seen_slugs = {}

    terms.uniq.sort.each do |name|
      slug, src = generate_slug(name, lang, overrides, used_slugs)
      missing[lang] << name if src.start_with?('auto') && !overrides.dig(lang, name)
      if seen_slugs[slug]
        conflicts[lang][slug] ||= []
        conflicts[lang][slug] << name
      end
      seen_slugs[slug] = true

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count'         => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if %w[taxonomy_name taxonomy_slug].include?(attr)
        next if meta['unused']
        default = meta['default']
        value = meta['type'] == 'enum' ? (meta['values']&.include?(default) ? default : meta['values']&.first) : default
        item[attr] = value
      end

      items << item

      # 出力Markdownファイル
      path = File.join(OUTPUT_ROOT, lang, type.to_s, "#{slug}.md")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, <<~MD)
        ---
        layout: #{LAYOUT}
        title: "#{key.capitalize}: #{name}"
        #{key}: "#{name}"
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---
      MD
    end

    generated[lang][type] = items
  end
end

# ---------- YAML保存 ----------

FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated.to_yaml)
File.write(MISSING_FILE, missing.to_yaml)
File.write(CONFLICT_FILE, conflicts.to_yaml)

puts "✅ Taxonomy generation complete."
puts "   > Data:    #{TAXONOMY_YML}"
puts "   > Missing: #{MISSING_FILE}"
puts "   > Conflict: #{CONFLICT_FILE}"
