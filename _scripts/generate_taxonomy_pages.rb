require 'fileutils'
require 'yaml'

POSTS_DIR = '_posts'
OUTPUT_ROOT = '.'
LAYOUT = 'default'

taxonomy = { 'ja' => { categories: [], tags: [] }, 'en' => { categories: [], tags: [] } }

Dir.glob("#{POSTS_DIR}/**/*.md").each do |path|
  content = File.read(path)
  front_matter = content.match(/---\s*\n(.*?)\n---/m)&.captures&.first
  next unless front_matter

  data = YAML.safe_load(front_matter)
  lang = data['lang']
  next unless %w[ja en].include?(lang)

  taxonomy[lang][:categories] += Array(data['categories'])
  taxonomy[lang][:tags] += Array(data['tags'])
end

taxonomy.each do |lang, sets|
  sets.each do |type, terms|
    terms.uniq.each do |term|
      slug = term.downcase.strip.gsub(' ', '-').gsub(/[^\w\-]/, '')
      filepath = File.join(lang, type.to_s, "#{term}.md")
      FileUtils.mkdir_p(File.dirname(filepath))
      File.write(filepath, <<~MARKDOWN)
        ---
        layout: #{LAYOUT}
        title: #{type.to_s.capitalize.chop}: #{term}
        #{type.to_s.chop}: #{term}
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        ---

        <h1>#{type.to_s.capitalize.chop}: #{term}</h1>
        <ul>
          {% assign posts = site.#{type}[page.#{type.to_s.chop}] | where: 'lang', '#{lang}' %}
          {% for post in posts %}
            <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
          {% endfor %}
        </ul>
      MARKDOWN
    end
  end
end
