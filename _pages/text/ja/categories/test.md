---
# _data/taxonomy/{type}.yml, _data/taxonomy/taxonomy_schema.yml
device: # 設定がない場合はpathから取得
lang: ja # 設定がない場合はpathから取得
type: # 設定がない場合はpathから取得
slug: test
name: # 設定がない場合は_data/taxonomy/{type}.ymlから取得（slugで照合）
description: # 設定がない場合は_data/taxonomy/{type}.ymlから取得（slugで照合）
icon: ""
priority: 5
featured: true
output_pc: true # trueで出力。{device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
layout: text-taxonomy # {device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
permalink: /pc/ja/categories/test/ # {device}/{lang}/{type}/にコピペする時に備え事前に全てのdevice用を設定
output_mobile: true
layout_mobile: text-taxonomy
permalink_mobile: /mobile/ja/categories/test/
output_text: true
layout_text: text-taxonomy
permalink_text: /text/ja/categories/test/
---

ここで個別投稿のリストが表示される
