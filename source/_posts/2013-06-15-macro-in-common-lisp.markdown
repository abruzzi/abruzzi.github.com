---
layout: post
title: "Common Lisp中的宏(Macro)"
date: 2013-06-15 11:12
comments: true
categories: 
- lisp
- script
- functional programming

---

#### Lisp与其他语言之区别

函数式编程，前缀表达式，繁多的括号，奇怪的操作符等等，这些都足以让Lisp和其他编程语言看起来有很大的区别，但是这些区别并非本质上的差异。让Lisp和其他编程语言有本质区别的是它对`宏`的支持。

C语言中的，被称为`宏`的预编译系统自有其好处，但是和Lisp中的`宏`比起来，好比的Notepad和Vim或者Emacs之间的差异。

#### 数据与代码

在Lisp中，数据和代码间的差异非常小，[上一篇文章](http://icodeit.org/2013/06/common-lisp-basic/)简单讨论了`引用`的基本概念，其中对数据与代码的差异已经有所涉及。

#### 宏(Macro)

简而言之，`宏`即替换，在Lisp中，可以通过程序生成代码(s-expr)，而这些代码又可以被执行（当然，需要是合法的s-expr）。这一点赋予了`宏`无限的可能性，比如定义一个新的语法：

```
(defmacro only (condition &rest body)
  `(if ,condition (progn ,@body)))
```

Lisp中函数macroexpand-1可以用来查看调用时`宏`是如何展开的：

```
> (macroexpand-1 '(only (> x 10) (format t "big than 10")))   

(IF (> X 10)
    (PROGN (FORMAT T "big than 10")))
```

上例中，`(> x 10)`被作为`condition`，而`(format t "big than 10")`作为`body`传递给了宏。

```
> (macroexpand-1 '(only (> x 10) 
	(format t "big than 10")
	(format t "~%")))

(IF (> X 10)
    (PROGN (FORMAT T "big than 10") (FORMAT T "~%")))
```

使用`progn`是为了让剩余的多条语句(如果有的话)，逐条执行，并返回最后一条语句的值（正如在函数中那样）。


#### 可能的陷阱

[上一篇文章](http://icodeit.org/2013/06/common-lisp-basic/)中讨论了迭代的通用方式`do`，虽然很通用，但是三段式的定义略显繁琐。

我们可以编写一个简单的宏`ntimes`，它接受一个数字参数N和一个代码块Block，并执行N次这个Block：

```
(ntimes 10 (format t "Hello, world~%"))
```

将打印10次`Hello, world`，`宏`的定义如下：

```
(defmacro ntimes (n &rest prog)
  `(do ((x 0 (1+ x)))
       ((>= x ,n))
     ,@prog))
```

但是这个宏在某些场景下不能如预期般的工作：比如当在使用`ntimes`的context中，本身有一个变量x，而在代码块Block中，尝试修改这个x，会发生什么呢？


```
(let ((x 10))
    (ntimes 5
       (format t "~a~%" x)))
```

预期的执行结果为打印5次10，但是事实上：

```
0
1
2
3
4
```

这是因为`宏`的内部使用了同名的变量，而由于作用域的原因，外部的let被屏蔽了，事实上宏的设计者貌似无法避免这类事情的发生，因为使用者如何使用是不能预料的，Lisp提供了另一种解决方案(类似于UUID)，使用`gensym`，以避免这种情况：

```
> (gensym)

#:G778
> (gensym)

#:G779
```

函数`gensym`每次都会分配一个新的ID作为标示，因此宏的实现可以修改为：

```
(defmacro ntimes (n &rest prog)
  (let ((g (gensym)))
    `(do ((,g 0 (+ ,g 1)))
         ((>= ,g ,n))
       ,@prog)))
```

事实上，这个版本还是有一个隐藏的bug：这里我们预期的n是一个数字，而实际上使用者是可以传入一个表达式如：`(setf x (- x 1))`，而由于`do`的特性，迭代中每次都查看测试条件是否满足`(>= ,g ,n)`，这会使得`(setf x (- x 1))`会被执行N次。也就是说，当数字N是一个有副作用的表达式时，我们的宏的行为是错误的，可以通过引入额外的临时变量来解决这个问题。

即在最开始的适合对N求值并赋值给一个临时变量，然后每次的测试都是基于这个临时变量而来：

```
(defmacro ntimes (n &rest prog)
  (let ((g (gensym))
        (h (gensym)))
    `(let ((,h ,n))
       (do ((,g 0 (+ ,g 1)))
           ((>= ,g ,h))
         ,@prog))))
```

#### 定义新的语法

这一小节的一个例子是for循环的`宏`定义：

```
(defmacro for (var start stop &body body)
  (let ((gstop (gensym)))
    `(do ((,var ,start (1+ ,var))
          (,gstop ,stop))
         ((> ,var ,gstop))
       ,@body)))
```

这样，可以很方便的使用我们比较熟悉的for语句了：

```
> (for x 1 5
     (print x))

1 
2 
3 
4 
5 
```

另一个有意思的例子是求平均值的`avg`宏：

```
(defmacro avg (&rest args)
  `(/ (+ ,@args) ,(length args)))
```

由于Lisp中采取前缀表达式，因此像`+`这种函数可以很方便的apply到一个列表上，如果是中缀表达式，则这种形式的抽象就变得非常复杂。

```
> (macroexpand-1 '(avg 1 2 3 4 5 6 7 8 9 10))
(/ (+ 1 2 3 4 5 6 7 8 9 10) 10)

> (avg 1 2 3 4 5 6 7 8 9 10)
11/2
```

- - -

附：文中部分代码示例来源于《ANSI Common Lisp》一书。