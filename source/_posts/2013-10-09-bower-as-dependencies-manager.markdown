---
layout: post
title: "bower as dependencies manager"
date: 2013-10-09 16:38
comments: true
categories: 
- JavaScript
- Lightweight

---
### Bower简介

#### Bower安装及简单配置

[Bower](http://bower.io/)是一个基于Node.js的依赖管理工具，它是一个npm的包，因此安装十分简单，由于我们需要在所有项目中都可以使用bower，因此将其安装在全局目录下：

```
$ npm install -g bower
```

安装完成之后，可以通过`bower search`来搜索需要的包，比如：

```
$ bower search underscore
```

典型的应用场景可能会是这样的，新建一个项目目录，然后运行`bower init`：

```
$ mkdir -p listing
$ cd listing
$ bower init
```
和Grunt类似，bower会问你一些问题，比如项目名称，项目入口点，作者信息之类：

```
{
  "name": "listing",
  "version": "0.0.0",
  "authors": [
    "Qiu Juntao <juntao.qiu@gmail.com>"
  ],
  "main": "src/app.js",
  "license": "MIT",
  "ignore": [
    "**/.*",
    "node_modules",
    "bower_components",
    "test",
    "tests"
  ]
}
```

比如我们需要安装jQuery和underscore.js，则很简单的运行`bower install`命令即可：

```
$ bower install jquery
$ bower install underscore
```

如果需要团队中的其他成员可以在本地恢复我们的环境，需要在bower.json中指定`dependencies`小节：

```
  "dependencies": {
    "jquery": "~2.0.3",
    "underscore": "~1.5.2"
  }
```

所有的JavaScript包都被安装到了本地的`bower_components`目录下，如果有了bower.json文件，那么即使本地的`bower_components`目录不存在，或者其中的包内容过期了，那么很容易用`bower install`将其更新。

