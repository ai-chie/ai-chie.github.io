require 'fileutils'
require 'time'

# 各種定義
TEXT_DIR = '_pages/text/ja'
SITEMAP_PATH = 'sitemap_text.xml'
BASE_URL = 'https://ai-chie.github.io/text/ja'

# 対象のHTMLファイル一覧を取得
paths = Dir.glob("#{TEXT_DIR}/**/index.html")

# サイトマップのXML構築
xml = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
XML

paths.each do |path|
  relative_path = path.sub(/^#{TEXT_DIR}/, '').sub(/\/index\.html$/, '')
  url = "#{BASE_URL}#{relative_path}/"
  xml << "  <url><loc>#{url}</loc></url>\n"
end

xml << "</urlset>\n"

# 出力
File.write(SITEMAP_PATH, xml)
puts "✅ sitemap_text.xml を生成しました（#{paths.size}件）"

