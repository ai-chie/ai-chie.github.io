#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'date'

POSTS_DIR    = '_posts'
SCHEMA_FILE  = '_data/post/post_schema.yml'
OUTPUT_DIR   = '_pages'

# ----------------------------------------
# スキーマ適用：デフォルト補完 + enum検証 + 必須チェック
# ----------------------------------------
def apply_schema(frontmatter, schema)
  schema.each do |key, meta|
    next if meta['calculated'] # layout, permalink, device は対象外

    if meta['required'] && !frontmatter.key?(key)
      warn "[WARN] Required key missing: #{key}"
    end

    unless frontmatter.key?(key) && !frontmatter[key].nil?
      frontmatter[key] = meta['default']
    end

    if meta['values'] && frontmatter[key]
      values = [frontmatter[key]].flatten # string or array 両対応
      values.each do |v|
        unless meta['values'].include?(v)
          warn "[WARN] Invalid value for #{key}: #{v.inspect} (allowed: #{meta['values']})"
        end
      end
    end
  end
  frontmatter
end

# ----------------------------------------
# Front Matter展開（output_device単位に複製）
# ----------------------------------------
def expand_targets(post, schema)
  filename = File.basename(post[:path])
  lang     = post[:frontmatter]['lang']

  devices = post[:frontmatter]['output_device'] || schema.dig('output_device', 'default')
  layout_settings    = post[:frontmatter]['output_layout_setting']    || schema.dig('output_layout_setting', 'default')
  permalink_settings = post[:frontmatter]['output_permalink_setting'] || schema.dig('output_permalink_setting', 'default')

  devices.map do |device|
    layout    = layout_settings[device]
    permalink = permalink_settings[device].to_s
                 .gsub('{device}', device)
                 .gsub('{lang}', lang)

    {
      filename: filename,
      device: device,
      lang: lang,
      layout: layout,
      permalink: permalink,
      content: post[:content],
      frontmatter: post[:frontmatter]
    }
  end
end

# ----------------------------------------
# 投稿ファイル読込（Front Matter + 本文）
# ----------------------------------------
def parse_post(path, schema)
  lines = File.readlines(path)
  if lines[0].strip != "---"
    warn "[WARN] No Front Matter in #{path}"
    return nil
  end

  i = 1
  frontmatter_lines = []
  while i < lines.size && lines[i].strip != "---"
    frontmatter_lines << lines[i]
    i += 1
  end
  content_lines = lines[(i+1)..-1] || []

  frontmatter = YAML.safe_load(frontmatter_lines.join)
  frontmatter = apply_schema(frontmatter, schema)

  {
    path: path,
    frontmatter: frontmatter,
    content: content_lines.join
  }
end

# ----------------------------------------
# 書き出し
# ----------------------------------------
def write_post_page(target)
  out_dir = File.join(OUTPUT_DIR, target[:device], target[:lang])
  FileUtils.mkdir_p(out_dir)
  FileUtils.touch(File.join(out_dir, ".keep"))
  out_path = File.join(out_dir, target[:filename])

  puts "[WRITE] #{out_path}"
  File.write(out_path, <<~FRONTMATTER + "\n" + target[:content])
    ---
    #{target[:frontmatter].merge({
      'device'    => target[:device],
      'layout'    => target[:layout],
      'permalink' => target[:permalink],
      'lang'      => target[:lang],
    }).to_yaml.strip}
    ---
  FRONTMATTER
end

# ----------------------------------------
# 実行本体
# ----------------------------------------
schema = YAML.load_file(SCHEMA_FILE)

Dir.glob("#{POSTS_DIR}/*.md").each do |path|
  post = parse_post(path, schema)
  next unless post
  expand_targets(post, schema).each do |target|
    write_post_page(target)
  end
end
