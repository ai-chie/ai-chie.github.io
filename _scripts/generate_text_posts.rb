require 'fileutils'
require 'time'

POSTS_DIR = "_posts/ja"
OUTPUT_DIR = "_pages/text/ja"

def extract_metadata(dir_name)
  # 例: 2025-05-30-T135040+0900-UUID-ja
  if dir_name =~ /^(\d{4}-\d{2}-\d{2})-T(\d{6})([+-]\d{4})-(.+)-ja$/
    date = "#{$1}T#{$2[0..1]}:#{$2[2..3]}:#{$2[4..5]}#{$3}"
    uuid = "#{$1}-T#{$2}#{$3}-#{$4}"
    return [uuid, date]
  end
  nil
end

Dir.entries(POSTS_DIR).each do |dir_name|
  next if dir_name.start_with?('.') || !File.directory?(File.join(POSTS_DIR, dir_name))

  metadata = extract_metadata(dir_name)
  next unless metadata

  uuid, iso_date = metadata
  post_file = File.join(POSTS_DIR, dir_name, "#{uuid}-ja.md")
  next unless File.exist?(post_file)

  output_path = File.join(OUTPUT_DIR, uuid, "index.html")
  FileUtils.mkdir_p(File.dirname(output_path))

  File.open(output_path, "w:utf-8") do |f|
    f.puts <<~MARKDOWN
      ---
      layout: text-post
      lang: ja
      device: text
      title: "#{uuid}"
      description: ""
      date: #{iso_date}
      ---

      {% capture original %}
        {% include_relative ../../../_posts/ja/#{uuid}/#{uuid}-ja.md %}
      {% endcapture %}
      {{ original | markdownify }}
    MARKDOWN
  end
end

