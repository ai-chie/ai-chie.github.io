require 'fileutils'
require 'yaml'

POSTS_DIR = '_posts'
OUTPUT_ROOT = '_generated'
LAYOUT = 'default'
TAXONOMY_YML = '_data/generated_taxonomy.yml'

taxonomy = { 'ja' => { categories: [], tags: [] }, 'en' => { categories: [], tags: [] } }
counts = { 'ja' => { categories: Hash.new(0), tags: Hash.new(0) }, 'en' => { categories: Hash.new(0), tags: Hash.new(0) } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  post = File.read(path)
  front_matter = post.match(/---\s*\n(.*?)\n---/m)&.captures&.first
  next unless front_matter

  begin
    data = YAML.safe_load(front_matter, permitted_classes: [Date, Time], aliases: true) || {}
  rescue Psych::Exception => e
    warn "YAML parse error in #{path}: #{e}"
    next
  end

  next if data['draft'] == true || data['hidden'] == true
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  Array(data['categories']).each do |cat|
    taxonomy[lang][:categories] << cat
    counts[lang][:categories][cat] += 1
  end

  Array(data['tags']).each do |tag|
    taxonomy[lang][:tags] << tag
    counts[lang][:tags][tag] += 1
  end
end

# 出力処理
generated_data = {}

taxonomy.each do |lang, types|
  generated_data[lang] = {}
  types.each do |type, terms|
    key = type.to_s.chop # categories -> category
    generated_data[lang][type] = terms.uniq.sort.map do |term|
      {
        'name' => term,
        'slug' => term.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, ''),
        'count' => counts[lang][type][term]
      }
    end

    # 各 term に対応するページを生成
    terms.uniq.each do |term|
      slug = term.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
      dir = "#{OUTPUT_ROOT}/#{lang}/#{type}/#{term}.md"
      label = type.to_s.capitalize.chop
      FileUtils.mkdir_p(File.dirname(dir))
      File.write(dir, <<~MD)
        ---
        layout: #{LAYOUT}
        title: #{label}: #{term}
        #{key}: #{term}
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---

        <h1>#{label}: #{term}</h1>
        <p>{{ site.data.#{key}s.#{lang}[page.#{key}] | default: 'この#{label}に関する記事を紹介します。' }}</p>

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
  end
end

# YAMLファイルに保存
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, generated_data.to_yaml)
