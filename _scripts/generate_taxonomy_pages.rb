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
  puts "[DEBUG] SlugGen: term=#{term} lang=#{lang}"; STDOUT.flush

  override = overrides.dig(lang, term)
  if override && !override.strip.empty?
    puts "[DEBUG] → override slug=#{override}"; STDOUT.flush
    return override
  end

  missing[lang][type] << term unless missing[lang][type].include?(term)

  base = I18n.transliterate(term.to_s)
  puts "[DEBUG] → transliterate=#{base.inspect}"; STDOUT.flush
  base = term.to_s if base.strip.empty?

  slug = base.parameterize
  puts "[DEBUG] → parameterized=#{slug.inspect}"; STDOUT.flush

  if slug.empty?
    slug = term.to_s.each_codepoint.map { |c| c.to_s(16) }.join("-")[0..20]
    puts "[DEBUG] → fallback slug=#{slug}"; STDOUT.flush
  end

  if used.include?(slug)
    slug = "#{lang}-#{slug}"
    puts "[DEBUG] → conflict resolved slug=#{slug}"; STDOUT.flush
  end

  used << slug
  puts "[DEBUG] → final slug=#{slug}"; STDOUT.flush
  slug
end

# --- Utility: deep stringify keys ---
def deep_stringify_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), h|
      h[k.to_s] = deep_stringify_keys(v)
    end
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
overrides = File.exist?(SLUG_DICT_FILE) ? YAML.load_file(SLUG_DICT_FILE) : {}

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
  puts "[TRACE] Building taxonomy for lang=#{lang}"; STDOUT.flush
  generated[lang] = {}

  types.each do |type, terms|
    puts "[TRACE]  → #{type}: #{terms.uniq.sort.inspect}"; STDOUT.flush
    items = []
    key = type.chop

    terms.uniq.sort.each do |name|
      puts "[TRACE]    → term=#{name}"; STDOUT.flush
      slug = generate_slug(name, lang, used_slugs, overrides, missing, type)

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count'         => counts[lang][type][name],
        'color'         => '#cccccc',
        'description'   => '',
        'priority'      => 99
      }

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

    puts "[TRACE]    → items.size = #{items.size}"; STDOUT.flush
    generated[lang][type] = items
  end
end

# --- YAML保存 ---
puts "[LOG] Writing YAML to #{TAXONOMY_YML}"; STDOUT.flush

stringified = deep_stringify_keys(generated)
yaml_string = stringified.to_yaml

puts "[DEBUG] YAML Preview:\n#{yaml_string}"; STDOUT.flush

FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
bytes_written = File.write(TAXONOMY_YML, yaml_string)
puts "[INFO] #{bytes_written} bytes written to #{TAXONOMY_YML}"; STDOUT.flush

raise "[ERROR] YAML write failure: empty file" if bytes_written == 0

File.write(MISSING_TERMS_FILE, deep_stringify_keys(missing).to_yaml)
puts "[DONE] missing terms also written to #{MISSING_TERMS_FILE}"; STDOUT.flush

puts "[DEBUG] Final taxonomy object structure:"; STDOUT.flush
pp generated; STDOUT.flush
