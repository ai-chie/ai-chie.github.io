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
    data = YAML.safe_load(yaml, permitted_classes: [Date, Time], aliases: true) || {}
    warn "✅ Parsed: #{file_path} → categories=#{data['categories'].inspect} tags=#{data['tags'].inspect} lang=#{data['lang']}"
    return data
  else
    warn "❌ No front matter found in #{file_path}"
    return {}
  end
rescue Psych::SyntaxError => e
  warn "❌ YAML syntax error in #{file_path}: #{e.message}"
  {}
end

begin
  schema = YAML.load_file(SCHEMA_PATH)
rescue => e
  abort "❌ Failed to load taxonomy schema: #{e}"
end

taxonomy = {
  'ja' => { categories: [], tags: [] },
  'en' => { categories: [], tags: [] }
}
counts = {
  'ja' => { categories: Hash.new(0), tags: Hash.new(0) },
  'en' => { categories: Hash.new(0), tags: Hash.new(0) }
}

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  data = parse_front_matter(path)
  next if data.empty? || data['draft'] || data['hidden']

  lang = data['lang']
  unless %w[ja en].include?(lang)
    warn "⚠️ Unsupported lang '#{lang}' in #{path}"
    next
  end

  %i[categories tags].each do |type|
    Array(data[type]).each do |term|
      term_str = term.to_s.strip
      if term_str.empty?
        warn "⚠️ Skipped empty term for #{type} in #{lang} from post #{path}"
        next
      end
      taxonomy[lang][type.to_sym] << term_str
      counts[lang][type.to_sym][term_str] += 1
      puts "📥 Added #{type}: '#{term_str}' to taxonomy[#{lang}][#{type}]"
    end
  end
end

puts "🔍 Final collected taxonomy structure:"
puts taxonomy.inspect

generated_data = {}

taxonomy.each do |lang, types|
  generated_data[lang] = {}

  types.each do |type, terms|
    key = type.to_s.chop
    items = []
    seen_slugs = {}

    puts "🔍 Terms to generate for #{lang}/#{type}: #{terms.uniq.sort.inspect}"

    terms.uniq.sort.each do |name|
      slug = normalize_slug(name)
      next if seen_slugs[slug]
      seen_slugs[slug] = true

      item = {
        'taxonomy_name' => name,
        'taxonomy_slug' => slug,
        'count' => counts[lang][type.to_sym][name]
      }

      schema.each do |attr, meta|
        next if %w[taxonomy_name taxonomy_slug].include?(attr) || meta['unused']
        if meta['type'] == 'enum'
          item[attr] = meta['values'].include?(meta['default']) ? meta['default'] : meta['values'].first
        else
          item[attr] = meta['default']
        end
      end

      items << item
      puts "📘 Added item to #{lang}/#{type}: #{item.inspect}"

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
puts "✅ YAML written to #{TAXONOMY_YML}"
