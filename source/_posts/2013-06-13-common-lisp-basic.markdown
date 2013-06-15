---
layout: post
title: "common lisp 里的一些基本概念"
date: 2013-06-13 16:15
comments: true
categories: 
- lisp
- functional programming

---

###Common Lisp

之前一直说JavaScript是一门被误解很深的语言，现在学习了一段时间Lisp后发现，Lisp才是！Lisp一直为人所诟病的是它虽然很强大，但是有点学院派，难当大用。但是读了七，八章[《Practical Common Lisp》](http://book.douban.com/subject/6859720/)和几章[《ANSI Common Lisp》](http://book.douban.com/subject/1456906/)之后发现，怎么就学院派了，其他编程语言能处理的，Lisp一样可以处理，其他语言处理不了的（或者很繁琐的，比如java中的循环，map之类），Lisp却能处理。

Lisp本质上是一个抽象语法树（AST）而已，但是又提供了一些操作这个AST的方法（比如强大的宏），这样很容易用Lisp开发出来一个新的DSL。用函数式编程的好处之一就是在编写完一个应用程序之后，通常还可以获得一个新的语言（于业务领域很匹配的语言）。

[Common Lisp](http://zh.wikipedia.org/wiki/Common_Lisp)本身是Lisp的一个方言，是有一个标准来定义，其目的是为了标准化众多的Lisp分支而定。

#### sbcl环境

[上一篇文章](http://icodeit.org/2013/06/setup-lisp-development-env-on-mac/)已经介绍了如何在Mac下配置Common Lisp的开发环境：

![image](http://abruzzi.github.com/images/2013/06/sbcl.resized.png)

#### 引用（quote）

由于在Lisp中，数据和代码都是通过S-expr来表示，所以需要用一种标记法来告诉解释器：这个表达式表示数据/代码。这就是引用的作用：

```
> (+ 1 2 3 4 5)
15

> '(+ 1 2 3 4 5)
(+ 1 2 3 4 5)
```
解释器会将s-expr的第一项作为函数(car)，而将后续的元素(cdr)作为参数传递给第一项来调用，并求值。可以通过引用（quote）来阻止解释器这样解释。

#### 反引号(`)

与引用对应的，有一个反引号形式的引用(在键盘上1的左边)。一般的用法上，它与`quote`的含义一样，都是防止解释器解释被引用的列表。

```
>`(a b c)
(a b c)

>`(a b (+ 1 2))
(a b (+ 1 2))
```	

但是，反引号引用的列表提供了重新启动求值的能力，这……，我的意思是，如上式中，如果想要将`(+1 2)`这个子列表求值，怎么做到呢？反引号引用提供了这个能力，用逗号(,)作为子列表的前缀即可：

```
>`(a b ,(+ 1 2))
(a b 3)
```

这个当然在此刻看起来毫无用处，或者感觉略有画蛇添足之嫌，但是在宏中，这个操作符却有很广泛的用途，这里有一个有意思的例子：

```
(defun foo (x) 
  (only (> x 10) (format t "big than 10")))
```

我们可以通过`if`来实现此处的only，当only之后的条件满足的话，就执行后续的所有语句：

```
(defmacro only (condition &rest body)
  `(if ,condition (progn ,@body)))
```

此处可以看到，对于宏代码体中，有部分代码我们不需要引用，如(if, progn)，而另外一部分则需要解释器真实地去解释来获得值。另外，我们需要宏本身返回一个列表(被引用的列表)。

#### 通用的循环（do）

`do`是Lisp中通用的处理迭代的操作符，可以在其中创建局部变量：

```
(do ((i 0 (1+ i)))
    ((>= i 4))
  (print i))
```

`do`的格式比较复杂：

```
(do (variable-definition*)
	(end-test-form result-form*)
	statement*)
```

其中，变量声明部分的格式为：

```
(variable init-form step-form)
```

然后是测试，如果测试成功，有一个可选的返回值（上例中为nil），然后是statement部分，如果测试失败，则执行一次statement，然后通过step-from修改变量的值，测试，执行。

上例的代码会打印**0-3**的数字。`do`的另外一个功用是它支持多个变量并发的循环，这是(dolist, dotimes等无法完成的，所以在很多宏中，do是不二之选)。

```
(do ((n 0 (1+ n))
     (cur 0 next)
     (next 1 (+ cur next)))
    ((= 10 n) cur))
```

这个例子则没有statement部分，当n等于10这个测试条件成立后，返回cur当前的值。

#### apply 和 funcall

`apply/call` 这两个函数当然是FP编程语言的必备了：

```
> (apply #'(lambda (x y) (+ x y)) '(3 4))
7

> (funcall #'(lambda (x y) (+ x y)) 3 4)
8
```

注意这里的`#'`操作符，它表示对函数对象的引用，就像`'`是对list的引用一样。

#### list的基本操作

构造列表（cons），`cons`的作用是将两个对象结合成一个对象（这个新的对象由两部分组成），这两部分分别由`car`,`cdr`来引用。

```
> (cons 'a nil)
(a)

> (cons 'a (cons 'b nil))
(a b)
```

当然可以用更简洁的方式：使用list函数：

```
> (list a b)
(a b)
```

`car`, `cdr`的用法如下：

```
> (setf x '(a b c (d e)))
(a b c (d e))

> (car x)
a

> (cdr x)
(b c (d e))

```

有了`car`,`cdr`，对于既定的list，我们总是可以将其遍历（这在宏中非常有用）。

