---
layout: post
title: "在Sublime Text中设置JavaScript构建"
date: 2014-12-21 18:52
comments: true
categories: 
- JavaScript
---
我在编写[《JavaScript核心概念及实践》](http://book.douban.com/subject/24165880/)一书的时候，为了保证读者学习时可以比较专注语言本身，专门用Swing开发了一个小工具[JSEvaluator](https://github.com/abruzzi/jsevaluator)。

这个工具可以当做JavaScript的简单的IDE，有一个编辑区域，有一些按钮(打开，保存，执行等)，执行之后还可以将结果显示在一个面板上。书出版后不断有读者问我如何将这个工具运行起来（我自己写这个工具的时候，并没有release的概念，而且最初的几个版本可用之后，就再也没有花心思维护），单独回复比较耗时，今天早上又收到一位热心读者的邮件，就在这里统一回复一下。

其实JSEvaluator的思想和其他的IDE一样：将一个编辑器和命令行工具结合在一起，编辑器提供编辑功能，然后IDE可以将编辑器中的文本发送给命令行工具执行（使用Rhino），将结果重定向到界面上。

[Sublime Text](http://www.sublimetext.com/3)提供的`Build`功能也可以做到这一点，并且可以使用它更加强大的其他编辑特性，因此推荐各位读者使用这里介绍的方式。

### Sublime Text编辑器
[Sublime Text](http://www.sublimetext.com/3)是一个文本编辑器，非常轻量级，并且有丰富的插件机制。虽然它不是一个免费软件，但是如果不注册还是可以无限试用下去，除了不定时的弹出一个对话框之外。它在现在的前端开发中非常流行，我作为一个`Vim`的忠实粉丝，也已经花费了很多时间在Sublime Text上了。

在写书的时候，JavaScript已经比较火了，但是更多的是在Web端。在本地开发的支持上还是比较薄弱。但是现在就不一样了，各个操作系统平台上都已经有了许多本地的JavaScript执行环境。比如Mac自带的`jsc`，跨平台的[node](http://nodejs.org/)等。

#### 准备工作
如果你在使用Mac OS X，请直接跳到下一步。如果你在使用Windows，请先安装node.js的Windows版本，然后保证`node.exe`在系统的PATH环境变量中。

#### 自定义build

在Sublime Text中，点击`Tools` -> `Build System` -> `New build system...`，Sublime会打开一个文件，我们来编辑这个文件：

```json
{
	"cmd": ["jsc", "$file"],
	"selector": "source.js"
}
```

上边这个命令指定了这个build使用的命令是`jsc`。如果你在Windows下使用`node`，那么对应的这个文件应该写成：

```json
{
	"cmd": ["node", "$file"],
	"selector": "source.js"
}
```

如果`node.exe`不在环境变量PATH中，请保证将其加入。完成这个文件的编辑之后，将其保存为`JavaScript.sublime-build`文件（Sublime会提示你输入文件名，因此输入JavaScript即可）。

#### 开始开发

接下来你就可以在Sublime中开发并编译JavaScript代码了，应该注意的是，如果你使用的是`jsc`，那么`console.log`这样的函数式不能直接使用的，不过你可以很容易的将其重新定义：

```js
var console = console || {};
console.log = debug;
```

这里的`debug`是`Sublime`提供的输出函数，它将会把结果输出在Sublime的控制台上。

![Sublime Text Build JavaScript](images/2014/12/sublime-text-jsc-resized.png)

运行构建的快捷键，在Mac OS X下为(`Cmd+B`)，Windows下为(`Ctrl+B`)。运行之后，可以看到在编辑器的底部会有一个小的窗口打开，里边的内容就是执行结果了。

#### 其他资料

1.	这里有一个[英文版](http://calebgrove.com/articles/js-console-sublime-text)，这里是[另一个](http://www.wikihow.com/Create-a-Javascript-Console-in-Sublime-Text)
2.	这里有一个[中文版](https://cnodejs.org/topic/51ee453af4963ade0ebde85e)，以及它的[补充](http://www.hacke2.cn/nodeJS-sublime-3/)

Note：由于我自己不使用`Windows`平台，也不推荐其他开发者使用，因此关于Windows的部分并没有经过认真测试。