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

# --------- Front matter helper ---------
def parse_front_matter(path)
  content = File.read(path)
  if content =~ /\A---\s*\n(.*?)\n---/m
    yaml = Regexp.last_match(1)
    data = YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
    puts "[TEST] Parsed front matter for #{path}:"
    pp data
    return data
  else
    {}
  end
rescue Psych::SyntaxError => e
  warn "YAML syntax error in #{path}: #{e.message}"
  {}
end

# --------- Slug generator ---------
def generate_slug(term, lang, used)
  slug = I18n.transliterate(term.to_s).parameterize
  slug = "#{lang}-#{slug}" if used.include?(slug)
  used << slug
  slug
end

# --------- 初期化 ---------
taxonomy = Hash.new { |h, k| h[k] = { "categories" => [], "tags" => [] } }
counts   = Hash.new { |h, k| h[k] = { "categories" => Hash.new(0), "tags" => Hash.new(0) } }
used_slugs = []

puts "[LOG] Scanning posts..."
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

# --------- デバッグ確認 ---------
puts "[TRACE] taxonomy keys: #{taxonomy.keys}"
puts "[TRACE] taxonomy['ja']['categories']: #{taxonomy.dig('ja', 'categories').inspect}"
puts "[TRACE] taxonomy['ja']['tags']: #{taxonomy.dig('ja', 'tags').inspect}"

# --------- 出力処理 ---------
generated = {}

taxonomy.each do |lang, types|
  puts "[TRACE] Building taxonomy for lang=#{lang}"
  generated[lang] = {}

  types.each do |type, terms|
    puts "[TRACE]  → #{type}: #{terms.uniq.sort.inspect}"
    items = []
    key = type.chop # "categories" → "category"

    terms.uniq.sort.each do |name|
      puts "[TRACE]    → term=#{name}"
      slug = generate_slug(name, lang, used_slugs)

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count'         => counts[lang][type][name],
        'color'         => '#cccccc',
        'description'   => '',
        'priority'      => 99
      }

      items << item

      # Markdown出力
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

    puts "[TRACE]    → items.size = #{items.size}"
    generated[lang][type] = items
  end
end

# --------- YAML保存 ---------
puts "[LOG] Writing YAML to #{TAXONOMY_YML}"
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated.to_yaml)

puts "[DONE] generated_taxonomy.yml written successfully."
puts "[DEBUG] Final taxonomy object structure:"
pp generated
