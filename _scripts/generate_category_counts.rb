require 'yaml'
require 'fileutils'

POSTS_DIR = '_posts'
OUTPUT_PATH = '_data/generated_category_counts.yml'
LANGS = %w[ja] # 必要に応じて 'en' も追加

result = {}

LANGS.each do |lang|
  counts = Hash.new(0)

  Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
    content = File.read(path)
    front = content.match(/---\s*\n(.*?)\n---/m)&.captures&.first
    next unless front

    data = YAML.safe_load(front)
    next unless data['lang'] == lang
    next if data['hidden'] || data['draft']

    Array(data['categories']).each do |cat|
      counts[cat] += 1
    end
  end

  result[lang] = counts.sort.to_h
end

FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))
File.write(OUTPUT_PATH, result.to_yaml)

puts "✅ #{OUTPUT_PATH} updated."

