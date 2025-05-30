require 'fileutils'
require 'yaml'

POSTS_DIR = '_posts'
OUTPUT_ROOT = '_generated'
LAYOUT = 'default'

# カテゴリ・タグを収集
taxonomy = { 'ja' => { categories: [], tags: [] }, 'en' => { categories: [], tags: [] } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  post = File.read(path)
  front_matter = post.match(/---\s*\n(.*?)\n---/m)&.captures&.first
  next unless front_matter

  begin
    data = YAML.safe_load(
      front_matter,
      permitted_classes: [Date, Time],
      aliases: true
    ) || {}
  rescue Psych::Exception => e
    warn "YAML parse error in #{path}: #{e}"
    next
  end

  next if data['draft'] == true || data['hidden'] == true
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  taxonomy[lang][:categories] += Array(data['categories'])
  taxonomy[lang][:tags] += Array(data['tags'])
end

taxonomy.each do |lang, types|
  types.each do |type, terms|
    terms.uniq.each do |term|
      slug = term.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
      dir = "#{OUTPUT_ROOT}/#{lang}/#{type}/#{term}.md"
      FileUtils.mkdir_p(File.dirname(dir))
      File.write(dir, <<~MD)
        ---
        layout: #{LAYOUT}
        title: #{type.to_s.capitalize.chop}: #{term}
        #{type.to_s.chop}: #{term}
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---

        <h1>#{type.to_s.capitalize.chop}: #{term}</h1>
        <ul>
          {% assign posts = site.#{type}[page.#{type.to_s.chop}] | where: 'lang', '#{lang}' | where_exp: 'post', 'post.hidden != true and post.draft != true' %}
          {% for post in posts %}
            <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
          {% endfor %}
        </ul>
      MD
    end
  end
end
