---
layout: default
title: Category: Test
category: Test
permalink: /en/categories/test/
lang: en
---

<!-- en/categories/test.md -->
<h1>Category: Test</h1>
<p>{{ site.data.categories.en[page.category] | default: 'This category includes posts related to this topic.' }}</p>

<h2>Featured Articles</h2>
<ul>
  {% assign category_posts = site.categories[page.category] | where: 'lang', 'en' %}
  {% assign visible_category_posts = category_posts | where_exp: "post", "post.hidden != true and post.draft != true" %}
  {% for post in visible_category_posts limit: 2 %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>

<h2>All Posts</h2>
<ul>
  {% for post in visible_category_posts offset: 2 %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>
