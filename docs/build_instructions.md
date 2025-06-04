# 🛠 Jekyll ビルド & プレビュー手順書

## ローカルビルド手順

```bash
bundle install
bundle exec jekyll build
```

### モード別ビルド

```bash
JEKYLL_ENV=production bundle exec jekyll build --config _config.yml,_config_text.yml
```

## サーバープレビュー

```bash
bundle exec jekyll serve --livereload
```

## ビルド対象構成ファイル（例）

- `_config.yml`（デフォルト）
- `_config_text.yml`（text/モード用）
- `_config_mobile.yml`（モバイル表示用）