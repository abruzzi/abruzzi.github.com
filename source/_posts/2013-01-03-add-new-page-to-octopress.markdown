---
layout: post
title: "为octopress添加新的页面(page)"
date: 2013-01-03 17:38
comments: true
categories: 
- blog
tags: []

---
我之前在wordpress中有一些页面(page)，在迁移到octopress之后都不见了，早就想把这些页面show出来了，最终都被我以各种理由拖到了今天。

### 布局
一个典型的octopress博客的source目录布局大概是这样：

```
source/
├── _attachments
├── _includes
│   ├── asides
│   ├── custom
│   │   └── asides
│   └── post
├── _layouts
├── _nav_menu_items
├── _pages
├── _posts
├── blog
│   └── archives
├── font
├── images
│   ├── 2012
│   │   ├── 01
│   │   ├── 02
│   ├── 2013
│   │   └── 01
│   ├── fancybox
│   └── social
├── javascripts
│   ├── asides
│   └── libs
├── jsccp
└── stylesheets
    ├── bootstrap
    └── syntax
```    

对应的，当执行

```
$ rake generate
```

时，source下面的markdown会被编译为html，并拷贝到public下，public目录下的结构跟source下一致，里边的内容为最终的静态页面。因此我们需要修改souce中的内容，然后generate/deploy即可。

### 添加页面(page)

在octopress中，已经有两个默认page，即blog/archives，我们可以参考它来完成自己的页面，首先在source中创建一个目录，比如叫做**jsccp**([JavaScript Core Concepts and Practices](http://abruzzi.github.com/jsccp))，然后在这个目录中放入一个名叫index.markdown的文件即可。

将需要的内容放入这个文件即可完成页面(page)的编辑。但是我们还需要在首页上将这个页面的链接暴露出来，这一步需要编辑`source/_includes/custom/navigation.html`


	<ul class="main-navigation">
  		<li><a href="{{ root_url }}/">Blog</a></li>
  		<li><a href="{{ root_url }}/blog/archives">Archives</a></li>
  		<li><a href="{{ root_url }}/jsccp">JavaScript内核系列</a></li>
	</ul>
	
我为这个文件添加了一个新行，指向新创建的目录(此处不需要指定到index.markdown或者index.html)，这样就设置完成了。

尝试`rake generate`然后`rake preview`，如果一起正常，就可以`rake deploy`部署到github上了。

###效果图

![image](http://abruzzi.github.com/images/2013/01/navigation.png)
