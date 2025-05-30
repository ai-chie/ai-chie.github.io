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
  {% for post in category_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>

