---
layout: post
title: "发布你的Web设计"
date: 2014-11-21 22:24
comments: true
categories: 
- Web Design
- Github
---

### Github的`主页服务`

Github提供了[Github Pages](https://help.github.com/articles/user-organization-and-project-pages/)的服务来帮助你为自己的项目提供`主页`。目前，这种主页服务分为两种：`用户主页`和`项目主页`。其中`用户主页`已经称为广大开发者的标配，有很多的开发者已经将自己的博客迁移到了Github上，其中所用到的核心机制就是`Github Pages`。

这篇文章主要介绍如何使用`项目主页`。`项目主页`，顾名思义，就是你项目的主页，本来设计的初衷是为你的项目编写介绍文档，不过Github只提供对静态内容的托管。如果需要添加评论，可以使用[disqus](https://disqus.com/home/)的服务，而和微博，flickr等集成都有现成的JavaScript片段，这里也不做详细讨论。

你现在正在看的我的博客正是托管在Github上，不过我对域名进行了自定义而已，如何做到这一点可以[查看此处](https://help.github.com/articles/tips-for-configuring-a-cname-record-with-your-dns-provider/)的文档。

我之前发布的一个`我去过的地方`就使用了`项目主页`的服务，该项目的[地址在此](https://github.com/abruzzi/placesihavebeen)，[最终的页面](http://icodeit.org/placesihavebeen/)在这里。

![places I have been](/images/2014/11/places-i-have-been-resized.png)

#### Web设计样板工程

我在Github上创建了一个[设计样板工程](https://github.com/abruzzi/design-boilerplate)，你可以使用这个工程快速的搭建一个完整的样板工程，其中包含了：

1.	一个基本的HTML5的文档
2.	SCSS环境
3.	Guard环境，可以与LiveReload集成

具体的操作可以[参看文档](https://github.com/abruzzi/design-boilerplate/blob/master/README.md)。

#### 发布你的Web设计

Github提供的`项目主页服务`可以帮助你快速将设计发布，你所需要做的就是为项目创建一个名叫`gh-pages`的分支，然后将`HTML/CSS/JS`放在这个分支上即可。

假设你在github上的用户名为`wumai`(一时间想不到好名字，看看窗外，就叫**雾霾**吧)，那么根据惯例，你的Github地址为`https://github.com/wumai`。这时候，假设你的项目（repo）的名称为`design-1`，则你的`项目主页地址`为`https://wumai.github.io/design-1`。

知道了你的`项目主页地址`，你就需要为这个页面添加内容了：

```sh
$ git clone git@github.com:abruzzi/design-boilerplate.git design-1
```

克隆了`design-boilerplate`之后，

```sh
$ cd design-1
$ git remote -v
```

你可以看到当前的项目是和`git@github.com:abruzzi/design-boilerplate.git`关联的，

```
origin	git@github.com:abruzzi/design-boilerplate.git (fetch)
origin	git@github.com:abruzzi/design-boilerplate.git (push)
```

你需要先和这个样板工程解除绑定：

```sh
$ git remote remove origin
```

然后你需要在Github上创建一个新的Repo，假设命名为`design-1`，这时候，将这个新创建的Repo作为你本地的remote：

```sh
$ git remote add -u origin git@github.com:wumai/design-1.git
```

与远程连接之后，我们可以开始实际的设计了，不过在这之前，需要先创建一个`gh-pages`分支：

```sh
$ git checkout -b gh-pages
```

这条命令会创建`gh-pages`分支，并切换到该分支，这样后续的修改都会在该分支进行，这也正是我们想要的。开发调试之后，就可以将这个分支push到Github：

```sh
$ git push -u origin gh-pages
```

好了，现在打开地址`http://wumai.github.io/design-1`，应该就可以看到你自己的设计了。

![web design](/images/2014/11/web-design-resized.png)