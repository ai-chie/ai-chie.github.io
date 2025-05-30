---
layout: default
title: タグ: サンプル
tag: サンプル
permalink: /ja/tags/サンプル/
lang: ja
---

<!-- ja/tags/サンプル.md -->
<h1>タグ: サンプル</h1>
<p>{{ site.data.tags.ja[page.tag] | default: 'このタグに関する記事を紹介します。' }}</p>
<ul>
  {% assign tag_posts = site.tags[page.tag] | where: 'lang', 'ja' %}
  {% assign visible_tag_posts = tag_posts | where_exp: "post", "post.hidden != true and post.draft != true" %}
  {% for post in visible_tag_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>
