---
layout: post
title: "First post of github blog (powered by octopress)"
date: 2012-10-08 23:13
comments: true
categories: 
---

## What is Octopress anyway
Here is a short description from [octopress.org](http://octopress.org/):
>    Octopress is a framework designed by Brandon Mathis for Jekyll, the blog aware static site generator powering Github Pages. To start blogging with Jekyll, you have to write your own HTML templates, CSS, Javascripts and set up your configuration. But with Octopress All of that is already taken care of. Simply clone or fork Octopress, install dependencies and the theme, and you’re set.

## How to configure octopress
The document presented by octopress itself is really great, you car refer [How to deploying to github](http://octopress.org/docs/deploying/github/) for more details (as what I did).

## I found a weird issue when try to generate
### FIX for Lion's posix_spawn_ext.bundle: [BUG] Segmentation fault
First delete the ruby
    rvm remove ruby-1.9.3 --gems --archive
then
    echo $CC
should return none.

finally, reinstall all stuff
    CC=/usr/bin/gcc-4.2 rvm install ruby-1.9.2
    gem install bundler
    bundle install
should fix the error.

