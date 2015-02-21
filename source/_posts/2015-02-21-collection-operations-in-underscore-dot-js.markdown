---
layout: post
title: "underscore.js中的集合操作"
date: 2015-02-21 12:48
comments: true
categories: 
- functional programming
- effective
---

## underscore.js中的集合操作

[书接前文](icodeit.org/2015/02/functional-programming-in-underscore-dot-js/)，我们在上一篇中将一个文本划分成了单词的数组，并统计了每个单词出现的频率。现在我们需要将排行前10的单词找出来。那么第一步就是将所有单词按照频率排序，然后将这个集合的前10个拿出来。

`underscore.js`为集合提供了丰富的API，这与函数式编程的鼻祖`LISP`语言有着直接的继承关系。`LISP`围绕着`List`提供了的众多函数。

### 排序

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
```

比如想要将上面这个集合按照`age`排序，可以使用`sortBy`函数：

```js
var sorted = _(contacts).sortBy("age");
```

默认的`sortBy`的返回值是按照升序排列的，不过JavaScript的数组原生就有reverse的API用以翻转数组，因此如果要得到降序的排列，只需要：

```js
var sorted = _(contacts).sortBy("age").reverse();
```

### 抽取

有时候，我们需要从众多的信息中抽取自己关心的，比如上例中的`contacts`集合，我们在界面上仅仅需要`name`属性组成的集合，这时候可以通过`pluck`来完成抽取：

```js
var names = _.pluck(contacts, "name");
//["juntao", "abruzzi", "sara"]
```

`underscore.js`默认的`pluck`只能抽取一层，如果遇到下面这种场景：

```js
var contacts = [
	{
    	"name": "Juntao",
        "age": 29,
        "address": {
        	"street": "Dengling Rd"
        }
    },
    {
    	"name": "Sara",
        "age": 29,
        "address": {
        	"street": "Zhangba 4th Rd"
        }
    }
]
```

想要抽取`address.street`就无能为力了，不过我们可以很容易的增强一下`pluck`的功能。先来写一个小测试：

```js
it("deep pluck", function() {
    var contacts = [
        {
            "name": "Juntao",
            "age": 29,
            "address": {
                "street": "Dengling Rd"
            }
        }
    ];

    var result = deeppluck(contacts, "address.street");

    expect(result[0]).toEqual("Dengling Rd");
});
```

然后是实现：

```js
function deeppluck(origin, property) {
	if (property.indexOf(".") < 0) {
		return _.pluck(origin, property)
	}

	var object = _.clone(origin);
	var chain = property.split(".");

	_(chain).each(function(key) {
		object = _.pluck(object, key);
	});

	return object;
}
```

这样就可以深度的抽取了：

```js
deeppluck(contacts, "address.street");
//["Dengling Rd", "Zhangba 4th Rd"]
```

`underscore`提供了类似于`Ruby`中的`mixin`扩展，这样就可以将我们自定义的函数添加到`underscore`中了。扩展方法很容易，只需要为`mixin`传入一个键值对(`函数名：函数`)即可：

```js
_.mixin({
	deeppluck: function(origin, property) {
		if (property.indexOf(".") < 0) {
			return _.pluck(origin, property)
		}

		var object = _.clone(origin);
		var chain = property.split(".");

		_(chain).each(function(key) {
			object = _.pluck(object, key);
		});

		return object;
	}
});
```

这样`deeppluck`就和其他`underscore`内置的API一样被使用了：

```js
_.deeppluck(contacts, "address.street");
//["Dengling Rd", "Zhangba 4th Rd"]

_(contacts).deeppluck("address.street");
//["Dengling Rd", "Zhangba 4th Rd"]
```

### 按照频率排序单词列表

好了，有了这些基础知识，我们来完成今天的变成任务吧。我们昨天得到的数据格式是这样的：

```json
{
    "drools": 3,
    "extends": 2,
    "rete": 2,
    "by": 3,
    "optimizing": 1,
    "the": 23,
    "propagation": 1,
    "from": 3,
    "objecttypenode": 2,
    "to": 11,
    "alphanode": 5,
    "using": 1,
    "hashing": 1,
    "each": 4,
    "time": 1,
    ...
}
```

这个格式无法使用`sortBy`，那么最简单的方式就是做一下`map`操作，使其变为：

```json
[
	{
		"word": "drools",
		"count": 3
	},
	{
		"word": "extends",
		"count": 2
	},
	...
]
```

根据昨天学到的`_.map`，很容易写出：

```js
function sortWords(wordMap) {
    var mapped = _(wordMap).map(function(value, key) {
        return {
            "word": key,
            "count": value
        };
    });

    return _(mapped).sortBy("count").reverse();
}
```

### 取出指定数目的元素

由于`sortWords`返回的是一个JavaScript原生的数组，我们可以使用原生的API来取出前10个元素：

```js
var sorted = sortWords(wordMap)
var top10 = sorted.splice(0, 10);
```

不过`underscore.js`提供更友好的`take`函数：

```js
var sorted = sortWords(wordMap);
var top10 = _(sorted).take(10);
```

基于已经学习到的这些API，我们可以包装一下，形成这样以一个函数：

```js

function topWords(wordMap, n) {
    var mapped = _(wordMap).map(function(value, key) {
        return {
            "word": key,
            "count": value
        };
    });

    var sorted = _(mapped).sortBy("count").reverse();

    return _(_(sorted).take(n)).pluck("word");
}
```

这个函数可以取出频率最高的前N个单词：

```js
topWords(wordMap, 1)
//["the"]

topWords(wordMap, 3)
//["the", "a", "to"]

topWords(wordMap, 10)
//["the", "a", "to", "is", "and", "input", "as", "alphanode", "we", "objects"]
```

当然，上面的代码可以略微压缩一下：

```js
function topWords(wordMap, n) {
    return _(_(_(_(wordMap).map(function(value, key) {
        return {
            "word": key,
            "count": value
        };
    })).sortBy("count").reverse()).take(n)).pluck("word");
}
```

啊偶，有点难看了。幸好`underscore.js`提供了链式操作

### 链式操作

如果你用过jQuery，那么应该对链式操作非常熟悉了。链式操作写起来非常顺畅，代码也会非常的语义化。`underscore.js`中也支持将代码写成链式的，API为`chain`，`chain`返回的是一个包装过的`underscore`对象，到链结束的时候，需要调用`value`来获取最终的结果：

比如

```js
function count(text) {
    var mapped = _(text.match(/\w+/g)).map(function(word) {
        return word.toLowerCase()
    });

    return _(mapped).reduce(function(frequencies, word) {
        frequencies[word] = (frequencies[word] || 0) + 1;
        return frequencies;
    }, {});
}
```

可以简化为：

```js
function count(text) {
    return _.chain(text.match(/\w+/g))
    .map(function(word) {
        return word.toLowerCase()
    })
    .reduce(function(frequencies, word) {
        frequencies[word] = (frequencies[word] || 0) + 1;
        return frequencies;
    }, {})
    .value();
}
```

同样，我们刚才`简化`过的那段很难看的代码也可以写成：

```js
function topWords(wordMap, n) {
    return _.chain(wordMap)
        .map(function(value, key) {
            return {
                "word": key,
                "count": value
            };
        })
        .sortBy("count")
        .reverse()
        .take(n)
        .pluck("word")
        .value();
}
```

最终，我们的代码就被缩减成了：

```js
var text = "...";
var top10 = topWords(count(text), 10);
//["the", "a", "to", "is", "and", "input", "as", "alphanode", "we", "objects"]
```

可以看到，使用`underscore.js`提供的众多API，可以写出非常简洁，表意的代码来。这也是函数式编程逐步占领`主流`编程世界的一个重要原因吧。