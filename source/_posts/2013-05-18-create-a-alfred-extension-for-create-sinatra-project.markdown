---
layout: post
title: "Alfred简介及Alfred扩展编写"
date: 2013-05-18 20:04
comments: true
categories: 
- ruby
- tools
- productivity

---

###Alfred简介

[Alfred](http://www.alfredapp.com/)是Mac下的一个小工具，可以极大的提高使用计算机的效率。Alfred提供非常丰富的功能集，比如：

1.	基本的文件/目录查找功能
2.	应用程序加载器
3.	快速的搜索（google，wikipedia）

![使用Alfred搜索](http://abruzzi.github.com/images/2013/05/alfred-find.png)

####powerpack

Alfred本身是免费的，但是一些高级的功能，如：

1.	自定义扩展（**非常有用**）
2.	剪贴板栈/代码片段管理（**非常有用**）
3.	iTunes控制
4.	近期访过的文档

提供在[powerpack](http://www.alfredapp.com/powerpack/)中，这个功能是要收费的，不过个人觉得绝对的物超所值。这些功能可以极大的提高我对计算机的使用效率，而且剪贴板栈功能可以节省我很多的时间。

![image](http://abruzzi.github.com/images/2013/05/alfred-clipboard.png)

###扩展编写

经常会使用[sinatra](http://www.sinatrarb.com/)编写一些简单的Web应用程序，以用作一些showcase和应用程序的原型搭建。但是由于sinatra并不是一个框架，并不会像rails那样自动生成目录结构等，而每个sinatra应用的目录结构和文件依赖都非常相似，因此完全可以考虑将这个过程自动化。

基本思路是：

1.	定义一个目录结构的模板
2.	每次开始一个sinatra工程时，将个模板目录拷贝到新的工程下
3.	一些库依赖的下载（bundle install以及JavaScript库的下载）
4.	在编辑器中打开这个新的目录

####一个sinatra工程的原型

```
$ pwd
/Users/twer/develop/templates/sinatra

$ tree -a
.
├── .rvmrc
├── Gemfile
├── app.rb
├── config.ru
├── public
│   ├── css
│   └── scripts
│       ├── app.js
│       └── libs
└── views
```

####Extension shell script

```
# create the project folder
cd ~/develop/ruby && mkdir -p {query} && cd {query}

# cp info to folder
cp -R ~/develop/templates/sinatra/ .

# grab jquery
curl http://code.jquery.com/jquery.js > public/scripts/libs/jquery.js

# open the project
/Applications/MacVim.app/Contents/MacOS/Vim -g .
```

![image](http://abruzzi.github.com/images/2013/05/sinatra-ext-result.png)

执行完之后，`~/develop/ruby`下会生成一个新的目录，即`note`，这个目录中即为一个可以直接开始开发sinatra应用的工作目录了。