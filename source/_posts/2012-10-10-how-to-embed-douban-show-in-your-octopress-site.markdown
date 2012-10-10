---
layout: post
title: "How to embed Douban-Show in your octopress site"
date: 2012-10-10 21:08
comments: true
categories: 
---
### What do you need?
* A valid douban account of course
* octopress site

### Step by step
Let's do it step by step:
Login your douban account at first, and then try to access this [link](http://www.douban.com/service/badgemakerjs), then you'll prabobly get a similar script like this:

    <script type="text/javascript" src="http://www.douban.com/service/badge/4023370/?show=collection&amp;n=8&amp;columns=2" ></script>

and then simply create a new file under the following path(in octopress repo):

    $ touch source/_includes/asides/douban.html

and then add the link you generated and fulfill it in the following structure:

    {% if site.douban_user %}
    <section>
    <h2>What did I read</h2>
    <div>
        <script type="text/javascript" src="http://www.douban.com/service/badge/4023370/?show=collection&amp;n=8&amp;columns=2" ></script>
    </div>
    </section>
    {% endif %}

finally, add the page path in *_config.html*:

    default_asides: [..., asides/douban.html, ...]

now you are done.

