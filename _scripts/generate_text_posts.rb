require 'fileutils'
require 'yaml'
require 'kramdown'

DEVICES = %w[text]          # 将来は ["pc", "mobile", "text"]
LANGS = %w[ja en]           # 言語対応
POSTS_ROOT = "_posts"
OUTPUT_ROOT = "_pages"

def extract_metadata(dir_name)
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
    uuid, iso_date, detected_lang = extract_metadata(dir_name)
    next unless detected_lang == lang

    filename = "#{uuid}-#{lang}.md"
    post_path = File.join(POSTS_DIR, dir_name, filename)
    next unless File.exist?(post_path)

    content_md = File.read(post_path, encoding: 'utf-8').sub(/\A---\s*.*?---\s*/m, '')
    content_html = Kramdown::Document.new(content_md).to_html

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

        #{content_html.strip}
      HTML
    end
  end
end
