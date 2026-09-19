---
layout: page
permalink: /publications/
title: publications
description: Peer-reviewed publications, in reverse chronological order.
nav: true
nav_order: 2
---

<!-- _pages/publications.md -->

<!-- Bibsearch Feature -->

{% include bib_search.liquid %}

<script src="{{ '/assets/js/publication-sort.js' | relative_url | bust_file_cache }}"></script>
<style>
  .publication-sort-toolbar .btn.active {
    background-color: var(--global-theme-color);
    color: var(--global-hover-text-color);
  }
</style>

<div class="publications">

{% bibliography %}

</div>
