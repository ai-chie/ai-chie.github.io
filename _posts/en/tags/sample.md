---
layout: default
title: Tag: Sample
tag: Sample
permalink: /en/tags/sample/
lang: en
---

<!-- en/tags/sample.md -->
<h1>Tag: Sample</h1>
<ul>
  {% assign tag_posts = site.tags[page.tag] | where: 'lang', 'en' %}
  {% assign visible_tag_posts = tag_posts | where_exp: "post", "post.hidden != true and post.draft != true" %}
  {% for post in visible_tag_posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a> - {{ post.date | date: "%Y-%m-%d" }}
    </li>
  {% endfor %}
</ul>
