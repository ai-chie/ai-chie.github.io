#!/usr/bin/env ruby
require 'yaml'
require 'fileutils'
require 'date'
require 'psych'
require 'stringio'

POSTS_DIR    = '_posts'
SCHEMA_FILE  = '_data/post/post_schema.yml'
OUTPUT_DIR   = '_pages'

def apply_schema(frontmatter, schema)
  schema.each do |key, meta|
    next if meta['calculated']
    value = frontmatter[key]

    if meta['required'] && !frontmatter.key?(key)
      warn "[WARN] Required key missing: #{key}"
    end

    unless frontmatter.key?(key) && !frontmatter[key].nil?
      frontmatter[key] = meta['default']
      value = frontmatter[key]
    end

    if meta['values'] && value
      [value].flatten.each do |v|
        unless meta['values'].include?(v)
          warn "[WARN] Invalid value for #{key}: #{v.inspect} (allowed: #{meta['values']})"
        end
      end
    end

    expected_type = meta['type']
    type_mismatch = case expected_type
    when "string"  then !value.is_a?(String)
    when "array"   then !value.is_a?(Array)
    when "boolean" then ![true, false].include?(value)
    when "integer" then !value.is_a?(Integer)
    when "object"  then !value.is_a?(Hash)
    else false
    end

    if type_mismatch
      warn "[WARN] Type mismatch for #{key}: expected #{expected_type}, got #{value.class}"
    end
  end
  frontmatter
end

def parse_post(path, schema)
  lines = File.readlines(path)
  return nil unless lines[0].strip == "---"

  i = 1
  frontmatter_lines = []
  while i < lines.size && lines[i].strip != "---"
    frontmatter_lines << lines[i]
    i += 1
  end
  content_lines = lines[(i+1)..-1] || []

  begin
    frontmatter = YAML.safe_load(frontmatter_lines.join)
  rescue => e
    warn "[ERROR] Failed to parse front matter in #{path}: #{e.message}"
    return nil
  end

  unless frontmatter.is_a?(Hash)
    warn "[ERROR] Invalid front matter in #{path}: not a hash"
    return nil
  end

  frontmatter = apply_schema(frontmatter, schema)

  {
    path: path,
    frontmatter: frontmatter,
    content: content_lines.join
  }
end

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

def write_post_page(target)
  out_dir = File.join(OUTPUT_DIR, target[:device], target[:lang])
  FileUtils.mkdir_p(out_dir)
  FileUtils.touch(File.join(out_dir, ".keep"))
  out_path = File.join(out_dir, target[:filename])
  puts "[WRITE] #{out_path}"

  excluded_keys = %w[output_device output_layout_setting output_permalink_setting]
  filtered_frontmatter = target[:frontmatter].reject { |k, _| excluded_keys.include?(k) }

  final_frontmatter = filtered_frontmatter.merge({
    'device'    => target[:device],
    'layout'    => target[:layout],
    'permalink' => target[:permalink],
    'lang'      => target[:lang],
  })

  yaml_text = Psych.dump(final_frontmatter).sub(/\A---\s*\n?/, '').gsub(/^(-\s+)/, '  \1').rstrip

  File.write(out_path, <<~TEXT)
    ---
    #{yaml_text}
    ---
    #{target[:content]}
  TEXT
end

schema = YAML.load_file(SCHEMA_FILE)

# 生成対象ファイルの一覧を収集
generated_paths = []

Dir.glob("#{POSTS_DIR}/*.md").each do |path|
  post = parse_post(path, schema)
  next unless post
  expand_targets(post, schema).each do |target|
    path = File.join(OUTPUT_DIR, target[:device], target[:lang], target[:filename])
    generated_paths << path
    write_post_page(target)
  end
end

# taxonomy式 同期削除
generated_set = generated_paths.to_set
base_dirs = Dir.glob("#{OUTPUT_DIR}/*/*").select { |f| File.directory?(f) }
base_dirs.each do |dir|
  Dir.glob(File.join(dir, "*.md")).each do |file|
    unless generated_set.include?(file)
      puts "[DELETE] #{file}"
      File.delete(file)
    end
  end
end
