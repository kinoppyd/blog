---
layout: blog
title: "kinoppyd dev"
permalink: /blog
pagination:
  enabled: true
---


<!-- Pagination links -->
<div class="pagination mb-8 text-center text-sm font-medium sm:mb-12 sm:text-base">
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
    <hr class="my-12 h-px w-full bg-gray-200" />
  {% endif %}
{% endfor %}

<!-- Pagination links -->
<div class="pagination mt-8 text-center text-sm font-medium sm:mt-12 sm:text-base">
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
