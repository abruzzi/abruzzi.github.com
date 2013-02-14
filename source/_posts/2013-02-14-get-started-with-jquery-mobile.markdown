---
layout: post
title: "Get started with jQuery Mobile"
date: 2013-02-14 13:50
comments: true
categories: 
- lightweight web
- open source
tags: [lightweight, mobile, javascript]

---
###jQuery mobile

[jQuery Mobile](http://jquerymobile.com/)是一个基于jQuery/jQuery-ui的UI库，用于构建基于HTML5的应用程序，当然它主要针对移动设备平台，开发者使用它可以很容易的开发出运行在ios/android/windows phone上的应用，这些应用（尽管运行在不同的硬件/软件系统上）在界面上看起来几乎一致。

###基本元素

####页面布局

在移动设备上，一个页面一般由三部分组成（header区域，content区域，footer区域），当然，有的页面可能会缺失一部分（最常见的如：没有footer的长列表），jQuery Mobile通过在DOM元素上定义data-role来指定元素的归属：

-	page 整个页面
-	header header区域
-	content content区域
-	footer footer区域

```
<div data-role='page'>
    <div data-role='header'>
        <h1>This is header</h1>
    </div>
    <div data-role='content'>
        <p>This is content</p>
    </div>
    <div data-role='footer'>
        <h1>This is footer</h1>
    </div>
</div>
```

![image](http://abruzzi.github.com/images/2013/02/jquery-mobile-page.png)

####多个页面

通常一个应用程序会有多个“页面”，在jQuery Mobile中，所有的“页面”都放在同一个html文件中，通过data-role为page的元素的id来指定一个页面：

```
<div data-role='page' id='edit-page'>
    <div data-role='header'>
        <h1>Edit page</h1>
    </div>
    <div data-role='content'>
        <form>
        	<label for='desc'>Description: </label>
        	<input type='text' value='' />
        </form>
    </div>
</div>
```

在另一个页面中，可以通过link的href来引用这个id：

```
<a href="#edit-page">Go to edit page</a>
```

![image](http://abruzzi.github.com/images/2013/02/jquery-mobile-multi-page.png)

####列表元素

列表可能是最常见的一种jQuery Mobile元素了，列表由HTML的ul-li组成：

```
<ul data-role='listview' data-inset='true'>
	<li> <a href="#">Tomorrow is another day</a> </li>
	<li> <a href="#">Michael is leaving</a> </li>
	<li> <a href="#">Tutorial of jQuery mobile</a> </li>
	<li> <a href="#">So, if you want something,...</a> </li>
</ul>
```

![image](http://abruzzi.github.com/images/2013/02/jquery-mobile-list.png)

###一个小例子
我在最近的一个开源项目[feather](https://github.com/abruzzi/feather)中使用了jQuery Mobile来完成ios上的展现。

![image](http://abruzzi.github.com/images/2013/02/feather-mobile.png)