# 🧩 taxonomy schema.yml 仕様

## 属性一覧と用途

| 属性名               | 型     | 説明                                        |
|----------------------|--------|---------------------------------------------|
| taxonomy_name        | string | 表示名（slugにも使用）                      |
| taxonomy_hidden      | bool   | 非表示にする場合 true                       |
| taxonomy_draft       | bool   | 下書きとして未公開扱いにする                |
| taxonomy_private     | bool   | 非公開カテゴリ（管理者のみなど）            |
| taxonomy_featured    | bool   | 注目カテゴリ/タグ                          |
| taxonomy_beta        | bool   | ベータ扱いでUIにラベル表示される            |
| taxonomy_deprecated  | bool   | 廃止予定としてマークされる                  |
| taxonomy_audience    | string | 対象（internal / external）                |
| taxonomy_color       | string | 表示用カラーコード                         |
| taxonomy_icon        | string | 表示用アイコン                             |
| taxonomy_link        | string | カスタムリンクを張る場合                    |
| taxonomy_description | string | カテゴリやタグの説明文                     |

## データ構造（例）

```yaml
AI:
  items:
    - name: "GPT"
      taxonomy_description: "OpenAIの大規模言語モデル"
      taxonomy_icon: "🧠"
```