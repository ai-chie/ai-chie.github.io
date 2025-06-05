require 'fileutils'
require 'yaml'
require 'kramdown'

DEVICES     = %w[text]
LANGS       = %w[ja en]
POSTS_ROOT  = "_posts"
OUTPUT_ROOT = "_pages"

def extract_metadata(dir_name)
  # 例: 2025-05-30-T135040+0900-UUID-ja
  if dir_name =~ /^(\d{4}-\d{2}-\d{2})-T(\d{6})([+-]\d{4})-(.+)-(.+)$/
    date = "#{$1}T#{$2[0..1]}:#{$2[2..3]}:#{$2[4..5]}#{$3}"
    uuid = "#{$1}-T#{$2}#{$3}-#{$4}"
    lang = $5
    return [uuid, date, lang]
  end
  nil
end

LANGS.each do |lang|
  POSTS_DIR = "#{POSTS_ROOT}/#{lang}"

  Dir.entries(POSTS_DIR).each do |dir_name|
    next if dir_name.start_with?('.') || !File.directory?(File.join(POSTS_DIR, dir_name))

    metadata = extract_metadata(dir_name)
    next unless metadata

    uuid, iso_date, detected_lang = metadata
    next unless detected_lang == lang

    filename = "#{uuid}-#{lang}.md"
    post_path = File.join(POSTS_DIR, dir_name, filename)
    next unless File.exist?(post_path)

    body_md = File.read(post_path, encoding: 'utf-8').sub(/\A---\s*.*?---\s*/m, '')
    body_html = Kramdown::Document.new(body_md).to_html

    DEVICES.each do |device|
      output_dir = File.join(OUTPUT_ROOT, device, lang, uuid)
      FileUtils.mkdir_p(output_dir)
      File.write(File.join(output_dir, "index.html"), <<~HTML)
        ---
        layout: text-post
        lang: #{lang}
        device: #{device}
        title: "#{uuid}"
        description: ""
        date: #{iso_date}
        permalink: /#{device}/#{lang}/#{uuid}/index.html
        ---

        #{body_html.strip}
      HTML
    end
  end
end
