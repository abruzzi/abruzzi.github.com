---
layout: post
title: "Python中的 list comprehension 以及 generator"
date: 2015-03-30 17:06
comments: true
categories: 
- python
- functional programming
---

### 一个小故事
三年前，我在[一篇博客](http://icodeit.org/2012/07/post-from-python-vim-2/)里不无自豪的记录了python编写的小函数，当时感觉python真强大，11行代码就写出了一个配置文件的解析器。

```py
def loadUserInfo(fileName):
    userinfo = {}
    file = open(fileName, "r")
    while file:
        line = file.readline()
        if len(line) == 0:
            break
        if line.startswith('#'):
            continue
        key, value = line.split("=")
        userinfo[key.strip()] = value.strip()

	return userinfo
```

最近正在跟同事学习`python在数据挖掘中的应用`，又专门学习了一下python本身，然后用`list comprehension`简化了以下上面的代码：

```py
def loadUserInfo(file):
    return dict([line.strip().split("=")
        for line in open(file, "r")
            if len(line) > 0 and not line.startswith("#")])
```

这个函数和上面的函数的功能一样，都是读取一个指定的`key=value`格式的文件，然后构建出来一个`映射`（当然，在Python中叫做`字典`）对象，该函数还会跳过空行和`#`开头的行。

比如，我想要查看一下`.wgetrc`配置文件：

```py
if __name__ == "__main__":
    print(loadUserInfo("/Users/jtqiu/.wgetrc"))
```

假设我的`.wgetrc`文件配置如下：

```
http-proxy=10.18.0.254:3128
ftp-proxy=10.18.0.254:3128
#http_proxy=10.1.1.28:3128
use_proxy=yes
```

则上面的函数会产生这样的输出：

```
{'use_proxy': 'yes', 'ftp-proxy': '10.18.0.254:3128', 'http-proxy': '10.18.0.254:3128'}
```

### list comprehension（列表推导式）

在python中，`list comprehension`（或译为列表推导式）可以很容易的从一个列表生成另外一个列表，从而完成诸如`map`, `filter`等的动作，比如：

要把一个字符串数组中的每个字符串都变成大写：
```py
names = ["john", "jack", "sean"]

result = []
for name in names:
    result.append(name.upper())
```

如果用列表推导式，只需要一行：

```py
[name.upper() for name in names]
```

结果都是一样：

```
['JOHN', 'JACK', 'SEAN']
```

另外一个例子，如果想要过滤出一个数字列表中的所有偶数：

```py
numbers = [1, 2, 3, 4, 5, 6]

result = []
for number in numbers:
    if number % 2 == 0:
        result.append(number)
```

如果写成列表推导式：

```py
[x for x in numbers if x%2 == 0]
```

结果也是一样：

```
[2, 4, 6]
```

显然，列表推导更加短小，也更加表意。

### 迭代器

在了解`generator`之前，我们先来看一个`迭代器`的概念。有时候我们不需要将整个列表都放在内存中，特别是当列表的尺寸比较大的时候。

比如我们定义一个函数，它会返回一个连续的整数的列表：

```py
def myrange(n):
    num, nums = 0, []
    while num < n:
        nums.append(num)
        num += 1
    return nums
```

当我们计算诸如`myrange(50)`或者`myrange(100)`时，不会有任何问题，但是当获取诸如`myrange(10000000000)`的时候，由于这个函数的内部会将数字保存在一个临时的列表中，因此会有很多的内存占用。

因此在python有了迭代器的概念：

```py
class myrange(object):
    def __init__(self, n):
        self.i = 0
        self.n = n

    def __iter__(self):
        return self

    # for python 3
    def __next__(self):
        return self.next()

    def next(self):
        if self.i < self.n:
            i = self.i
            self.i += 1
            return i
        else:
            raise StopIteration()
```

这个对象其实实现了两个特殊的方法：`__iter__`（对于python3来说，是`__next__`）和`next`方法。其中`next`每次只返回一个值，如果迭代已经结束，就抛出一个`StopIteration`的异常。实现了这两个方法的类都可以算作是一个迭代器，他们可以被用于`可迭代`的上下文中，比如：

```py
>>> from myrange import myrange
>>> x = myrange(10)
>>> x.next()
0
>>> x.next()
1
>>> x.next()
2
```

但是可以看到这个函数中有很多的样板代码，因此我们有了生成器表达式来简化这个过程：

```py
def myrange(n):
    num = 0
    while num < n:
        yield num
        num += 1
```

注意此处的`yield`关键字，每次使用`next`来调用这个函数时都会求值一次num并返回，具体的细节可以[参考这里](http://www.jeffknupp.com/blog/2013/04/07/improve-your-python-yield-and-generators-explained/)。

### 区别

简单来说，两者都可以在迭代器上下文中使用，看起来几乎是一样的。不同的地方是`generator`可以节省内存空间，从而提高执行速度。`generator`更适合一次性的列表处理，比如只是需要一个中间列表作为转换。而列表推导则更适合要将`列表`保存下来，以备后续使用的场景。

这里也有[一些讨论](http://stackoverflow.com/questions/47789/generator-expressions-vs-list-comprehension)，可以一并参看。

### 参考

1.	[Iterators & Generators](http://anandology.com/python-practice-book/iterators.html)
2.	[Generators Wiki](https://wiki.python.org/moin/Generators)