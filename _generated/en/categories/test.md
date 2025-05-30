---
layout: default
title: Category: Test
category: Test
permalink: /en/categories/test/
lang: en
---

<!-- en/categories/test.md -->
<h1>Category: Test</h1>
<ul>
  {% assign category_posts = site.categories[page.category] | where: 'lang', 'en' %}
  {% assign visible_category_posts = category_posts | where_exp: "post", "post.hidden != true and post.draft != true" %}
  {% for post in visible_category_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>
