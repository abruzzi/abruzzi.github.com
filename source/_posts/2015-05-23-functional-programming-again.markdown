---
layout: post
title: "又一篇JavaScript的函数式编程教程"
date: 2015-05-23 17:37
comments: true
categories: 
- functional
- JavaScript
---
## 前言

4月初在北京的时候，徐昊同学表示我们公司的同事们写的文章都太简单，太注重细节，然后捡起了芝麻丢了西瓜，于是我就不再更新博客（其实根本原因是项目太忙）。上周和其他几个同事一起参加“Martin Fowler深圳行”的活动，我和同事扎西贡献了一个《FullStack Language JavaScript》，一起的还有杨云的话题是《函数式编程》，李新的话题是《并发的前世今生》。

和其他同事预演的时候，突然发现其实我们的主题或多或少都有些关联，

1.	基于事件（Event-Based）的Node.js的正是并发中很典型的一个模型
2.	函数式编程使其天然支持回调，从而非常适合异步/事件机制
3.	函数式编程特性使其非常适合DSL的编写

会后第二天，在项目代码里忽然想要将一个聚合模型用函数式编程的方式重写一下，结果发现思路竟然与NoSQL依稀有些联系，进一步发现自己很多不足。

下面这个例子来自于实际项目中的场景，不过domain做了切换，但是丝毫不影响阅读和理解背后的机制。

### 一个书签应用

设想有这样一个应用：用户可以看到一个订阅的RSS的列表。列表中的每一项（称为一个Feed），包含一个`id`，一个文章的标题`title`和一个文章的链接`url`。

数据模型看起来是这样的：

```js
var feeds = [
    {
        'id': 1,
        'url': 'http://abruzzi.github.com/2015/03/list-comprehension-in-python/',
        'title': 'Python中的 list comprehension 以及 generator'
    },
    {
        'id': 2,
        'url': 'http://abruzzi.github.com/2015/03/build-monitor-script-based-on-inotify/',
        'title': '使用inotify/fswatch构建自动监控脚本'
    },
    {
        'id': 3,
        'url': 'http://abruzzi.github.com/2015/02/build-sample-application-by-using-underscore-and-jquery/',
        'title': '使用underscore.js构建前端应用'
    }
];
```

当这个简单应用没有任何用户相关的信息时，模型非常简单。但是很快，应用需要从单机版扩展到Web版，也就是说，我们引入了用户的概念。每个用户都能看到一个这样的列表。另外，用户还可以收藏Feed。当然，收藏之后，用户还可以查看收藏的Feed列表。

![feed and user](/images/2015/05/bookmarks.png)

由于每个用户可以收藏多个Feed，而每个Feed也可以被多个用户收藏，因此它们之间的多对多关系如上图所示。可能你还会想到诸如:

```sh
$ curl http://localhost:9999/user/1/feeds
```

来获取用户`1`的所有`feed`等，但是这些都不重要，真正的问题是，当你拿到了所有Feed之后，在UI上，需要为每个Feed填加一个属性`makred`。这个属性用来标示该feed是否已经被收藏了。对应到界面上，可能是一枚黄色的星星，或者一个红色的心。

![bookmarkds design](/images/2015/05/bookmarks-design-resized.png)

#### 服务器端聚合

由于关系型数据库的限制，你需要在服务器端做一次聚合，比如将feed对象包装一下，生成一个`FeedWrapper`之类的对象：

```java
public class FeedWrapper {
    private Feed feed;
    private boolean marked;

    public boolean isMarked() {
        return marked;
    }

    public void setMarked(boolean marked) {
        this.marked = marked;
    }

    public FeedWrapper(Feed feed, boolean marked) {
        this.feed = feed;
        this.marked = marked;
    }
}
```

然后定义一个`FeedService`之类的服务对象：

```java
public ArrayList<FeedWrapper> wrapFeed(List<Feed> markedFeeds, List<Feed> feeds) {
    return newArrayList(transform(feeds, new Function<Feed, FeedWrapper>() {
        @Override
        public FeedWrapper apply(Feed feed) {
            if (markedFeeds.contains(feed)) {
                return new FeedWrapper(feed, true);
            } else {
                return new FeedWrapper(feed, false);
            }
        }
    }));
}
```

好吧，这也算是一个还凑合的实现，但是静态强类型的Java做这个事儿有点勉强，而且一旦发生新的变化（几乎肯定会发生），我们还是把这部分逻辑放在JavaScript中，来看看它是如何简化这一个过程的。

#### 客户端聚合

快要说到主题了，这篇文章我们会使用`lodash`作为函数式编程的库来简化代码的编写。由于JavaScript是一个动态弱类型的语言，我们可以随时为一个对象添加属性，这样一个简单的`map`操作就可以完成上边的Java对应的代码了：

```js
_.map(feeds, function(item) {
    return _.extend(item, {marked: isMarked(item.id)});
});
```

其中函数`isMarked`会做这样一件事儿：

```js
var userMarkedIds = [1, 2];
function isMarked(id) {
    return _.includes(userMarkedIds, id);
}
```

即查看传入的参数是否在一个列表`userMarkedIds`，这个列表可能由下列的请求来获得：

```sh
$ curl http://localhost:9999/user/1/marked-feed-ids
```

之所有只获取id是为了减少网络传输的数据大小，当然你也可以将全部的`/marked-feeds`都请求到，然后在本地做`_.pluck(feeds, 'id')`来抽取所有的`id`属性。

嗯，代码是精简了许多。但是如果仅仅能做到这一步的话，也没有多大的好处嘛。现在需求又有了变化，我们需要在另一个页面上展示当前用户的收藏夹（用以展示用户所有收藏的feed）。作为程序员，我们可不愿意重新写一套界面，如果能复用同一套逻辑当然最好了。

比如对于上面这个列表，我们已经有了对应的模板：

```html
{{#each feeds}}
<li class="list-item">
    <div class="section" data-feed-id="{{this.id}}">
        {{#if this.marked}}
            <span class="marked icon-favorite"></span>
        {{else}}
            <span class="unmarked icon-favorite"></span>
        {{/if}}
        <a href="/feeds/{{this.url}}">
            <div class="detail">
                <h3>{{this.title}}</h3>
            </div>
        </a>
    </div>
</li>
{{/each}}
```

事实上，这段代码在收藏夹页面上完全可以复用，我们只需要把所有的`marked`属性都设置为true就行了！简单，很快我们就可以写出对应的代码：

```js
_.map(feeds, function(item) {
    return _.extend(item, {marked: true});
});
```

漂亮！而且重要的是，它还可以如正常工作！但是作为程序员，你很快就发现了两处代码的相似性：

```js
_.map(feeds, function(item) {
    return _.extend(item, {marked: isMarked(item.id)});
});

_.map(feeds, function(item) {
    return _.extend(item, {marked: true});
});
```

消除重复是一个有追求的程序员的基本素养，不过要消除这两处貌似有点困难：位于`marked:`后边的，一个是函数调用，另一个是值！如果要简化，我们不得不做一个匿名函数，然后以回调的方式来简化：

```js
function wrapFeeds(feeds, predicate) {
    return _.map(feeds, function(item) {
        return _.extend(item, {marked: predicate(item.id)});
    });
}
```

对于feed列表，我们要调用：

```js
wrapFeeds(feeds, isMarked);
```

而对于收藏夹，则需要传入一个匿名函数：

```js
wrapFeeds(feeds, function(item) {return true});
```

在`lodash`中，这样的匿名函数可以用`_.wrap`来简化：

```js
wrapFeeds(feeds, _.wrap(true));
```

好了，目前来看，简化的还不错，代码缩减了，而且也好读了一些（当然前提是你已经熟悉了函数式编程的读法）。

#### 更进一步

如果仔细审视`isMarked`函数，会发现它对外部的依赖不是很漂亮（而且这个外部依赖是从网络异步请求来的），也就是说，我们需要在请求到`markedIds`的地方才能定义`isMarked`函数，这样就把函数定义`绑定`到了一个固定的地方，如果该函数的逻辑比较复杂，那么势必会影响代码的可维护性（或者更糟糕的是，多出维护）。

要将这部分代码隔离出去，我们需要将`ids`作为参数传递出去，并得到一个可以当做谓词（判断一个id是否在列表中的谓词）的函数。

简而言之，我们需要：

```js
var predicate = createFunc(ids);
wrapFeeds(feeds, predicate);
```

这里的`createFunc`函数接受一个列表作为参数，并返回了一个谓词函数。而这个谓词函数就是上边说的`isMarked`。这个神奇的过程被称为柯里化`currying`，或者偏函数`partial`。在`lodash`中，这个很容易实现：

```js
function isMarkedIn(ids) {
    return _.partial(_.includes, ids);
}
```

这个函数会将`ids`保存起来，当被调用时，它会被展开为：`_.includes(ids, <id>)`。只不过这个`<id>`会在实际迭代的时候才传入：

```js
$('/marked-feed-ids').done(function(ids) {
    var wrappedFeeds = wrapFeeds(feeds, isMarkedIn(ids));
    console.log(wrappedFeeds);
});
```

这样我们的代码就被简化成了：

```js
$('/marked-feed-ids').done(function(ids) {
    var wrappedFeeds = wrapFeeds(feeds, isMarkedIn(ids));
    var markedFeeds = wrapFeeds(feeds, _.wrap(true));
    
    allFeedList.html(template({feeds: wrappedFeeds}));
    markedFeedList.html(template({feeds: markedFeeds}));
});
```
