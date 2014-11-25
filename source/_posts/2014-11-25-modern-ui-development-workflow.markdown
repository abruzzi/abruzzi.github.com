---
layout: post
title: "现代Web页面开发流程"
date: 2014-11-25 14:11
comments: true
categories: 
- Web Design
- Workflow
- Frontend

---

### 现代Web页面开发流程

通常来说，Web页面开发的流程大致是这样的：设计师（设计师不是美工，就像程序员不是码农一样）提供设计稿，通常是图片格式。然后前端的开发人员（在ThoughtWorks我们称之为UI Dev）来手工的将图片转换为对应的HTML+CSS，往往还需要在各个浏览器中调试等。

大多数时候，设计师会提供色卡，或者至少前景色/背景色/高亮色的值给开发人员。如果没有的话，开发人员会用到一些工具如`colorpicker`, `ruler`之类来确保最终的效果和设计稿是一致的。

如果你观察过UI Dev的工作流程的话，你会发现基本的上是这样的：使用编辑器（或者IDE）编写HTML代码，CSS代码，保存修改内容，切换到浏览器窗口，按`F5`或者`Ctrl-R`刷新，然后对比设计稿和实现，如果发现不一致的地方，再切换到编辑器中修改代码，如是往复。

#### 避免手工劳动

纯手工的方式来编辑HTML/CSS会非常耗时，特别是作为标记语言的HTML，开发者需要时刻关注关闭已经打开的标签。比如一个标题元素，你需要：

```html
<h1>This is the page title</h1>
```

几乎从一开始，人们就想到了各种办法来避免自己重复的键入，比如Vim的[SuperTab](https://github.com/ervandew/supertab)以及[Snipmate](https://github.com/garbas/vim-snipmate)插件，可以通过输入`标签名`+`Tab`来补全所有的标签等，又或者DreamWaver提供的`代码生成`的方式来简化这一流程。

Sublime的编辑器上的著名插件[Emmet](https://sublime.wbond.net/packages/Emmet)可以帮助开发人员飞速的开发HTML/CSS，这里有一个小例子。假设我们需要实现的页面是这样的：

![web design](/images/2014/11/web-design-resized.png)

那么对应的HTML结构可能会是：

```html
<ul>
    <li>
        <div class="feature">
            <span class="number"></span>
            <i></i>
            <h4></h4>
            <p></p>
        </div>
    </li>
    ...
</ul>
```

使用Emmet，则只需要给出表达式，然后按一下`Tab`键就可以补全为上述的结构了：

```
ul>li*3>.feature>span.number+i+h4+p
```

上边的这条命令可以读作："创建一个UL，该UL下有3个LI，每个LI下有一个class为feature的DIV（不指定元素名称的话，默认生成div），每个DIV内，有一个类为.number的SPAN，一个i元素，一个H4元素和一个P元素"

完整的技巧可以参看[官方文档](http://docs.emmet.io/cheat-sheet/)。

#### 避免重复劳动

上边提到的频繁的F5刷新，可以通过`LiveReload+Guard`两个工具的组合来解决。[LiveReload](https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei)是一个浏览器的插件，通过协议与后台的服务器进行通信。当后台文件发生变化时，LiveReload会自动刷新页面。

[Guard](https://github.com/guard/guard)会使用操作系统的API来感知本地文件的变化，当文件变化后，它可以通知LiveReload进行刷新，当然Guard可以做其他一些事情，比如等SCSS发生变化时，自动编译CSS等。

两者结合之后，就可以节省我们大量的时间，而把精力主要投放在开发这件事情本身上。

#### 样板工程

我在Github上公开了一个样板工程，这是一个开箱即用的工程，其中提供了这样一些配置：

1.	SCSS的编译环境（使用compass）
2.	Guard配置（当你的SCSS文件或者HTML文件修改之后，自动通知LiveReload来刷新浏览器）
3.	一个标准的HTML5样板文档
4.	一个基本的style.scss

Guardfile的配置中，如果`index.html`发生变化，或者`stylesheets`中的css文件发生变化，或者`scripts`目录中的js文件发生变化，都会触发`livereload`任务（通知浏览器）。

```rb
guard 'livereload' do
  watch('index.html')
  watch(%r{stylesheets/.+\.(css)})
  watch(%r{scripts/.+\.(js)})
end

guard :compass
```

你只需要简单的将这个工程克隆到本地：

```sh
$ git clone git@github.com:abruzzi/design-boilerplate.git mydesign
```

然后在该目录中执行`bundle install`即可：

```sh
$ cd mydesign
$ bundle install
```

这里有两点假设：
1.	你已经安装了[rvm](http://rvm.io/)
2.	你已经使用rvm安装了某个版本的ruby，即`bundler`这个gem

#### 开发流程

我通常会启动两个终端，一个用来运行`Guard`，另一个用来运行`HTTP Server`，然后是一个浏览器：

![workflow](/images/2014/11/workflow-resized.png)

当在编辑器中进行编辑之后，保存文件，浏览器会自动刷新，这样的快速反馈可以告诉我下一步应该如何修改：将背景色调整的再淡一点，还是把会h2的字体变得更大，或者图片和文字的上边缘没有对齐等等。

这种开发流程和后台开发人员进行TDD的方式非常类似：`实时反馈，小步前进`！如果你的桌子上有两个显示器的话，那就更好了，你可以在一台显示器上显示设计稿，另一台上分屏显示编辑器和浏览器，这样就可以非常舒服的进行UI开发了：

![two displays](/images/2014/11/two-displays-resized.png)




