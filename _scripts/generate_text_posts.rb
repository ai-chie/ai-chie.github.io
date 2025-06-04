require 'fileutils'
require 'time'
require 'kramdown'

POSTS_DIR = "_posts/ja"
OUTPUT_DIR = "_pages/text/ja"

def extract_metadata(dir_name)
  if dir_name =~ /^(\d{4}-\d{2}-\d{2})-T(\d{6})([+-]\d{4})-(.+)-ja$/
    date = "#{$1}T#{$2[0..1]}:#{$2[2..3]}:#{$2[4..5]}#{$3}"
    uuid = "#{$1}-T#{$2}#{$3}-#{$4}"
    return [uuid, date]
  end
  nil
end

def extract_body_without_front_matter(file_path)
  content = File.read(file_path, encoding: 'utf-8')
  content.sub(/\A---\s*.*?---\s*/m, '') # YAML front matter を除去
end

Dir.entries(POSTS_DIR).each do |dir_name|
  next if dir_name.start_with?('.') || !File.directory?(File.join(POSTS_DIR, dir_name))

  metadata = extract_metadata(dir_name)
  next unless metadata

  uuid, iso_date = metadata
  post_file = File.join(POSTS_DIR, dir_name, "#{uuid}-ja.md")
  next unless File.exist?(post_file)

  body_md = extract_body_without_front_matter(post_file)
  body_html = Kramdown::Document.new(body_md).to_html

  output_path = File.join(OUTPUT_DIR, uuid, "index.html")
  FileUtils.mkdir_p(File.dirname(output_path))

  File.open(output_path, "w:utf-8") do |f|
    f.puts <<~HTML
      ---
      layout: text-post
      lang: ja
      device: text
      title: "#{uuid}"
      description: ""
      date: #{iso_date}
      ---

      #{body_html}
    HTML
  end
end
