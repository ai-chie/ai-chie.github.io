#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'set'

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
    result[key] = entry.key?(key) ? entry[key] : meta["default"]
  end
  result
end

def expand_targets(entry)
  devices = entry["output_device"] || []
  langs   = entry["output_lang"] || []
  types   = entry["output_type"] || []
  devices.product(langs, types).map do |device, lang, type|
    layout = entry["output_layout_setting"][device]
    permalink_template = entry["output_permalink_setting"][device]
    slug = entry["slug"]
    {
      "slug"        => slug,
      "name"        => entry["name"][lang],
      "title"       => entry["title"][lang],
      "description" => entry["description"][lang],
      "device"      => device,
      "lang"        => lang,
      "type"        => type,
      "layout"      => layout,
      "permalink"   => permalink_template.gsub("{device}", device)
                                         .gsub("{lang}", lang)
                                         .gsub("{type}", type)
                                         .gsub("{slug}", slug)
    }
  end
end

def write_markdown(target)
  dir = File.join(OUTPUT_PAGES, target["device"], target["lang"], target["type"])
  FileUtils.mkdir_p(dir)
  FileUtils.touch(File.join(dir, ".keep"))
  if target["slug"].to_s.strip.empty?
  puts "[ERROR] Missing slug in entry: #{target.inspect}"
  missing << {
    "slug" => nil,
    "type" => target["type"],
    "lang" => target["lang"],
    "device" => target["device"],
    "name" => target["name"],
    "title" => target["title"],
    "description" => target["description"]
  }
  next
end

  path = File.join(dir, "#{target["slug"]}.md")
  puts "[WRITE] #{path}"
  File.write(path, <<~FRONTMATTER)
    ---
    slug: #{target["slug"].inspect}
    name: #{target["name"].inspect}
    title: #{target["title"].inspect}
    description: #{target["description"].inspect}
    device: #{target["device"].inspect}
    lang: #{target["lang"].inspect}
    type: #{target["type"].inspect}
    layout: #{target["layout"].inspect}
    permalink: #{target["permalink"].inspect}
    ---
  FRONTMATTER
end

schema = load_yaml(SCHEMA_FILE)
categories = load_yaml(CATEGORIES_FILE).map { |entry| apply_schema(entry, schema).merge("output_type" => ["categories"]) }
tags = load_yaml(TAGS_FILE).map { |entry| apply_schema(entry, schema).merge("output_type" => ["tags"]) }
all_entries = categories + tags

generated = []
conflicts = []
missing = []
seen_paths = Set.new

all_entries.each do |entry|
  expand_targets(entry).each do |target|
    path = File.join(OUTPUT_PAGES, target["device"], target["lang"], target["type"], "#{target["slug"]}.md")
    if seen_paths.include?(path)
      puts "[WARN] Conflict: duplicate slug for #{path}"
      conflicts << {
  "path" => path,
  "slug" => target["slug"],
  "type" => target["type"],
  "lang" => target["lang"],
  "device" => target["device"],
  "name" => target["name"],
  "title" => target["title"],
  "description" => target["description"]
}
      next
    end
    seen_paths << path
    write_markdown(target)
    generated << target.merge("path" => path)
  end
end

# 不要ファイルの削除
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

# 中間出力
File.write("#{DATA_DIR}/generated_taxonomy.yml", { "generated" => generated }.to_yaml)
File.write("#{DATA_DIR}/missing_slug_terms.yml", { "missing" => missing }.to_yaml)
File.write("#{DATA_DIR}/slug_conflicts.yml", { "conflicts" => conflicts }.to_yaml)

puts "[DONE] taxonomy ページと中間データを出力しました。"
