---
layout: post
title: "使用 Yahoo pipes 服务做内容聚合 -- ThoughtWorks好声音"
date: 2014-01-01 19:48
comments: true
categories: 
- yahoo
- tools
- ThoughtWorks

---

### ThoughtWorks好声音

[ThoughtWorks好声音](http://voice.thoughtworkers.org/)是一个聚合网站，内容来自众ThoughtWorker的博客，我们每周会汇聚一次，从众多的博客中挑选出一些P2(软件卓越)相关的主题，然后编为一辑，再分享出去。

但是从近100个博客中找P2相关的内容，这件事本身非常繁琐，如果每周都做这个重复劳动的话，那么软件卓越从何谈起呢？作为以解放人类为己任的程序员，我们绝对不能忍受纯体力的劳动。

#### 获取博客地址列表

之前郑晔做了一个[金数据](https://jinshuju.net/)的统计，请各位同事把自己的名字和博客地址登记在一个金数据的表单上：

![image](http://abruzzi.github.com/images/2014/01/blog-colllecting.png)

接下来第一步就是把网页上的所有地址取下来，这一步很容易，从金数据的页面上用jQuery找到表格的第二列，然后将其中的文字取出来：

```js

$("table tr td:nth-child(2)").map(function(key, item) {
	return $(item).text().trim(); 
});

```

写到这里突发奇想，能不能用phantomjs去把这个动作自动化？

```js
page.open(url, function (status) {
    if (status !== 'success') {
        console.log('Unable to access network');
    } else {
        page.injectJs('jquery.js');
        
        var links = page.evaluate(function() {
            return $("table tr td:nth-child(2)").map(function(key, value) {
                return $(value).text().trim();
            });
        });

        var results = underscore(links).filter(function(item) {
            return item.length > 0; 
        }).map(function(item) {
            if(!new RegExp('^(https|http)').test(item)) {
                return "http://" + item;
            }
            return item;
        });
    }
    phantom.exit();
});

```

这样，results数组中就包含了所有的博客链接了，而且有的同事比较懒，提供的URL中不包含`http`，这段代码还顺手给这样的url添加了头尾。

然后**第二步**，我**想象**着应该再写个脚本，在这个数组中得每个url的后边加上诸如`rss`或者`atom.xml`之类的后缀，然后去获取每个博客的rss文件，然后根据这些信息做一些事情。吃午饭的过程中我还在想象这个工具分为几个模块，用什么样的语言来做开发等等细节。

吃完午饭，突然想起来之前熊杰貌似发过一个yahoo pipes生成的rss，我在邮件中翻出来之后，失望的发现我自己的博客都不在里边，想想熊杰貌似还在乌干达援助非洲人民，那就自己动手重新定义一个吧。

#### Yahoo pipes 服务

[Yahoo pipes](http://pipes.yahoo.com/pipes/)是一个用来定制聚合的服务，只需要定义好数据源(通常是rss/atom)，然后定义一些操作，比如排序，去重，联合等等。最后这个pipe会生成一个结果集，这些特性简直就是为我们这个需求定制的：

1.	将博客地址+'/rss' / 博客地址+'/atom.xml' 添加到一个个的fetcher上
2.	将这些fetcher联合起来
3.	将联合的结果排序(按照发表日期/更新日期)
4.	生成最后的rss

yahoo pipes提供的编辑器非常简单易用：

![image](http://abruzzi.github.com/images/2014/01/single-pipe.png)

而且在编辑界面底下有一个预览界面：

![image](http://abruzzi.github.com/images/2014/01/single-preview.png)

当然，当定义好完整的pipe之后，我们的ThoughtWorks好声音的源看起来是这样的：

![image](http://abruzzi.github.com/images/2014/01/tvot-pipe-resized.png)

运行这个pipe之后，得到一个preview的界面：

![image](http://abruzzi.github.com/images/2014/01/tvot-pipe-run-resized.png)

最后，可以将这个pipe公开发布，或者将这个pipe生成的rss订阅到阅读器中，比如[vienna](http://www.vienna-rss.org/):

![image](http://abruzzi.github.com/images/2014/01/vienna-resized.png)

然后就可以一目了然的看到最近有哪些ThoughtWorker更新了自己的博客，又有那些是P2相关的，可以`理论上`减轻我们编辑很多的工作量。

#### 结论

手里是锤子的时候，看着周围的东西都像钉子。有时候，那些又酷又炫的技巧/工具可能并非必须。