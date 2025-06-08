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
  if val.
