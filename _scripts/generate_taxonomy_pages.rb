require 'fileutils'
require 'yaml'
require 'date'

POSTS_DIR     = '_posts'
OUTPUT_ROOT   = '_generated'
LAYOUT        = 'default'
TAXONOMY_YML  = '_data/generated_taxonomy.yml'
SCHEMA_PATH   = '_data/taxonomy/schema.yml'

def normalize_slug(name)
  name.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
end

def parse_front_matter(file_path)
  content = File.read(file_path)
  if content =~ /\A---\s*\n(.*?)\n---/m
    yaml = Regexp.last_match(1)
    YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
  else
    {}
  end
rescue Psych::SyntaxError => e
  warn "YAML syntax error in #{file_path}: #{e.message}"
  {}
end

schema = YAML.load_file(SCHEMA_PATH)
taxonomy = Hash.new { |h, k| h[k] = { categories: [], tags: [] } }
counts = Hash.new { |h, k| h[k] = { categories: Hash.new(0), tags: Hash.new(0) } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] == true || data['hidden'] == true

  lang = data['lang']
  next unless %w[ja en].include?(lang)

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      taxonomy[lang][type] << term
      counts[lang][type][term] += 1
    end
  end
end

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
      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count' => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if %w[taxonomy_name taxonomy_slug].include?(attr) || meta['unused']
        if meta['type'] == 'enum'
          valid = meta['values'] || []
          def_val = meta['default']
          item[attr] = valid.include?(def_val) ? def_val : valid.first
        else
          item[attr] = meta['default']
        end
      end

      items << item

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

FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated_data.to_yaml)
