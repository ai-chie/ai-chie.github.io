require 'yaml'
require 'fileutils'

SLUG_OVERRIDES_FILE = '_data/slug_overrides.yml'
MISSING_FILE = '_data/missing_slug_overrides.yml'

# ファイル読み込み
overrides = File.exist?(SLUG_OVERRIDES_FILE) ? YAML.load_file(SLUG_OVERRIDES_FILE) : {}
missing   = File.exist?(MISSING_FILE) ? YAML.load_file(MISSING_FILE) : {}

# 空の場合は終了
if missing.nil? || missing.empty?
  puts "✅ No missing slugs to merge."
  exit 0
end

merged = overrides.dup

missing.each do |lang, words|
  merged[lang] ||= {}
  words.each do |word|
    # 既存に存在しない語だけ追加（仮スラッグは parameterize 相当）
    unless merged[lang].key?(word)
      slug = word.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
      merged[lang][word] = slug
      puts "➕ Added: #{word.inspect} → #{slug.inspect} (lang=#{lang})"
    end
  end
end

# YAMLとして保存（バックアップも残す）
timestamp = Time.now.strftime('%Y%m%d%H%M%S')
FileUtils.cp(SLUG_OVERRIDES_FILE, "#{SLUG_OVERRIDES_FILE}.bak.#{timestamp}") if File.exist?(SLUG_OVERRIDES_FILE)
File.write(SLUG_OVERRIDES_FILE, merged.to_yaml)

puts "✅ Merged missing slugs into #{SLUG_OVERRIDES_FILE}"

