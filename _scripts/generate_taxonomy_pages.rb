# ... 省略: require など先頭部は以前と同じ ...

# 安全な stringify_keys 実装
def stringify_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), h|
      h[k.to_s] = stringify_keys(v)
    end
  when Array
    obj.map { |v| stringify_keys(v) }
  else
    obj
  end
end

# ... parse_front_matter, generate_slug など関数も同様（省略） ...

# ---------------- MAIN 処理（taxonomy構築ループ） ----------------
generated = {}

taxonomy.each do |lang, types|
  generated[lang] = {}

  types.each do |type, terms|
    items = []
    key = type.chop

    terms.uniq.sort.each do |name|
      slug, source = generate_slug(name, lang, used_slugs, overrides, missing, conflicts, type)

      normalized_key = name.to_s.strip.downcase
      dict_map = taxonomy_definitions.dig(lang, type) || {}

      matched_entry = dict_map.find { |k, _| k.to_s.strip.downcase == normalized_key }&.last
      verified_name = matched_entry ? matched_entry["taxonomy_name"] : "unknown"

      puts "[DEBUG] verified_name for #{lang}/#{type}/#{name}: #{verified_name}"

      item = {
        'taxonomy_name' => verified_name,
        'taxonomy_slug' => slug,
        'slug_source'   => source,
        'count'         => counts[lang][type][name]
      }

      schema.each do |attr, meta|
        next if meta['unused']
        item[attr] = resolve_schema_value(meta, lang)
      end

      items << item

      md_path = File.join(OUTPUT_ROOT, lang, type, "#{slug}.md")
      FileUtils.mkdir_p(File.dirname(md_path))
      File.write(md_path, <<~MD)
        ---
        layout: #{LAYOUT}
        title: "#{key.capitalize}: #{name}"
        #{key}: "#{name}"
        permalink: /#{lang}/#{type}/#{slug}/
        lang: #{lang}
        slug_source: #{source}
        ---
      MD
    end

    generated[lang][type] = items
  end
end

# ---------------- 検証 & 出力 ----------------
puts "[CHECK] Final taxonomy output structure:"
pp generated

puts "[CHECK] Individual taxonomy items:"
generated.each do |lang, types|
  types.each do |type, items|
    puts "== #{lang} / #{type} =="
    items.each { |i| pp i }
  end
end

puts "[LOG] Writing taxonomy YAML..."; STDOUT.flush
FileUtils.mkdir_p(File.dirname(TAXONOMY_YML))
File.write(TAXONOMY_YML, stringify_keys(generated).to_yaml)
File.write(MISSING_TERMS_FILE, stringify_keys(missing).to_yaml)
File.write(CONFLICT_FILE, stringify_keys(conflicts).to_yaml)
puts "[DONE] All YAML files written."; STDOUT.flush
