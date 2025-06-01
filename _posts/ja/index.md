---
layout: default
title: ホーム
---

<!-- ja/index.md -->
<h1>ようこそ</h1>
<p>これは日本語版のトップページです。</p>
{% include lang_switch.html %}

<h2>カテゴリ一覧</h2>
<ul>
  {% assign ja_categories = site.categories | where_exp: "cat", "cat[1].first.lang == 'ja'" %}
  {% for category in ja_categories %}
    <li><a href="/ja/categories/{{ category[0] | slugify }}/">{{ category[0] }}</a></li>
  {% endfor %}
</ul>

<h2>タグ一覧</h2>
<ul>
  {% assign ja_tags = site.tags | where_exp: "tag", "tag[1].first.lang == 'ja'" %}
  {% for tag in ja_tags %}
    <li><a href="/ja/tags/{{ tag[0] | slugify }}/">{{ tag[0] }}</a></li>
  {% endfor %}
</ul>

<h2>記事一覧</h2>
<ul>
  {% assign ja_posts = site.posts | where: 'lang', 'ja' %}
  {% for post in ja_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
      {% if post.categories.size > 0 %} [カテゴリ: {{ post.categories | join: ', ' }}]{% endif %}
      {% if post.tags.size > 0 %} [タグ: {{ post.tags | join: ', ' }}]{% endif %}
    </li>
  {% endfor %}
</ul>
