require 'fileutils'

DEVICES = %w[text]           # 今後 'pc', 'mobile' も対応可
LANGS = %w[ja en]

DEVICES.each do |device|
  LANGS.each do |lang|
    output_path = "_pages/#{device}/#{lang}/tags/index.html"
    FileUtils.mkdir_p(File.dirname(output_path))

    File.open(output_path, "w:utf-8") do |f|
      f.puts <<~TEXT
        ---
        layout: text
        lang: #{lang}
        device: #{device}
        title: "タグ一覧 - #{lang.upcase} - #{device.capitalize}"
        description: "このページは#{lang.upcase}の#{device}デバイス向けタグ一覧です。"
        permalink: /#{device}/#{lang}/tags/index.html
        ---

        {% include taxonomy-list-text.html type="tags" lang="#{lang}" %}
      TEXT
    end
  end
end
