---
layout: post
title: "如何提升页面渲染效率"
date: 2017-02-08 18:16
comments: true
categories: 
- UI
- Frontend
---

## Web页面的性能

我们每天都会浏览很多的Web页面，使用很多基于Web的应用。这些站点看起来既不一样，用途也都各有不同，有在线视频，`Social Media`，新闻，邮件客户端，在线存储，甚至图形编辑，地理信息系统等等。虽然有着各种各样的不同，但是相同的是，他们背后的工作原理都是一样的：

- 用户输入网址
- 浏览器加载`HTML/CSS/JS`，图片资源等
- 浏览器将结果绘制成图形
- 用户通过鼠标，键盘等与页面交互

![](/images/2017/02/internet-resized.png)

这些种类繁多的页面，在用户体验方面也有很大差异：有的响应很快，用户很容易就可以完成自己想要做的事情；有的则慢慢吞吞，让焦躁的用户在受挫之后拂袖而去。毫无疑问，性能是影响用户体验的一个非常重要的因素，而影响性能的因素非常非常多，从用户输入网址，到用户最终看到结果，需要有很多的参与方共同努力。这些参与方中任何一个环节的性能都会影响到用户体验。

- 宽带网速
- DNS服务器的响应速度
- 服务器的处理能力
- 数据库性能
- 路由转发
- 浏览器处理能力

早在2006年，雅虎就发布了提升站点性能的[指南](https://developer.yahoo.com/performance/rules.html)，Google也发布了类似的[指南](https://developers.google.com/speed/docs/insights/rules)。而且有很多工具可以和浏览器一起工作，对你的Web页面的加载速度进行评估：分析页面中资源的数量，传输是否采用了压缩，JS、CSS是否进行了精简，有没有合理的使用缓存等等。

如果你需要将这个过程与CI集成在一起，来对应用的性能进行监控，我去年写过一篇[相关的博客](http://icodeit.org/2016/02/performance-testing-in-ci/)。

本文打算从另一个角度来尝试加速页面的渲染：浏览器是如何工作的，要将一个页面渲染成用户可以看到的图形，浏览器都需要做什么，哪些过程比较耗时，以及如何避免这些过程（或者至少以更高效的方式）。

## 页面是如何被渲染的

说到性能优化，**规则一**就是：

>If you can't measure it, you can't improve it. - Peter Drucker

根据浏览器的工作原理，我们可以分别对各个阶段进行度量。

![](/images/2017/02/how-browser-works-frame-resized.png)

*图片来源：http://dietjs.com/tutorials/host#backend*

### 像素渲染流水线

1. 下载HTML文档
1. 解析HTML文档，生成`DOM`
1. 下载文档中引用的CSS、JS
1. 解析CSS样式表，生成`CSSOM`
1. 将JS代码交给JS引擎执行
1. 合并DOM和CSSOM，生成`Render Tree`
1. 根据`Render Tree`进行布局`layout`（为每个元素计算尺寸和位置信息）
1. 绘制（Paint）每个层中的元素（绘制每个瓦片，瓦片这个词与GIS中的瓦片含义相同）
1. 执行图层合并（Composite Layers）

使用Chrome的DevTools - Timing，可以很容易的获取一个页面的渲染情况，比如在`Event Log`页签上，我们可以看到每个阶段的耗时细节（清晰起见，我没有显示`Loading`和`Scripting`的耗时）：

![Timeline](/images/2017/02/timeline-resized.png)

上图中的Activity中，`Recalculate Style`就是上面的构建`CSSOM`的过程，其余Activity都分别于上述的过程匹配。

应该注意的是，浏览器可能会将Render Tree分成好几个层来分别绘制，最后再合并起来形成最终的结果，这个过程一般发生在`GPU`中。

Devtools中有一个选项：`Rendering - Layers Borders`，打开这个选项之后，你可以看到每个层，每个瓦片的边界。浏览器可能会启动多个线程来绘制不同的层/瓦片。

![Layers and Tiles](/images/2017/02/layer-and-tile-resized.png)

Chrome还提供一个`Paint Profiler`的高级功能，在`Event Log`中选择一个`Paint`，然后点击右侧的`Paint Profiler`就可以看到其中绘制的全过程：

![Paint in detail](/images/2017/02/paint-in-detial-resized.png)

你可以拖动滑块来看到随着时间的前进，页面上元素被逐步绘制出来了。我录制了一个我的知乎活动页面的视频，不过需要翻墙。

<iframe width="560" height="315" src="https://www.youtube.com/embed/gley7VZFx_I" frameborder="0" allowfullscreen></iframe>

### 常规策略

为了尽快的让用户看到页面内容，我们需要快速的完成`DOM+CSSOM` - `Layout` - `Paint` - `Composite Layers`的整个过程。一切会阻塞DOM生成，阻塞CSSOM生成的动作都应该尽可能消除，或者延迟。

在这个前提下，常见的做法有两种：

#### 分割CSS

对于不同的浏览终端，同一终端的不同模式，我们可能会提供不同的规则集：

```css
@media print {
	html {
		font-family: 'Open Sans';
		font-size: 12px;
	}
}

@media orientation:landscape {
	//
}
```

如果将这些内容写到统一个文件中，浏览器需要下载并解析这些内容（虽然不会实际应用这些规则）。更好的做法是，将这些内容通过对`link`元素的`media`属性来指定：

```html
<link href="print.css" rel="stylesheet" media="print">
<link href="landscape.css" rel="stylesheet" media="orientation:landscape">
```

这样，`print.css`和`landscape.css`的内容不会阻塞Render Tree的建立，用户可以更快的看到页面，从而获得更好的体验。

#### 高效的CSS规则

##### CSS规则的优先级

很多使用SASS/LESS的开发人员，太过分的喜爱嵌套规则的特性，这可能会导致复杂的、无必要深层次的规则，比如：

```css
#container {
	p {
		.title {
			span {
				color: #f3f3f3;
			}
		}
	}
}
```

在生成的CSS中，可以看到：

```css
#container p .title span {
  color: #f3f3f3;
}
```

而这个层次可能并非必要。CSS规则越复杂，在构建Render Tree时，浏览器花费的时间越长。CSS规则有自己的优先级，不同的写法对效率也会有影响，特别是当规则很多的时候。这里有一篇关于[CSS规则优先级](https://css-tricks.com/specifics-on-css-specificity/)的文章可供参考。

##### 使用GPU加速

很多动画都会定时执行，每次执行都可能会导致浏览器的重新布局，比如：

```css
@keyframes my {
	20% {
		top: 10px;
	}
	
	50% {
		top: 120px;
	}
	
	80% {
		top: 10px;
	}
}
```

这些内容可以放到GPU加速执行（GPU是专门设计来进行图形处理的，在图形处理上，比CPU要高效很多）。可以通过使用`transform`来启动这一特性：

```css
@keyframes my {
	20% {
		transform: translateY(10px);
	}

	50% {
		transform: translateY(120px);
	}
		
	80% {
		transform: translateY(10px);
	}
}
```

#### 异步JavaScript

我们知道，JavaScript的执行会阻塞DOM的构建过程，这是因为JavaScript中可能会有DOM操作：

```js
var element = document.createElement('<div></div>');
element.style.width = '200px';
element.style.color = 'blue';

body.appendChild(element);
```

因此浏览器会等等待JS引擎的执行，执行结束之后，再恢复DOM的构建。但是并不是所有的JavaScript都会设计DOM操作，比如审计信息，WebWorker等，对于这些脚本，我们可以显式地指定该脚本是**不阻塞DOM渲染**的。

```html
<script src="worker.js" async></script>
```

带有`async`标记的脚本，浏览器仍然会下载它，并在合适的时机执行，但是不会影响DOM树的构建过程。

### 首次渲染之后

在首次渲染之后，页面上的元素还可能被不断的重新布局，重新绘制。如果处理不当，这些动作可能会产生性能问题，产生不好的用户体验。

- 访问元素的某些属性
- 通过JavaScript修改元素的CSS属性
- 在`onScroll`中做耗时任务
- 图片的预处理（事先裁剪图片，而不是依赖浏览器在布局时的缩放）
- 在其他Event Handler中做耗时任务
- 过多的动画
- 过多的数据处理（可以考虑放入`WebWorker`内执行）

#### 触发布局/回流

元素的一些属性和方法，当在被访问或者被调用的时候，会触发浏览器的布局动作（以及后续的Paint动作），而布局基本上都会波及页面上的所有元素。当页面元素比较多的时候，布局和绘制都会花费比较大。

比如访问一个元素的`offsetWidth`（布局宽度）属性时，浏览器需要重新计算（重新布局），然后才能返回最新的值。如果这个动作发生在一个很大的循环中，那么浏览器就不得不进行多次的重新布局，这可能会产生严重的性能问题：

```js
for(var i = 0; i < list.length; i++) {
	list[i].style.width = parent.offsetWidth + 'px';
}
```

正确的做法是，先将这个值读出来，然后缓存在一个变量上（触发一次重新布局），以便后续使用：

```js
var parentWidth = parent.offsetWidth;
for(var i = 0; i < list.length; i++) {
	list[i].style.width = parentWidth + 'px';
}
```

这里有一个完整的列表[触发布局](https://gist.github.com/paulirish/5d52fb081b3570c81e3a)。

#### CSS样式修改

##### 布局相关属性修改

修改布局相关属性，会触发`Layout - Paint - Composite Layers`，比如对位置，尺寸信息的修改：

```js
var element = document.querySelector('#id');
element.style.width = '100px';
element.style.height = '100px';

element.style.top = '20px';
element.style.left = '20px';
```

##### 绘制相关属性修改

修改绘制相关属性，不会触发`Layout`，但是会触发后续的`Paint - Composite Layers`，比如对背景色，前景色的修改：

```js
var element = document.querySelector('#id');
element.style.backgroundColor = 'red';
```

##### 其他属性

除了上边的两种之外，有一些特别的属性可以在不同的层中单独绘制，然后再合并图层。对这种属性的访问（如果正确使用了CSS）不会触发`Layout - Paint`，而是直接进行`Compsite Layers`:

- transform
- opacity

`transform`展开的话又分为: `translate`, `scale`, `rotate`等，这些层应该放入单独的渲染层中，为了对这个元素创建一个独立的渲染层，你必须提升该元素。

可以通过这样的方式来提升该元素：

```css
.element {
  will-change: transform;
}
```

>CSS 属性 will-change 为web开发者提供了一种告知浏览器该元素会有哪些变化的方法，这样浏览器可以在元素属性真正发生变化之前提前做好对应的优化准备工作。

当然，额外的层次并不是没有代价的。太多的独立渲染层，虽然缩减了`Paint`的时间，但是增加了`Composite Layers`的时间，因此需要仔细权衡。在作调整之前，需要`Timeline`的运行结果来做支持。

还记得性能优化的规则一吗？

>If you can't measure it, you can't improve it. - Peter Drucker

下面这个视频里可以看到，当鼠标挪动到特定元素时，由于CSS样式的变化，元素会被重新绘制：

<iframe width="560" height="315" src="https://www.youtube.com/embed/c6wKfDpbwu8" frameborder="0" allowfullscreen></iframe>

[CSS Triggers](https://csstriggers.com/)是一个完整的CSS属性列表，其中包含了会影响布局或者绘制的CSS属性，以及在不同的浏览器上的不同表现。

### 总结

了解浏览器的工作方式，对我们做前端页面渲染性能的分析和优化都非常有帮助。为了高效而智能的完成渲染，浏览器也在不断的进行优化，比如资源的预加载，更好的利用GPU（启用更多的线程来渲染）等等。

另一方面，我们在编写前端的HTML、JS、CSS时，也需要考虑浏览器的现状：如何减少DOM、CSSOM的构建时间，如何将耗时任务放在单独的线程中（通过`WebWorker`）。

### 参考资料

- Google出品的[Web基础](https://developers.google.com/web/fundamentals/performance/?hl=zh-cn)
- 一篇关于如何[优化CSS的文章](https://varvy.com/pagespeed/optimize-css-delivery.html)
- [CSSOM](https://varvy.com/performance/cssom.html)的介绍
