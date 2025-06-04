require 'fileutils'

DEVICES = %w[text]           # 今後 'pc', 'mobile' にも拡張可能
LANGS = %w[ja en]            # 多言語対応

DEVICES.each do |device|
  LANGS.each do |lang|
    output_path = "_pages/#{device}/#{lang}/categories/index.html"
    FileUtils.mkdir_p(File.dirname(output_path))

    File.open(output_path, "w:utf-8") do |f|
      f.puts <<~TEXT
        ---
        layout: text
        lang: #{lang}
        device: #{device}
        title: "カテゴリ一覧 - #{lang.upcase} - #{device.capitalize}"
        description: "このページは#{lang.upcase}の#{device}デバイス向けカテゴリ一覧です。"
        permalink: /#{device}/#{lang}/categories/index.html
        ---

        {% include taxonomy-list-text.html type="categories" lang="#{lang}" %}
      TEXT
    end
  end
end
