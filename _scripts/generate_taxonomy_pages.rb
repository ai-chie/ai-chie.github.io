def resolve_schema_value(meta, lang)
  val = meta['default']
  if val.is_a?(Hash)
    val[lang] || val.values.first
  else
    case meta['type']
    when 'string'  then val.to_s
    when 'integer' then val.to_i
    when 'boolean' then !!val
    when 'enum'
      meta['values']&.include?(val) ? val : meta['values']&.first
    else val
    end
  end
end
