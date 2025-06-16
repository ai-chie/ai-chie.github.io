#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'set'
require 'psych'

TAXONOMY_DIR = "_data/taxonomy"
SCHEMA_FILE  = "#{TAXONOMY_DIR}/taxonomy_schema.yml"
CATEGORIES_FILE = "#{TAXONOMY_DIR}/categories.yml"
TAGS_FILE       = "#{TAXONOMY_DIR}/tags.yml"
OUTPUT_PAGES = "_pages"
DATA_DIR     = "_data"

def load_yaml(path)
  YAML.load_file(path)
rescue => e
  warn "[WARN] Failed to load YAML #{path}: #{e.message}"
  []
end

def apply_schema(entry, schema)
  return {} unless entry.is_a?(Hash)
  result = {}

  schema.each do |key, meta|
    next if meta["calculated"]
    value = entry[key]

    if meta["required"] && !entry.key?(key)
      puts "[WARN] Required key missing: #{key} in slug=#{entry["slug"] || "no-slug"}"
    end

    unless entry.key?(key) && !entry[key].nil?
      entry[key] = meta["default"]
    end
    value = entry[key]
    result[key] = value

    expected_type = meta["type"]
    type_mismatch = case expected_type
    when "string"  then !value.is_a?(String)
    when "array"   then !value.is_a?(Array)
    when "boolean" then ![true, false].include?(value)
    when "integer" then !value.is_a?(Integer)
    when "object"  then !value.is_a?(Hash)
    else false
    end

    if type_mismatch
      puts "[WARN] Type mismatch for #{key} in slug=#{entry["slug"] || "no-slug"}: expected #{expected_type}, got #{value.class}"
    end
  end

  result
end

def warn_unexpected_keys(entry, schema, context_label)
  extra_keys = entry.keys - schema.keys
  unless extra_keys.empty?
    puts "[WARN] Unexpected keys in #{context_label}: #{extra_keys}"
  end
end

def expand_targets(entry)
  devices = entry["output_device"] || []
  langs   = entry["output_lang"] || []
  types   = entry["output_type"] || []
  layout_map = entry["output_layout_setting"] || {}
  permalink_map = entry["output_permalink_setting"] || {}
  slug = entry["slug"]

  devices.product(langs, types).map do |device, lang, type|
    layout    = layout_map[device]
    permalink = permalink_map[device].to_s
                  .gsub("{device}", device)
                  .gsub("{lang}", lang)
                  .gsub("{type}", type)
                  .gsub("{slug}", slug)

    {
      "slug"        => slug,
      "name"        => entry["name"][lang],
      "title"       => entry["title"][lang],
      "description" => entry["description"][lang],
      "device"      => device,
      "lang"        => lang,
      "type"        => type,
      "layout"      => layout,
      "permalink"   => permalink,
      "path"        => File.join(OUTPUT_PAGES, device, lang, type, "#{slug}.md")
    }
  end
end

def build_frontmatter(target)
  {
    "slug"        => target["slug"],
    "name"        => target["name"],
    "title"       => target["title"],
    "description" => target["description"],
    "device"      => target["device"],
    "lang"        => target["lang"],
    "type"        => target["type"],
    "layout"      => target["layout"],
    "permalink"   => target["permalink"]
  }
end

def write_markdown(target)
  path = target["path"]
  dir = File.dirname(path)
  FileUtils.mkdir_p(dir)
  FileUtils.touch(File.join(dir, ".keep"))
  puts "[WRITE] #{path}"

  frontmatter = build_frontmatter(target)
  yaml_text = Psych.dump(frontmatter).sub(/\A---\s*\n?/, '').gsub(/^(-\s+)/, '  \1').rstrip

  File.write(path, <<~TEXT)
    ---
    #{yaml_text}
    ---
  TEXT
end

schema = load_yaml(SCHEMA_FILE)

categories = load_yaml(CATEGORIES_FILE).map do |entry|
  warn_unexpected_keys(entry, schema, "slug=#{entry["slug"] || "no-slug"}")
  apply_schema(entry, schema).merge("output_type" => ["categories"])
end

tags = load_yaml(TAGS_FILE).map do |entry|
  warn_unexpected_keys(entry, schema, "slug=#{entry["slug"] || "no-slug"}")
  apply_schema(entry, schema).merge("output_type" => ["tags"])
end

all_entries = categories + tags

generated = []
conflicts = []
missing = []
seen_paths = Set.new

all_entries.each do |entry|
  if entry["slug"].to_s.strip.empty?
    puts "[ERROR] Missing slug in entry: #{entry.inspect}"
    missing << {
      "slug" => nil,
      "type" => entry["output_type"]&.first,
      "lang" => entry["output_lang"]&.first,
      "device" => entry["output_device"]&.first,
      "name" => entry.dig("name", "ja") || entry.dig("name", "en"),
      "title" => entry.dig("title", "ja") || entry.dig("title", "en"),
      "description" => entry.dig("description", "ja") || entry.dig("description", "en")
    }
    next
  end

  expand_targets(entry).each do |target|
    path = target["path"]
    if seen_paths.include?(path)
      puts "[WARN] Conflict: duplicate slug for #{path}"
      conflicts << target
      next
    end

    seen_paths << path
    write_markdown(target)
    generated << target
  end
end

expected_paths = generated.map { |t| t["path"] }.to_set
base_dirs = Dir.glob("#{OUTPUT_PAGES}/*/*/*").select { |f| File.directory?(f) }
base_dirs.each do |dir|
  Dir.glob(File.join(dir, "*.md")).each do |file|
    unless expected_paths.include?(file)
      puts "[DELETE] #{file}"
      File.delete(file)
    end
  end
end

File.write("#{DATA_DIR}/taxonomy/script_output/missing_slug_terms.yml", { "missing" => missing }.to_yaml)
File.write("#{DATA_DIR}/taxonomy/script_output/slug_conflicts.yml", { "conflicts" => conflicts }.to_yaml)

puts "[DONE] taxonomy ページと中間データを出力しました。"
