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

# --------- Front matter helper ---------
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

puts "[TEST] Parsed front matter for #{path}:"
pp data

# --------- Slug generator ---------
def generate_slug(term, lang, used)
  slug = I18n.transliterate(term.to_s).parameterize
  slug = "#{lang}-#{slug}" if used.include?(slug)
  used << slug
  slug
end

# --------- Main execution ---------
taxonomy = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts   = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }
used_slugs = []

puts "[LOG] Scanning posts..."
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

generated = {}

taxonomy.each do |lang, types|
  generated[lang] = {}

  types.each do |type, terms|
    items = []
    key = type.to_s.chop

    terms.uniq.sort.each do |name|
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

puts "[LOG] Writing YAML to #{TAXONOMY_YML}"
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated.to_yaml)

puts "[DONE] generated_taxonomy.yml written successfully."

puts "[DEBUG] Final taxonomy object structure:"
pp generated
puts "[DEBUG] Lang keys: #{generated.keys}"
puts "[DEBUG] First level sizes:"
generated.each do |lang, types|
  puts "  - #{lang}:"
  types.each do |type, items|
    puts "    * #{type}: #{items.size} items"
  end
end

