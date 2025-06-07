#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'date'
require 'i18n'
require 'active_support/core_ext/string/inflections'
require 'pp'

POSTS_DIR           = '_posts'
OUTPUT_ROOT         = '_generated'
LAYOUT              = 'default'
TAXONOMY_YML        = '_data/generated_taxonomy.yml'
SLUG_DICT_FILE      = '_data/slug_overrides.yml'
MISSING_TERMS_FILE  = '_data/missing_slug_terms.yml'
SCHEMA_PATH         = '_data/taxonomy/schema.yml'

# --- 安全な YAML ロード ---
def safe_load_yaml(path)
  return {} unless File.exist?(path)
  YAML.load_file(path)
rescue => e
  warn "[WARN] YAML load error in #{path}: #{e.message}"
  {}
end

# --- Front matter helper ---
def parse_front_matter(path)
  content = File.read(path)
  if content =~ /\A---\s*\n(.*?)\n---/m
    yaml = Regexp.last_match(1)
    data = YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
    puts "[TEST] Parsed front matter for #{path}:"; STDOUT.flush
    pp data; STDOUT.flush
    return data
  else
    {}
  end
rescue Psych::SyntaxError => e
  warn "YAML syntax error in #{path}: #{e.message}"
  {}
end

# --- Slug generator ---
def generate_slug(term, lang, used, overrides, missing, type)
  override = overrides.dig(lang, term)
  return override if override && !override.strip.empty?

  missing[lang][type] << term unless missing[lang][type].include?(term)

  base = I18n.transliterate(term.to_s)
  base = term.to_s if base.strip.empty?

  slug = base.parameterize
  slug = term.to_s.each_codepoint.map { |c| c.to_s(16) }.join("-")[0..20] if slug.empty?
  slug = "#{lang}-#{slug}" if used.include?(slug)
  used << slug
  slug
end

# --- Utility: deep stringify keys ---
def deep_stringify_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify_keys(v) }
  when Array
    obj.map { |v| deep_stringify_keys(v) }
  else
    obj
  end
end

# --- 初期化 ---
taxonomy = Hash.new { |h, k| h[k] = { "categories" => [], "tags" => [] } }
counts   = Hash.new { |h, k| h[k] = { "categories" => Hash.new(0), "tags" => Hash.new(0) } }
missing  = Hash.new { |h, k| h[k] = { "categories" => [], "tags" => [] } }

used_slugs = []
overrides  = safe_load_yaml(SLUG_DICT_FILE)
schema     = safe_load_yaml(SCHEMA_PATH)

puts "[LOG] Scanning posts..."; STDOUT.flush
Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  ["categories", "tags"].each do |type|
    Array(data[type]).each do |term|
      str = term.to_s.strip
      next if str.empty?
      taxonomy[lang][type] << str
      counts[lang][type][str] += 1
    end
  end
end

# --- 出力処理 ---
generated = {}

taxonomy.each do |lang, types|
  generated[lang] = {}

  types.each do |type, terms|
    items = []
    key = type.chop

    terms.uniq.sort.each do |name|
      slug = generate_slug(name, lang, used_slugs, overrides, missing, type)

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count'         => counts[lang][type][name]
      }

      # --- schema属性を付加 ---
      schema.each do |attr, meta|
        next if meta['unused']
        default = meta['default']
        value = case meta['type']
                when 'string'  then default.to_s
                when 'integer' then default.to_i
                when 'boolean' then !!default
                when 'enum'
                  meta['values']&.include?(default) ? default : meta['values']&.first
                else
                  default
                end
        item[attr] = value
      end

      items << item

      md_path = File.join(OUTPUT_ROOT, lang, type, "#{slug}.md")
      FileUtils.mkdir_p(File.dirname(md_path))
      File.write(md_path, <<~MD)
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

# --- YAML保存 ---
puts "[LOG] Writing taxonomy YAML..."; STDOUT.flush
stringified = deep_stringify_keys(generated)
yaml_string = stringified.to_yaml
puts "[DEBUG] YAML Preview:\n#{yaml_string}"; STDOUT.flush
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
written = File.write(TAXONOMY_YML, yaml_string)
raise "[ERROR] YAML write failure!" if written == 0

File.write(MISSING_TERMS_FILE, deep_stringify_keys(missing).to_yaml)
puts "[DONE] Files written successfully."; STDOUT.flush
