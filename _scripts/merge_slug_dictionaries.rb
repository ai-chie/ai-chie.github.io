require 'yaml'
require 'fileutils'

BASE   = '_data'
OUTPUT = "#{BASE}/slug_overrides.yml"
FILES  = ['slug_overrides.yml', 'missing_slug_terms.yml', 'slug_conflicts.yml'].map { |f| "#{BASE}/#{f}" }

merged = {}

FILES.each do |file|
  next unless File.exist?(file)
  data = YAML.load_file(file) || {}
  data.each do |lang, entries|
    merged[lang] ||= {}
    entries.each do |name, slug|
      merged[lang][name] = slug
    end
  end
end

File.write(OUTPUT, merged.to_yaml)
puts "✅ Merged and saved to #{OUTPUT}"

