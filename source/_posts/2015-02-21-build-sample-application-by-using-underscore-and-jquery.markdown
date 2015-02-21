---
layout: post
title: "使用underscore.js构建前端应用"
date: 2015-02-21 21:21
comments: true
categories: 
- frontend
- jquery
- underscore
---

## 一个监控系统

我们今天要使用`underscore.js`和`jQuery`来构建一个客户端的应用，这个应用是一个监控系统的前端，设计师已经给出了界面设计：

![alarms design](/images/2015/02/alarms-design-resized.png)

而对应的服务器端的API也已经就绪了：

```sh
$ curl http://localhost:9527/alarms.json -s | jq .
```

会看到诸如这样的返回值：

```json
[
  {
    "proiority": "critical",
    "occurrence": "2/12/2015 01:23 AM",
    "summary": "heartbeat failure",
    "node": "VIQ002"
  },
  {
    "proiority": "major",
    "occurrence": "2/12/2015 01:22 AM",
    "summary": "packages are rejected",
    "node": "VIQ002"
  },
  {
    "proiority": "medium",
    "occurrence": "2/11/2015 01:23 AM",
    "summary": "connection cannot be established",
    "node": "VIQ002"
  }
]

```

每条告警信息都包含：优先级，发生时间，描述信息，以及发生告警的节点名称。

我们要将这些信息整合，并展示在页面上。

### mockup

我在[《3周3页面》](juntao.gitbooks.io/3-web-designs-in-3-weeks/)中讨论过现代前端开发的方式，你也可以参考[这篇文章](http://icodeit.org/2014/11/modern-ui-development-workflow/)以及[这篇文章](http://)。我们这里还是采用相同的方式来实现这个`mockup`，也就是静态页面。

首先我们在`index.html`中编写HTML：

```html
<div class="container">
    <h1>Active Event List in transmission</h1>
    <ul class="events">
        <li>
            <div class="event critical">
                <h3>heartbeat failure @ VIQ002</h3>
                <span class="date">2/12/2015 01:23 AM</span>
            </div>
        </li>
        <li>
            <div class="event major">
                <h3>packages are rejected</h3>
                <span class="date">2/12/2015 01:23 AM</span>
            </div>
        </li>
        <li>
            <div class="event medium">
                <h3>connection cannot be established</h3>
                <span class="date">2/12/2015 01:23 AM</span>
            </div>
        </li>
        <!-- ... -->
    </ul>

    <ul class="legend">
        <li>
            <div class="count critical">
                <i class="alarm"></i>
                <span>critical: 20</span>
            </div>
        </li>
        <li>
            <div class="count major">
                <i class="alarm"></i>
                <span>major: 13</span>
            </div>
        </li>
        <li>
            <div class="count medium">
                <i class="alarm"></i>
                <span>medium: 20</span>
            </div>
        </li>
        <li>
            <div class="count warning">
                <i class="alarm"></i>
                <span>warning: 30</span>
            </div>
        </li>
        <li>
            <div class="count indeterminate">
                <i class="alarm"></i>
                <span>indeterminate: 6</span>
            </div>
        </li>
    </ul>
</div>

```

`events`中包含了所有告警信息，每一条告警根据等级不同显示了不同的颜色：红色表示严重，橘红表示主要，橘色表示一般等。告警信息包含了一个描述信息，并且包含了一个时间戳，表示告警发生的时间。

`legend`部分是一个图例，其中包含了各个颜色的说明，并且包含了不同级别的告警信息的数目，比如截止目前为止，共有**20**个严重的告警，13个主要告警等。

对应的`scss`内容如下，首先定义了一些通用的CSS类：

```scss
@import "compass/reset";
@import "compass/css3";

body {
	font-size: 62.5%;
	font-family: "Open Sans", serif;
	text-align: center;
}

.critical {
	background-color: red;
	color: white;
}

.major {
	background-color: orangered;
	color: white;
}

.medium {
	background-color: orange;
	color: white;
}

.warning {
	background-color: #2C75DB;
	color: white;
}

.indeterminate {
	background-color: #29D4BA;
	color: white;
}
```

然后定义`container`中的各个元素的样式：

```scss
.container {
	padding: 1em 0;
	width: 800px;
	margin: 0 auto;

	h1 {
		font-size: 3em;
		text-transform: uppercase;
		margin: 1em 0;
	}

	.event {
		position: relative;

		h3 {
			text-align: left;
			font-size: 1.5em;
			padding: .6em .5em;
			text-transform: capitalize;
		}

		.date {
			position: absolute;
			top: 50%;
			right: 1em;
			font-size: 1em;
			font-style: italic;
			color: #eeeeee;
		}
	}

	.legend {
		margin: 1em 0;
		li {
			width: 20%;
			float: left;

			.count {
				padding: .6em;
				text-transform: capitalize;
			}
		}
	}
}
```

### 应用程序

首先我们下载`underscore.js`和`jquery.js`，并将它们放在当前目录下的`scripts/libs`下，并在`scripts`下创建一个`app.js`文件。

这时候的目录结构如下：

```
├── index.html
├── sass
│   └── style.scss
├── scripts
│   ├── app.js
│   └── libs
│       ├── jquery.min.js
│       └── underscore.js
└── stylesheets
    └── style.css
```

然后我们在`index.html`中引入上列的文件：

```html
<script src="scripts/libs/jquery.min.js"></script>
<script src="scripts/libs/underscore.js"></script>
<script src="scripts/app.js"></script>
```

我们的应用程序需要做的事情很简单：

1.	请求服务器获得数据
2.	处理数据（如果需要的话）
3.	将加工过的数据与模板结合，渲染在页面上

`underscore.js`中有一个用来处理模板的函数，叫做`template`：

```js
var compiled = _.template("<h1><%= title %></h1>");
compiled({"title": "Heartbeat Failure @ VIQ002"});

//<h1>Heartbeat Failure @ VIQ002</h1>
```

注意上式中的`<%= variable %>`，这个表达式表示打印`variable`的值。而如果只是执行JavaScript代码，表达式则为`<% expression; %>`。

比如我们可以使用`for`循环：

```js
var template =
	"<% _.each(alarms, function(alarm){ %>" +
		"<h3><%= alarm.summary %></h3>" +
	"<% }); %>";

var compilded = _.template(template);
compilded({"alarms": [
  {
    "proiority": "critical",
    "occurrence": "2/12/2015 01:23 AM",
    "summary": "heartbeat failure",
    "node": "VIQ002"
  },
  {
    "proiority": "major",
    "occurrence": "2/12/2015 01:22 AM",
    "summary": "packages are rejected",
    "node": "VIQ002"
  },
  {
    "proiority": "medium",
    "occurrence": "2/11/2015 01:23 AM",
    "summary": "connection cannot be established",
    "node": "VIQ002"
  }
]});

//<h3>heartbeat failure</h3><h3>packages are rejected</h3><h3>connection cannot be established</h3>
```

注意上边代码中的`_.each`语句。

### 实现

首先我们在页面上定义一个模板，定义在id为`events`的`script`标签中，注意这个script的type为`template`，这样既可以避免浏览器解释它，又可以为我们临时保存一段文本。

```html
<script type="template" id="events">
    <% _.each(alarms, function(alarm) { %>
        <li>
            <div class="event <%= alarm.proiority%>">
                <h3><%= alarm.summary%> @ <%= alarm.node %></h3>
                <span class="date"><%= alarm.occurrence %></span>
            </div>
        </li>
    <% }); %>
</script>
```

然后在`app.js`中只需要请求`alarms.json`，然后编译模板，并绑定数据：

```js
$(function() {
	$.get("/alarms.json").done(function(alarms) {
		var compiled = _.template($("#events").html());
		var html = compiled({"alarms": alarms});

		$(".events").html(html);
	});
});
```

刷新页面，就可以看到来自于后台的实际数据了（当然，我们这里使用了一个静态的`alarms.json`来模拟后台的API）：

![fetch data from server](/images/2015/02/fetch-data-resized.png)


#### 处理数据

你可能已经看到了，由于后台数据采集的问题，前端请求到的数据不一定每次都是按照日期排好序的，因此我们需要在拿到数据之后先排序在展示。好在我们之前已经学习了如何做到这一点：

```js
$(function() {
	$.get("/alarms.json").done(function(alarms) {
		var eventCompiled = _.template($("#events").html());

		var events = _(alarms).sortBy("occurrence").reverse();
		var eventHTML = eventCompiled({"alarms": events});

		$(".events").html(eventHTML);
	});
});
```

剩下的就是页面最底部的图例部分了，这部分会统计各种类型告警的合计信息，这些信息需要进一步的汇总。首先我们将`legend`封装成模板：

```html
<script type="template" id="legend">
    <% _.each(legends, function(legend) { %>
        <li>
            <div class="count <%= legend.proiority %>">
                <i class="alarm"></i>
                <span><%= legend.proiority %>: <%= legend.count %></span>
            </div>
        </li>
    <% }); %>
</script>
```

也即，我们需要这样一个结果集：

```js

[
	{
		"proiority": "critical",
		"count": 3
	},
	{
		"proiority": "major",
		"count": 2
	}
]
```

不过使用`underscore.js`，我们可以很容易的得到这个格式的数据：

```js
var legends = _.chain(alarms)
	.groupBy("proiority")
    .map(function(value, key) {
    	return {proiority: key, count: value.length};
	}).value();
```

其中，`groupBy`是一个新的API，和`SQL`中的`group by`子句一样，它可以将符合条件的项目合并为不同的组：

```js
var contacts = [
  {
      "name": "Juntao",
      "age": 29
  },
  {
      "name": "Abruzzi",
      "age": 30
  },
  {
      "name": "Sara",
      "age": 29
  }
];

var result = _(contacts).groupBy("age");
```

会得到这样的结果：

```json
{
    "29": [
        {
            "name": "Juntao",
            "age": 29
        },
        {
            "name": "Sara",
            "age": 29
        }
    ],
    "30": [
        {
            "name": "Abruzzi",
            "age": 30
        }
    ]
}
```

因此我们通过上面的计算就可以得到需要的结果了：

![with legend](/images/2015/02/with-legend-resized.png)

