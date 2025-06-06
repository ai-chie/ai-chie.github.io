---
layout: default
title: Categorie: Test
categorie: Test
permalink: /en/categories/test/
lang: en
---

<h1>Categorie: Test</h1>
<p>{{ site.data.taxonomy.categories.en['Test'].taxonomy_description | default: 'このCategorieに関する記事を紹介します。' }}</p>

{% assign posts = site.categories[page.categorie] | where: 'lang', 'en' | where_exp: 'post', 'post.hidden != true and post.draft != true' %}

{% if posts.size > 0 %}
<h2>おすすめ記事</h2>
<ul>
  {% for post in posts limit: 2 %}
    <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
  {% endfor %}
</ul>

<h2>すべての記事</h2>
<ul>
  {% for post in posts offset: 2 %}
    <li><a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}</li>
  {% endfor %}
</ul>
{% else %}
<p>現在このCategorieに該当する記事はありません。</p>
{% endif %}
