#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'pathname'

# --- 設定 ---
TAXONOMY_DIR = "_data/taxonomy"
OUTPUT_ROOT  = "_pages"
DATA_OUTPUT  = "_data"
SCHEMA_FILE  = "#{TAXONOMY_DIR}/taxonomy_schema.yml"
CATEGORIES_FILE = "#{TAXONOMY_DIR}/categories.yml"
TAGS_FILE       = "#{TAXONOMY_DIR}/tags.yml"

# --- ユーティリティ関数 ---
def load_yaml(path)
  YAML.load_file(path)
rescue => e
  warn "[WARN] Failed to load YAML #{path}: #{e.message}"
  {}
end

def apply_schema_defaults(entry, schema)
  result = {}
  schema.each do |key, meta|
    next if meta["calculated"]
    result[key] = entry.key?(key) ? entry[key] : meta["default"]
  end
  result
end

def expand_targets(entry)
  devices = entry["output_device"] || []
  langs   = entry["output_lang"]   || []
  types   = entry["output_type"]   || []

  targets = []
  devices.each do |device|
    langs.each do |lang|
      types.each do |type|
        layout = entry["output_layout_setting"][device]
        permalink_template = entry["output_permalink_setting"][device]
        slug = entry["slug"]
        permalink = permalink_template.gsub("{device}", device)
                                      .gsub("{lang}", lang)
                                      .gsub("{type}", type)
                                      .gsub("{slug}", slug)
        targets << {
          "device"    => device,
          "lang"      => lang,
          "type"      => type,
          "slug"      => slug,
          "layout"    => layout,
          "permalink" => permalink,
          "name"      => entry["name"][lang]
        }
      end
    end
  end
  targets
end

# --- taxonomy読み込み ---
schema     = load_yaml(SCHEMA_FILE)
categories = apply_schema_defaults(load_yaml(CATEGORIES_FILE), schema)
categories["output_type"] = ["categories"]

tags = apply_schema_defaults(load_yaml(TAGS_FILE), schema)
tags["output_type"] = ["tags"]

entries = {
  "categories" => [categories],
  "tags"       => [tags]
}

# --- 出力処理 ---
output_registry = []

entries.each do |type, entry_list|
  entry_list.each do |entry|
    expand_targets(entry).each do |target|
      dir = File.join(OUTPUT_ROOT, target["device"], target["lang"], target["type"])
      path = File.join(dir, "#{target["slug"]}.md")
      FileUtils.mkdir_p(dir)
      File.write(path, <<~MD)
        ---
        slug: #{target["slug"].inspect}
        name: #{target["name"].inspect}
        device: #{target["device"].inspect}
        lang: #{target["lang"].inspect}
        type: #{target["type"].inspect}
        layout: #{target["layout"].inspect}
        permalink: #{target["permalink"].inspect}
        ---
      MD

      # .keepの配置
      FileUtils.touch(File.join(dir, ".keep")) unless File.exist?(File.join(dir, ".keep"))

      # registry記録
      output_registry << target.merge("path" => path)
    end
  end
end

# --- 中間ファイル出力 ---
File.write("#{DATA_OUTPUT}/generated_taxonomy.yml", { "generated" => output_registry }.to_yaml)
File.write("#{DATA_OUTPUT}/missing_slug_terms.yml", {}.to_yaml)
File.write("#{DATA_OUTPUT}/slug_conflicts.yml", {}.to_yaml)

puts "[DONE] taxonomy ページと中間データを出力しました。"

