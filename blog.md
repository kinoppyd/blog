---
layout: blog
title: "kinoppyd dev"
permalink: /blog
pagination:
  enabled: true
---


<!-- Pagination links -->
<div class="pagination text-center mb-8 md:mb-16">
  <span class="page_number ">
    Page: {{ paginator.page }} of {{ paginator.total_pages }}
  </span>
  {% if paginator.previous_page %}
    <a href="{{ paginator.previous_page_path }}" class="previous">
      Previous
    </a>
  {% endif %}
  {% if paginator.previous_page and paginator.next_page %}
    <span> - </span>
  {% endif %}
  {% if paginator.next_page %}
    <a href="{{ paginator.next_page_path }}" class="next">Next</a>
  {% endif %}
</div>

<!-- This loops through the paginated posts -->
{% for post in paginator.posts %}
  <h1><a href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a></h1>
  <p class="author">
    <span class="date">{{ post.date }}</span>
  </p>
  <div class="content">
    {{ post.excerpt }}
  </div>
  {% if forloop.last == false   %}
    <hr class="w-100 h-1 mx-48 my-16 bg-gray-200" />
  {% endif %}
{% endfor %}

<!-- Pagination links -->
<div class="pagination text-center mt-8 md:mt-16">
  <span class="page_number ">
    Page: {{ paginator.page }} of {{ paginator.total_pages }}
  </span>
  {% if paginator.previous_page %}
    <a href="{{ paginator.previous_page_path }}" class="previous">
      Previous
    </a>
  {% endif %}
  {% if paginator.previous_page and paginator.next_page %}
    <span> - </span>
  {% endif %}
  {% if paginator.next_page %}
    <a href="{{ paginator.next_page_path }}" class="next">Next</a>
  {% endif %}
</div>