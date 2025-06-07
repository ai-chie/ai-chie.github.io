#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'date'
require 'i18n'
require 'active_support/core_ext/string/inflections'
require 'pp'

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

puts "[LOG] Loading schema..."
schema     = safe_load_yaml(SCHEMA_PATH)
puts "[LOG] Schema keys: #{schema.keys}"

puts "[LOG] Loading slug overrides..."
overrides  = safe_load_yaml(SLUG_DICT_FILE)

taxonomy   = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts     = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }

puts "[LOG] Scanning posts in #{POSTS_DIR}/"
files = Dir.glob("#{POSTS_DIR}/**/*.md")
puts "[LOG] Found #{files.size} markdown files."

files.each do |path|
  puts "[POST] Checking: #{path}"
  data = parse_front_matter(path)
  if data.empty?
    puts "[WARN] Front matter missing or invalid in: #{path}"
    next
  end

  lang = data['lang']
  if !%w[ja en].include?(lang)
    puts "[SKIP] Unsupported or missing lang: #{lang} in #{path}"
    next
  end

  if data['draft'] || data['hidden']
    puts "[SKIP] Draft or hidden: #{path}"
    next
  end

  puts "[OK] lang=#{lang}, categories=#{data['categories']}, tags=#{data['tags']}"

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
  puts "[TAXONOMY] Generating for language: #{lang}"
  generated[lang] = {}

  types.each do |type, terms|
    key = type.to_s.chop
    items = []
    seen_slugs = {}

    puts "  [#{type}] Terms: #{terms.uniq.sort.inspect}"

    terms.uniq.sort.each do |name|
      slug, src = generate_slug(name, lang, overrides, used_slugs)
      puts "    → #{name} → #{slug} (#{src})"
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

    puts "  [#{type}] Total generated items: #{items.size}"
    generated[lang][type] = items
  end
end

# ---------- YAML保存 ----------

puts "[SAVE] Writing output YAMLs..."
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated.to_yaml)
File.write(MISSING_FILE, missing.to_yaml)
File.write(CONFLICT_FILE, conflicts.to_yaml)

puts "[DONE] YAML written:"
puts "  → #{TAXONOMY_YML} (#{File.size?(TAXONOMY_YML).to_i} bytes)"
puts "  → #{MISSING_FILE} (#{File.size?(MISSING_FILE).to_i} bytes)"
puts "  → #{CONFLICT_FILE} (#{File.size?(CONFLICT_FILE).to_i} bytes)"

puts "[DEBUG] Final structure of generated taxonomy object:"
pp generated
