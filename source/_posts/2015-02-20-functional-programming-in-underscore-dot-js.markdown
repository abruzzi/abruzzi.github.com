---
layout: post
title: "underscore.js中的函数式编程"
date: 2015-02-20 20:11
comments: true
categories: 
- functional programming
- effective
---

## JavaScript中的map/reduce

在过去的10年间，不论你是否对大数据有所涉足，你肯定听过`map/reduce`这个貌似很高大上的词。这个高大上的词事实上来自于`函数式编程`世界。`map`的意思是影射，即将一个集合中的内容，通过应用某种函数，形成另外一个集合。`reduce`表示求和，或者规约，即将一个集合以某种函数规约为一个值。

[underscore.js](http://underscorejs.org/)是一个`非常强大`的JavaScript库，也是我的工具箱里的必备品。事实上在我自己的小项目中，我更倾向于使用`jQuery`+`underscore.js`来完成所有的功能，而不是使用诸如`AngularJS`之类的框架。

作为一个库，`underscore.js`提供了丰富的API来操作JavaScript中的集合，对象，函数等，可以节省程序员大量的时间，我们在这篇文章中来看看`underscore.js`中基本的函数式编程特性。

### 使用map消除for-loop

我们先来看一个小例子：我们要编写一个名为`makeQuery`的函数，它接受一个JavaScript对象和一个分隔符，然后将JavaScript对象展开，形成`key=value[分隔符key=value]`的形式。正如下面这个测试所反映的：

```js
it("make query from object", function() {
    var cookies = {
        "JSESSIONID": "6C729E682C05AA56017E3D1675CE8E5F",
        "_USER": "GEO-NASTAR"
    };

    var expected = "JSESSIONID=6C729E682C05AA56017E3D1675CE8E5F;_USER=GEO-NASTAR";

    expect(makeQuery(cookies, ";")).toEqual(expected);
});
```

一个直接的解决方案是：

```js
function makeQuery(obj, delimiter) {
    var strArray = [];

    for (var key in obj) {
        strArray.push(key + "=" + obj[key]);
    }

    return strArray.join(delimiter);
}
```

我们再来看另外一个小例子：给定一个字符串（人名）数组，将数组中的所有人名都变成大写字母开头。正如下面这个测试所反映：

```js
it("capitalize", function() {
    var names = ["juanchen", "mingliang", "lu", "juntao"];
    var expected = ["Juanchen", "Mingliang", "Lu", "Juntao"];

    expect(capitalize(names)).toEqual(expected);
});
```

一个可能的函数如下：

```js
function capitalize(strArrays) {
     var newArray= [];

     strArrays.forEach(function(str) {
          str = str.charAt(0).toUpperCase() + str.slice(1);
          newArray.push(str);
     });

     return newArray;
}
```

如果仔细观看这两函数实现，会发现虽然做的事情完全不同（一个做对象到字符串到的连接，一个做字符串的首字母大写转换），但是如果从稍微高一点的抽象层次来看，会发现其实这两个函数式`一样的`！！

如果写成伪代码：

```js
function xxx(array) {
    var newArray = [];

    forLoop(array, function(item) {
        newArray.push(doSomething(item));
    });

    return newArray;
}
```

即，声明一个新的数组，迭代传入的数组，然后做`某种操作`，将结果存入数组，最后返回该数组。由于JavaScript是一个支持函数式变成范式的语言，我们可以将`某种操作`从外部传入，这样，这部分代码就可以被重用了！！

```js
function xxx(array, func) {
    var newArray = [];

    forLoop(array, func(item));

    return newArray;
}
```

看着很眼熟对吧，没错，这就是`map`操作。目前`V8`引擎已经把这个操作内置到了语言级别了，你可以直接在数组上调用`map`来完成映射的操作。不过我们这篇文章的主角是`underscore.js`，因此来看看在`underscore.js`里怎么使用`map`吧，还是上面这两个例子：

```js
function makeQuery(params, delimiter) {
	return _.map(params, function (value, key) {
    	return key + '=' + value;
	}).join(delimiter);
}

function capitalize(items) {
	return _.map(items, function(item) {
		return item.charAt(0).toUpperCase() + item.substring(1).toLowerCase();
	});
}
```

对比一下会发现，我们已经将`for`语句消除掉了（它被内置到了`_.map`函数中了）。这是一个非常伟大的提升，而代码更加表意。

### 使用reduce简化`规约`

我们来看另一个例子：给定一个工资列表，我们要计算公司为我们交纳的公积金的总和，假设比率为15%。测试如下：

```js
it("calculate rate", function() {
    var rate = 0.15;
    var salaries = [3200.00, 1768.00, 4020.00];

    var total = calcRate(salaries, rate);

    expect(total).toEqual(1348.2);
})
```

一个直观的实现如下：

```js
function calcRate (salaries) {
    var rate = 0.15;
    var minimunCost = 0;

    salaries.forEach(function(salary) {
        minimunCost += salary * rate;
    });

    return minimunCost;
}
```

再来看一个例子：我们有一个单词列表，需要统计出每个单词出现的次数。测试如下：

```js
it("count word", function() {
    var words = ["hello", "hello", "my", "friend", "my", "heart"];

    var result = count(words);

    expect(result["hello"]).toEqual(2);
    expect(result["my"]).toEqual(2);
    expect(result["friend"]).toEqual(1);
    expect(result["heart"]).toEqual(1);
});
```

一个直接的实现函数如下：

```js
function count(words) {
	var result = {};

	words.forEach(function(word) {
		result[word] = (result[word] || 0) + 1;
	});

	return result;
}
```

现在再来仔细对比这两个实现，如果从稍微`高级别`的层次来抽象，会发现这两段代码是`一样的`，如果写成伪代码的话，看起来是这样的：

```js
function xxx(array [,func]) {
    var result;

    array.forEach(function(item) {
        result += func(item);
    });

    return result;
}
```

注意可以传入一个可选的`func`作为计算子，另外此处的`+=`表示某种形式的累加（count函数中的复赋值其实是另一种形式的累加）。

这种`传入一个数组，通过某种形式的累加而生成一个单独的值`的计算，被称为`reduce`函数。当然，现在`V8`引擎已经内置了对`reduce`的支持。我们来看看在`underscore.js`中如何使用`reduce`：

```js
function calcRate(items, rate) {
	return _.reduce(items, function (total, value) {
	    return total + value * rate;
	}, 0);
}

function count(words) {
	return _.reduce(words, function(frequencies, word) {
        frequencies[word] = (frequencies[word] || 0) + 1;
        return frequencies;
    }, {});
}
```

`_.reduce`接受三个参数，分别是集合，累加器，和一个可选的初始值。应该注意的是第二个参数是一个函数，而这个函数的参数需要特别说明：第一个参数是上一次累加器的返回值，在迭代的第一次，这个值是调用`_.reduce`时传入的初始值。

以`calcRate`为例，调用
`calcRate([1000, 2000, 1500], 0.15)`时，第一次调用中间匿名函数时，total的值为初始值`0`；第二次则为`0+1000*0.15 = 150`；第三次则为`150+2000*0.15 = 450`。

### 一个实际的例子

如果纯粹列举`underscore.js`的特性，难免变得枯燥，我们来编写一个`实际`的例子来学习`map/reduce`的用法。

假设我们有一段文本：

```
var text = 
"Hello darkness, my old friend,
I've come to talk with you again,
Because a vision softly creeping,
Left its seeds while I was sleeping,
And the vision that was planted in my brain
Still remains
Within the sound of silence.

In restless dreams I walked alone
Narrow streets of cobblestone,
'Neath the halo of a street lamp,
I turned my collar to the cold and damp
When my eyes were stabbed by the flash of a neon light
That split the night
And touched the sound of silence.

And in the naked light I saw
Ten thousand people, maybe more.
People talking without speaking,
People hearing without listening,
People writing songs that voices never share
And no one dared
Disturb the sound of silence."
```

我们来统计一下每个单词出现的次数，**不区分**大小写。JavaScript中的字符串对象有一个`match`方法，`match`的参数可以是正则表达式，返回该字符串的第一个匹配：

```js
"hello world".match(/\w+/)
//["hello"]

"... hello world".match(/\w+/)
//["hello"]
```

注意`...`没有匹配正则表达式`\w`。当参数为带有`g`(global)选项的正则表达式时，该函数会返回所有匹配该正则表达式的数组：

```js
"hello world".match(/\w+/g)
//["hello", "world"]

"... hello world".match(/\w+/g)
//["hello", "world"]
```

有了这个`match`我们就可以很容易的将上述的文本分割为一个单词的数组，而根据要求，我们需要将所有的单词都转成小写。

可以先编写一个分割文本并转换小写的函数：

```js
function text2words(text) {
    return _.map(text.match(/\w+/g), function(word) {
        return word.toLowerCase();
    });
}
```

而对应的count函数则为：

```js
function count(words) {
	return _.reduce(words, function(frequencies, word) {
        frequencies[word] = (frequencies[word] || 0) + 1;
        return frequencies;
    }, {});
}
```

<del>
还可以使用`underscore.js`的链式操作，使用`_(object)`生成一个`underscore`包装过的对象。然后就可以使用`_(object).map(...).reduce(...)`的形式了：
</del>

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

我们在下一篇文章中将介绍如何将这些API用连式操作连起来。

```

![wordcount](/images/2015/02/wordcount-resized.png)

