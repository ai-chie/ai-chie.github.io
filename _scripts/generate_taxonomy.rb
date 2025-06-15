#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'

# ---------- 設定 ----------
TAXONOMY_DIR = "_data/taxonomy"
SCHEMA_FILE  = "#{TAXONOMY_DIR}/taxonomy_schema.yml"
CATEGORIES_FILE = "#{TAXONOMY_DIR}/categories.yml"
TAGS_FILE       = "#{TAXONOMY_DIR}/tags.yml"
OUTPUT_PAGES = "_pages"
DATA_DIR     = "_data"

# ---------- ユーティリティ ----------
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

# ---------- 実行 ----------
schema = load_yaml(SCHEMA_FILE)

categories = load_yaml(CATEGORIES_FILE).map do |entry|
  apply_schema(entry, schema).merge("output_type" => ["categories"])
end

tags = load_yaml(TAGS_FILE).map do |entry|
  apply_schema(entry, schema).merge("output_type" => ["tags"])
end

all_entries = categories + tags
generated = []

all_entries.each do |entry|
  expand_targets(entry).each do |target|
    write_markdown(target)
    generated << target.merge("path" => File.join(
      OUTPUT_PAGES, target["device"], target["lang"], target["type"], "#{target["slug"]}.md"
    ))
  end
end

# ---------- 中間ファイル出力 ----------
File.write("#{DATA_DIR}/generated_taxonomy.yml", { "generated" => generated }.to_yaml)
File.write("#{DATA_DIR}/missing_slug_terms.yml", {}.to_yaml)
File.write("#{DATA_DIR}/slug_conflicts.yml", {}.to_yaml)

puts "[DONE] taxonomy ページと中間データを出力しました。"
