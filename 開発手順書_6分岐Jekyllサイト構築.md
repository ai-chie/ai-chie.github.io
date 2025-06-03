
# 開発手順書：Jekyll 6分岐サイト構築支援

## 📌 プロジェクト概要

- GitHub Pages + Jekyll による静的サイト
- 6分岐構成：PC / モバイル / クローラー × 日本語 / 英語
- 自動タグ・カテゴリ処理、構成ツリーの自動生成、GitHub Actionsによるビルドを含む

## 🔗 基本情報

- GitHubリポジトリ: https://github.com/ai-chie/ai-chie.github.io
- 公開予定サイト: https://ai-chie.github.io/

## 📂 参考構成図

- 現状の構成: `構成図_202506031306.yml`
- 目標の構成: `予定構成図７.yml`

---

## 🧭 手順一覧（概要）

### Step 1: 構成図の差分確認
- `構成図_202506031306.yml` と `予定構成図７.yml` を比較し、変更点・不足点を明確化
- 各階層の __files__ や、pages, includes, data の構成一致を確認

### Step 2: Jekyllテンプレートの確認と分岐対応
- _layouts / _includes / _pages にあるテンプレートが PC/Mobile/Crawler + ja/en に対応しているか確認
- config_ymlファイル群（`_config_mobile.yml` など）の分岐設定確認

### Step 3: 自動生成機構の実装検証
- カテゴリ・タグ一覧の生成スクリプトが `_data/_generated/` に反映されているか
- GitHub Actionsにより、taxonomy生成・ディレクトリ構成JSON出力がされているか確認

### Step 4: データ設計と連携確認
- `_posts` と `_data` ディレクトリの連携性（言語・カテゴリ単位の整合性）
- `_admin` 内スクリプト（autofill系JS）の適用範囲と有効性確認

### Step 5: GitHub Actionsの整備
- `.github/workflows/` 以下のワークフローが有効に機能しているか
- トリガー（push, pull_request など）と生成対象の確認

### Step 6: 表示・出力確認
- サイトURLでの出力結果が分岐構成・多言語に対応しているか動作確認

---

## ✅ 今後の推奨タスク

| タスク名 | 概要 |
|----------|------|
| README最適化 | Deep Research向けに構造説明と目的を明記（既に修正案あり） |
| 各階層構成の正規化 | 同じ階層で __files__ が重複しないよう整理 |
| actionsのスリム化 | タスク単位に分離・エラー検知処理の追加 |
| 完成後のUX確認 | 多言語・モバイル対応のユーザビリティ検証 |

---

## 📎 備考

- 本手順書はAI補助により作成されています。実装状況に応じて適宜更新して下さい。
- 詳細な内容はDeep Research機能を通じて精査・改善できます。
