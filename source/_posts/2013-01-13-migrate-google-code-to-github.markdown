---
layout: post
title: "将Google Code上的项目迁移到Github"
date: 2013-01-13 23:28
comments: true
categories: 
- opensource
- tools
tags: [opensource, tools]

---
###一些闲话

虽然对开源社区没有任何杰出的贡献，但是我自己在业余时间开发的很多小东西都是开源的，有部分放在google code上，可是除了一个[sTodo](http://code.google.com/p/stodo/)有几个用户外，其他的工具几乎都纯属自娱自乐。虽然当时做的时候自己非常投入，会各种YY，假设用户会需要这个功能，会需要那个功能，用户会需要脚本化，自定义插件等等，但是到最后发现只有自己在使用，而再过一段时间，连自己也不会使用了。

我自己托管在google code上的，还算有点用处的项目有三个：

- [sTodo](http://code.google.com/p/stodo/) 一个简单的todo管理器
- [phoc](http://code.google.com/p/phoc/) 一个可以用JavaScript脚本化的计算器
- [utouch](http://code.google.com/p/utouch) 一个使用styledTextCtrl的编辑器

虽然这种事情发生在几乎每一个喜欢写程序的家伙身上，但是整个过程对自我修炼来说，还是非常有现实意义的，首先专业技能得到了锻炼，而最重要的一点是：需求不是想象出来的！在没有和用户真正仔细的讨论之前，我们的假设和推断往往是错的。

Idea到处都是，有很多很酷且很有挑战的idea，但是它们不一定真的在解决人们的问题。这是一个很值得思考的问题，我最近在尝试组织一个活动，主题以及目标已经确定，上周找胡凯帮我把关，结果发现我又一次的进入了“帮助用户想需求”的老路上了。

###迁移

####使用svn同步到本地

根据google code的提示，将code从svn中的checkout到本地：

```
svn checkout http://phoc.googlecode.com/svn phoc-read-only
```

####去除掉.svn隐藏目录

现使用`find`在当前目录下找到名称为.svn的目录，然后将其删除，这个过程是递归的，即可以清除掉当前目录及所有子目录中的.svn目录:

```
find . -name ".svn" -type d -exec rm -rf {} \;
```

####初始化git的repo

```
git init
git add .
git ci -m "migrate of project xxx to github"
```

然后对应的在github上创建repo，创建之后，需要将本地的remote指向github上的repo:

```
git remote add origin git@github.com:project/project.git
```

如果本地的master分支没有配置，可以在`.git/config`中进行配置：

```
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

最后将新的commit push到新的repo上即可：

```
git pull --rebase
git push
```

我已经把这个工具迁移到了github上[abruzzi](https://github.com/abruzzi)，正式告别了google code。