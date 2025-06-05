require 'fileutils'

DEVICES = %w[text]     # 拡張可能: %w[text pc mobile]
LANGS   = %w[ja en]

DEVICES.each do |device|
  LANGS.each do |lang|
    output_path = "_pages/#{device}/#{lang}/categories/index.html"
    FileUtils.mkdir_p(File.dirname(output_path))

    File.write(output_path, <<~TEXT)
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
