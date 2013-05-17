---
layout: post
title: "CSS中的before和after伪元素及其应用"
date: 2013-05-16 15:29
comments: true
categories: 
- css
- web

---
###before和after伪元素
所谓伪元素，可以理解为浏览器为某元素附加的元素（根据名字，附加在这个元素之前/之后）。用来完成特定的效果，before/after需要和content属性一起使用：

```
.css-class:before {
	content: " ";
}
.css-class:after {
	content: " ";
}
```

通过使用before/after伪元素，可以做一些很有意思的效果。[这里](http://css-tricks.com/pseudo-element-roundup/)有一些有意思的示例。

###四个三角形
页面上经常会遇到小三角形这种视觉元素，比如表示一个可以**打开/关闭**的开关（将不会频繁使用的元素隐藏起来，点击可以展开/收起），或者一个模拟消息盒子（纯CSS实现），最早的做法是使用一个小的图片来完成，但是这个事实上可以通过纯CSS来实现。

原理是利用block元素的`border`属性，当`border`的值很小的时候，`border`之间的连接处并无异常，但是当`border`较大，而元素本身的尺寸小于`border`自身时，则每一个`border`都会呈现为梯形，而当元素的`width`和`height`都为0时，就会看到一个正方形，而每个边都变成了一个三角形：

```
.container .color-box {
	content: " ";
	width: 0;
	height: 0;
	border: 10px solid transparent;
	border-left-color: #00ff00;
	border-right-color: #000000;
	border-top-color: #ff0000;
	border-bottom-color: #0000ff;
}
```

![image](http://abruzzi.github.com/images/2013/05/color-box.png)

###小三角形
这时候，如果将其他的三条边隐藏起来（通过将`border`的颜色置为透明）：

```
.container .color-box {
	content: " ";
	width: 0;
	height: 0;
	border: 10px solid transparent;//朝下的三角形
	border-top-color: #ff0000;
}
```

![image](http://abruzzi.github.com/images/2013/05/triggle.png)

先将所有的边都设置为透明色，然后根据需要显示某一个边，来完成三角形的指向。

###一个普通的消息框

一个普通的消息框，通过设置`box-shadow`和`border-radius`之后，可以变得比较“好看”，但是如果可以给这个消息框加上一个小的三角形（可以指向用户的头像等）。

HTML代码：

```
		<div class="container">
			<div class="chat-box">
				<p>
					Resque (pronounced like "rescue") is a Redis-backed library for creating background jobs, placing those jobs on multiple queues, and processing them later.
				</p>
			</div>
		</div>
```

样式如下：

```
.container .chat-box {
	position: relative;
	border: 1px solid #6b6b6b;
	border-radius: 5px;
	box-shadow: 1px 1px 4px #6b6b6b;
	width: 300px;
}

.container .chat-box p {
	margin: 0;
	padding: 10px;
	font-size: 18px;
	font-family: "Microsoft Yahei";
}
```

![image](http://abruzzi.github.com/images/2013/05/box.png)

###更fancy的消息框

先通过before伪元素，在消息框的底部加上一个小的三角形：

![image](http://abruzzi.github.com/images/2013/05/box-tirgger-gray.png)

```
.container .chat-box:after, 
.container .chat-box:before {
	position: absolute;
	content: " ";
	width: 0;
	height: 0;
	border: solid transparent;
	top: 100%;
	left: 62%;
} 

.container .chat-box:before {
	border-width: 10px;
	border-top-color: #6b6b6b;
	margin-left: -10px;
}
```

但是一个实心的灰色三角形比较难看，我们需要再改进一下，即通过在这个伪元素之上，再绘制一个白色（与消息框颜色相同）的伪元素，但是尺寸又小一个单位（单位与消息框本身的尺寸相同，这里为`1px`）。

![image](http://abruzzi.github.com/images/2013/05/box-tirgger-both.png)


