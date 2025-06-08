
#!/usr/bin/env ruby
require 'fileutils'
require 'yaml'
require 'date'
require 'i18n'
require 'active_support/core_ext/string/inflections'
require 'pp'

# ---------------- CONSTANTS ----------------
POSTS_DIR           = '_posts'
OUTPUT_ROOT         = '_generated'
LAYOUT              = 'default'
TAXONOMY_YML        = '_data/generated_taxonomy.yml'
SLUG_DICT_FILE      = '_data/slug_overrides.yml'
MISSING_TERMS_FILE  = '_data/missing_slug_terms.yml'
CONFLICT_FILE       = '_data/slug_conflicts.yml'
SCHEMA_PATH         = '_data/taxonomy/schema.yml'
LANGS               = %w[ja en]
TYPES               = %w[categories tags]

# ---------------- FUNCTIONS ----------------
def safe_load_yaml(path)
  return {} unless File.exist?(path)
  YAML.load_file(path)
rescue => e
  warn "[WARN] YAML load error in #{path}: #{e.message}"
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

def validate_schema(schema)
  valid_types = %w[string integer boolean enum]
  schema.each do |attr, meta|
    unless valid_types.include?(meta['type'].to_s)
      warn "[WARN] Invalid type '#{meta['type']}' for schema key '#{attr}'"
    end
    if meta['type'] == 'enum' && !meta['values'].is_a?(Array)
      warn "[WARN] Enum 'values' must be an array for '#{attr}'"
    end
  end
end

def resolve_schema_value(meta, lang)
  val = meta['default']
  if val.is_a?(Hash)
    val[lang] || val.values.first
  else
    case meta['type']
    when 'string'  then val.to_s
    when 'integer' then val.to_i
    when 'boolean' then !!val
    when 'enum'
      meta['values']&.include?(val) ? val : meta['values']&.first
    else val
    end
  end
end

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

def generate_slug(term, lang, used, overrides, missing, conflicts, type)
  if (override = overrides.dig(lang, term))
    used << override
    return [override, 'override']
  end

  base = I18n.transliterate(term.to_s)
  base = term.to_s if base.strip.empty?
  slug = base.parameterize

  source = 'auto'
  if slug.empty?
    slug = term.to_s.each_codepoint.map { |c| c.to_s(16) }.join("-")[0..20]
  end

  if used.include?(slug)
    conflicts[lang][slug] ||= []
    conflicts[lang][slug] << term unless conflicts[lang][slug].include?(term)
    slug = "#{lang}-#{slug}"
    source += '+conflict'
  end

  used << slug
  missing[lang][type] << term unless missing[lang][type].include?(term)
  [slug, source]
end

def load_flat_taxonomy_dict(path, lang)
  raw = safe_load_yaml(path)
  return {} unless raw[lang]
  flat = {}
  raw[lang].each_value do |group|
    next unless group["items"]
    group["items"].each do |item|
      name = item["taxonomy_name"]
      flat[name] = item if name
    end
  end
  flat
end

# ---------------- INIT ----------------
taxonomy  = Hash.new { |h, k| h[k] = { "categories" => [], "tags" => [] } }
counts    = Hash.new { |h, k| h[k] = { "categories" => Hash.new(0), "tags" => Hash.new(0) } }
missing   = Hash.new { |h, k| h[k] = { "categories" => [], "tags" => [] } }
conflicts = Hash.new { |h, k| h[k] = {} }
used_slugs = []

overrides = safe_load_yaml(SLUG_DICT_FILE)
schema    = safe_load_yaml(SCHEMA_PATH)
validate_schema(schema)

puts "[LOG] Scanning posts..."; STDOUT.flush
Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']
  lang = data['lang']
  next unless LANGS.include?(lang)

  TYPES.each do |type|
    Array(data[type]).each do |term|
      str = term.to_s.strip
      next if str.empty?
      taxonomy[lang][type] << str
      counts[lang][type][str] += 1
    end
  end
end

taxonomy_definitions = {}
LANGS.each do |lang|
  taxonomy_definitions[lang] = {}
  TYPES.each do |type|
    path = "_data/taxonomy/#{type}.yml"
    taxonomy_definitions[lang][type] = load_flat_taxonomy_dict(path, lang)
  end
end

generated = {}

taxonomy.each do |lang, types|
  generated[lang] = {}

  types.each do |type, terms|
    items = []
    key = type.chop

    terms.uniq.sort.each do |name|
      slug, source = generate_slug(name, lang, used_slugs, overrides, missing, conflicts, type)
      
      
      name_key = name.to_s.strip.downcase
      dict_values = taxonomy_definitions.dig(lang, type).values
      mapped = dict_values.map { |v| v["taxonomy_name"].to_s.strip.downcase }
      puts "[DEBUG] lang: #{lang}, type: #{type}, name: #{name.inspect}, name_key: #{name_key}"
      puts "[DEBUG] dict_values: #{mapped.inspect}"
      normalized_key = name.to_s.strip.downcase
matched_entry = dict_values.find do |item|
  candidate = item["taxonomy_name"]
  candidate.is_a?(String) && !candidate.strip.empty? &&
    candidate.strip.downcase == normalized_key
end

      verified_name = matched_entry ? matched_entry["taxonomy_name"] : "unknown"
puts "[DEBUG] matched_entry: #{matched_entry.inspect}"
      puts "[DEBUG] verified_name: #{verified_name.inspect}"

      item = {
        'taxonomy_name' => verified_name,
        'taxonomy_slug' => slug,
        'slug_source'   => source,
        'count'         => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if meta['unused']
        item[attr] = resolve_schema_value(meta, lang)
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
        slug_source: #{source}
        ---
      MD
    end

    generated[lang][type] = items
  end
end

puts "[CHECK] Final taxonomy output structure:"
pp generated
puts "[LOG] Writing taxonomy YAML..."; STDOUT.flush
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, deep_stringify_keys(generated).to_yaml)
File.write(MISSING_TERMS_FILE, deep_stringify_keys(missing).to_yaml)
File.write(CONFLICT_FILE, deep_stringify_keys(conflicts).to_yaml)
puts "[DONE] All YAML files written."; STDOUT.flush
