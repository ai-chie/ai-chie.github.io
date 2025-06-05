require 'fileutils'
require 'yaml'
require 'date'

POSTS_DIR = '_posts'
OUTPUT_ROOT = '_generated'
LAYOUT = 'default'
TAXONOMY_YML = '_data/generated_taxonomy.yml'
SCHEMA_PATH = '_data/taxonomy/schema.yml'

def normalize_slug(name)
  name.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
end

def extract_front_matter(path)
  content = File.read(path)
  if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
    YAML.safe_load($1, permitted_classes: [Date, Time], aliases: true) || {}
  else
    warn "⚠️ Front matter not found in #{path}"
    nil
  end
rescue Psych::Exception => e
  warn "⚠️ YAML parse error in #{path}: #{e}"
  nil
end

# Load schema
schema = YAML.load_file(SCHEMA_PATH)

# Prepare data structures
taxonomy = { 'ja' => { categories: [], tags: [] }, 'en' => { categories: [], tags: [] } }
counts   = { 'ja' => { categories: Hash.new(0), tags: Hash.new(0) }, 'en' => { categories: Hash.new(0), tags: Hash.new(0) } }

# Parse posts
Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = extract_front_matter(path)
  next unless data

  next if data['draft'] || data['hidden']
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      taxonomy[lang][type] << term
      counts[lang][type][term] += 1
    end
  end
end

# Generate taxonomy pages
generated_data = {}

taxonomy.each do |lang, types|
  generated_data[lang] = {}
  types.each do |type, terms|
    key = type.to_s.chop
    items = []
    seen_slugs = {}

    terms.uniq.sort.each do |term|
      name = term.to_s.strip
      next if name.empty?

      slug = normalize_slug(name)
      next if seen_slugs[slug]
      seen_slugs[slug] = true

      item = { 'taxonomy_name' => name, 'taxonomy_slug' => slug, 'count' => counts[lang][type][name] }

      # Set schema attributes
      schema.each do |attr, meta|
        next if attr == 'taxonomy_name' || meta['unused']
        item[attr] = if meta['type'] == 'enum'
          valid_values = meta['values'] || []
          value = meta['default']
          valid_values.include?(value) ? value : meta['default']
        else
          meta['default']
        end
      end

      items << item

      # Generate individual taxonomy page
      dir = "#{OUTPUT_ROOT}/#{lang}/#{type}/#{slug}.md"
      label = type.to_s.capitalize.chop
      FileUtils.mkdir_p(File.dirname(dir))
      File.write(dir, <<~MD)
        ---
        layout: #{LAYOUT}
        title: #{label}: #{name}
        #{key}: #{name}
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---

        <h1>#{label}: #{name}</h1>
        <p>{{ site.data.taxonomy.#{type}.#{lang}['#{name}'].taxonomy_description | default: 'この#{label}に関する記事を紹介します。' }}</p>

        {% assign posts = site.#{type}[page.#{key}] | where: 'lang', '#{lang}' | where_exp: 'post', 'post.hidden != true and post.draft != true' %}

        {% if posts.size > 0 %}
        <h2>おすすめ記事</h2>
        <ul>
          {% for post in posts limit: 2 %}
            <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
          {% endfor %}
        </ul>

        <h2>すべての記事</h2>
        <ul>
          {% for post in posts offset: 2 %}
            <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
          {% endfor %}
        </ul>
        {% else %}
        <p>現在この#{label}に該当する記事はありません。</p>
        {% endif %}
      MD
    end

    generated_data[lang][type] = items
  end
end

# Write output YAML
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated_data.to_yaml)
