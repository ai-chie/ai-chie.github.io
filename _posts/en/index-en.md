---
layout: default
title: Home
---

<!-- en/index.md -->
<h1>Welcome</h1>
<p>This is the English version of the homepage.</p>
{% include lang_switch.html %}

<h2>Categories</h2>
<ul>
  {% assign en_categories = site.categories | where_exp: "cat", "cat[1].first.lang == 'en'" %}
  {% for category in en_categories %}
    <li><a href="/en/categories/{{ category[0] | slugify }}/">{{ category[0] }}</a></li>
  {% endfor %}
</ul>

<h2>Tags</h2>
<ul>
  {% assign en_tags = site.tags | where_exp: "tag", "tag[1].first.lang == 'en'" %}
  {% for tag in en_tags %}
    <li><a href="/en/tags/{{ tag[0] | slugify }}/">{{ tag[0] }}</a></li>
  {% endfor %}
</ul>

<h2>Posts</h2>
<ul>
  {% assign en_posts = site.posts | where: 'lang', 'en' %}
  {% for post in en_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
      {% if post.categories.size > 0 %} [Category: {{ post.categories | join: ', ' }}]{% endif %}
      {% if post.tags.size > 0 %} [Tags: {{ post.tags | join: ', ' }}]{% endif %}
    </li>
  {% endfor %}
</ul>

