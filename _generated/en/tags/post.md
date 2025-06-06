---
layout: default
title: Tag: Post
tag: Post
permalink: /en/tags/post/
lang: en
---

<h1>Tag: Post</h1>
<p>{{ site.data.taxonomy.tags.en['Post'].taxonomy_description | default: 'このTagに関する記事を紹介します。' }}</p>

{% assign posts = site.tags[page.tag] | where: 'lang', 'en' | where_exp: 'post', 'post.hidden != true and post.draft != true' %}

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
<p>現在このTagに該当する記事はありません。</p>
{% endif %}
