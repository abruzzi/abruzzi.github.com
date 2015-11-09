---
layout: post
title: "你为什么应该试一试Reflux？"
date: 2015-11-09 23:03
comments: true
categories: 
- JavaScript
- Frontend
- React
- Reflux
---

### 一点背景

React在设计之初就只关注在View本身上，其余部分如`数据的获取`，`事件处理`等，全然不在考虑之内。不过构建大型的Web前端应用，这些点又实在不可避免。所以Facebook的工程师提出了前端的`Flux`架构，这个架构的最大特点是`单向数据流`（后面详述）。但是`Flux`本身的实现有很多不合理的地方，比如单例的Dispatcher会在系统中有多种事件时导致臃肿的`switch-cases`等。

这里是Facebook官方提供的提供[Flux的结构图](https://github.com/facebook/flux/tree/master/examples/flux-todomvc#structure-and-data-flow)。

![Flux Diagram](/images/2015/11/flux-diagram-resized.png)

其实整个Flux背后的思想也[不是什么新东西](http://bitquabit.com/post/the-more-things-change/)。在很久之前，Win32的消息机制（以及很多的GUI系统）就在使用这个模型，而且这也是一种被证实可以用来构建大型软件的模型。

鉴于Flux本身只是一个架构，而且Facebook提供的参考实现又有一些问题，所以社区有了很多版本的Flux实现。比如我们这里会用到的[Reflux](http://spoike.ghost.io/deconstructing-reactjss-flux/)。

### Reflux简介

简而言之，[Reflux](https://github.com/reflux/refluxjs)里有两个组件：Store和Action。Store负责和数据相关的内容：从服务器上获取数据，并更新与其绑定的React组件（view controller）;Action是一个事件的集合。Action和Store通过convention来连接起来。

具体来说，一个典型的过程是：

1.  用户的动作(或者定时器)在组件上触发一个Action
2.  Reflux会调用对应的Store上的callback（自动触发）
3.  这个callback在执行结束之后，会显式的触发（trigger）一个数据
4.  对应的组件（可能是多个）的state会被更新
5.  React组件检测到state的变化后，会自动重绘自身

![reflux data flow](/images/2015/11/reflux-data-flow.png)

### 一个例子

我们这里将使用React/Reflux开发一个实际的例子，从最简单的功能开始，逐步将其构建为一个较为复杂的应用。

这个应用是一个书签展示应用（数据来源于我的Google Bookmarks）。第一个版本的界面是这样的：

![bookmarks list](/images/2015/11/bookmarks-list-resized.png)

要构建这样一个列表应用，我们需要这样几个部分：

1.  一个用来`fetch`数据，存储数据的store （BookmarkStore）
2.  一个用来表达事件的`Action`（BookmarkActions）
3.  一个列表组件（BookmarkList）
4.  一个组件条目组件（Bookmark）

#### 定义Actions

```js
var Reflux = require('reflux');
var BookmarkActions = Reflux.createActions([
	'fetch'
]);

module.exports = BookmarkActions;
```

第一个版本，我们只需要定义一个`fetch`事件即可。然后在`Store`中编写这个Action的回调：

#### 定义Store

```js
var $ = require('jquery');
var Reflux = require('reflux');
var BookmarkActions = require('../actions/bookmark-actions');

var Utils = require('../utils/fetch-client');

var BookmarkStore = Reflux.createStore({
	listenables: [BookmarkActions],

	init: function() {
		this.onFetch();
	},

	onFetch: function() {
		var self = this;
		Utils.fetch('/bookmarks').then(function(bookmarks) {
			self.trigger({
				data: bookmarks,
				match: ''
			});
		});
	}
});

module.exports = BookmarkStore;
```

此处，我们使用`listenables: [BookmarkActions]`来将Store和Action关联起来，根据`convention`，`on`+事件名称就是回调函数的名称。这样当`Action`被触发的时候，`onFetch`会被调用。当获取到数据之后，这里会显式的`trigger`一个数据。

#### List组件

```js
var React = require('react');
var Reflux = require('reflux');

var BookmarkStore = require('../stores/bookmark-store.js');
var Bookmark = require('./bookmark.js');

var BookmarkList = React.createClass({
	mixins: [Reflux.connect(BookmarkStore, 'bookmarks')],

	getInitialState: function() {
		return {
			bookmarks: {data: []}
		}
	},

	render: function() {
		var list = [];
		this.state.bookmarks.data.forEach(function(item) {
	      list.push(<Bookmark title={item.title} created={item.created}/>)
	    });
	    
		return <ul>
			{list}
		</ul>
	}
});

module.exports = BookmarkList;
```

在组件中，我们通过`mixins: [Reflux.connect(BookmarkStore, 'bookmarks')]`将Store和组件关联起来，这样List组件`state`上的`bookmarks`就和`BookmarkStore`连接起来了。当`state.bookmarks`变化之后，`render`方法就会被自动调用。

对于每一个书签，就只是简单的展示内容即可：

#### Bookmark组件

```js
var React = require('react');
var Reflux = require('reflux');
var moment = require('moment');

var Bookmark = React.createClass({

	render: function() {
		var created = new Date(this.props.created * 1000);
		var date = moment(created).format('YYYY-MM-DD');

		return <li>
			<div className='bookmark'>
				<h5 className='title'>{this.props.title}</h5>
				<span className='date'>Created @ {date}</span>
			</div>
		</li>;
	}
});

module.exports = Bookmark;
```

这里我使用了`moment`库将`unix timestamp`转换为日期字符串，然后写在页面上。

最后，`Utils`只是一个对`jQuery`的包装：

```js
var $ = require('jquery');
var Promise = require('promise');

module.exports = {
    fetch: function(url) {
        var promise = new Promise(function (resolve, reject) {
            $.get(url).done(resolve).fail(reject);
        });

        return promise;
    }
}
```

我们再来总结一下，`BookmarkStore`在初始化的时候，显式地调用了`onFetch`，这个动作会导致`BookmarkList`组件的`state`的更新，这个更新会导致`BookmarkList`的重绘，`BookmarkList`会依次迭代所有的`Bookmark`。


### 更复杂一些

当然，Reflux的好处不仅仅是上面描述的这种单向数据流。当`Store`，`Actions`以及具体的`组件`被解耦之后，构建大型的应用才能成为可能。我们来对上面的应用做一下扩展：我们为列表添加一个搜索功能。

随着用户的键入，我们发送请求到服务器，将过滤后的数据渲染为新的列表。我们需要这样几个东西

1.  一个SearchBox组件
2.  一个新的`Action`：`search`
3.  `BookmarkStore`上的一个新方法`onSearch`
4.  组件`SearchBox`需要和`BookmarkActions`关联起来

为了让用户看到匹配的效果，我们需要将匹配到的关键字高亮起来，这样我们需要在`Bookmark`组件中监听`BookmarkStore`，当`BookmarkStore`发生变化之后，我们就可以即时修改书签的`title`了。

#### 搜索框组件

```js
var React = require('react');
var BookmarkActions = require('../actions/bookmark-actions');

var SearchBox = React.createClass({
	performSearch: function() {
		var keyword = this.refs.keyword.value;
		BookmarkActions.search(keyword);
	},

	render: function() {
		return <div className="search">
			<input type='text' 
				placeholder='type to search...' 
				ref="keyword"
				onChange={this.performSearch} />	
		</div>
	}
});

module.exports = SearchBox;
```

#### BookmarkStore

```js
var $ = require('jquery');
var Reflux = require('reflux');
var BookmarkActions = require('../actions/bookmark-actions');

var Utils = require('../utils/fetch-client');

var BookmarkStore = Reflux.createStore({
	listenables: [BookmarkActions],

	init: function() {
		this.onFetch();
	},

	onFetch: function() {
		var self = this;
		Utils.fetch('/bookmarks').then(function(bookmarks) {
			self.trigger({
				data: bookmarks,
				match: ''
			});
		});
	},

	onSearch: function(keyword) {
		var self = this;

		Utils.fetch('/bookmarks?keyword='+keyword).then(function(bookmarks) {
			self.trigger({
				data: bookmarks,
				match: keyword
			});
		});
	}
});

module.exports = BookmarkStore;
```

我们在`BookmarkStore`中添加了`onSearch`方法，它会根据关键字来调用后台API进行搜索，并将结果`trigger`出去。由于数据本身的结构并没有变化（只是数量会由于过滤而变少），因此`BookmarkList`是无需修改的。

#### 书签高亮

当搜索匹配之后，我们可以将对应的关键字高亮起来，这时候我们需要修改`Bookmark`组件：

```js
var React = require('react');
var Reflux = require('reflux');
var moment = require('moment');

var BookmarkStore = require('../stores/bookmark-store.js');

var Bookmark = React.createClass({
	mixins: [Reflux.listenTo(BookmarkStore, 'onMatch')],

    onMatch: function(data) {
        this.setState({
            match: data.match
        });
    },

	getInitialState: function() {
		return {
			match: ''
		}
	},

	render: function() {
		var created = new Date(this.props.created * 1000);
		var date = moment(created).format('YYYY-MM-DD');

		var title = this.props.title;
		if(this.state.match.length > 0) {
			title = <span
		        dangerouslySetInnerHTML={{
		          __html : this.props.title.replace(new RegExp('('+this.state.match+')', "gi"), '<span class="highlight">$1</span>')
		        }} />
		}

		return <li>
			<div className='bookmark'>
				<h5 className='title'>{title}</h5>
				<span className='date'>Created @ {date}</span>
			</div>
		</li>;
	}
});

module.exports = Bookmark;
```

`mixins: [Reflux.listenTo(BookmarkStore, 'onMatch')]`表示，我们需要监听`BookmarkStore`的变化，当变化发生时，调用`OnMatch`方法。`OnMatch`会修改组件的`match`属性，从而触发`render`。

在`render`中，我们替换关键字为`<span class="highlight">$keyword</span>`，这样就可以达到预期的效果了：

![bookmark search](/images/2015/11/bookmark-search-resized.png)

### 结论

从上面的例子可以看到，我们从一开始就引入了Reflux。虽然第一个版本和React原生的写法差异并不是很大，但是当加入`SearchBox`功能之后，需要修改的地方非常清晰：添加`Actions`，在对应的`Store`中添加callback，然后在组件中使用。这种方法不仅可以最大程度的使用`React`的长处（diff render），而且使得代码逻辑变得较为清晰。

随着业务代码的不断增加，Reflux提供的方式确实可以在一定程度上控制代码的复杂性和可读性。

完整的[代码地址在这里](https://github.com/abruzzi/react-reflux-demo)。

### 其他参考

-  [Reflux“宣言”](http://www.bunniesandbeatings.com/RefluxManifesto/)
-  [Flux is the new WndProc](https://news.ycombinator.com/item?id=10381015)
-  [React Reflux Example](https://ochronus.com/react-reflux-example/)

