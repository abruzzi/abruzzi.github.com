---
layout: post
title: "SVN中合并分支"
date: 2014-08-25 22:42
comments: true
categories: 
- SVN
- Command line

---
### 分支策略

本来准备整理一篇版本管理中，关于分支的维护策略。后来看到阮一峰老师的[这篇文章](http://www.ruanyifeng.com/blog/2012/07/git.html)，觉得非常清晰，这里给出一个链接供参考。

另外一个有意思的[链接在这里](http://codicesoftware.blogspot.com/2008/08/4-steps-to-make-version-control-shine.html)，也可以一并参看。

本文就仅仅简单的描述一下，使用svn的命令行工具，如何具体完成合并的操作：

### 在Svn中合并分支

在svn中，要合并两个分支（通常是将某个分支b合并到trunk上，不过另一种模式下也可以将trunk合并到b上）非常简单，我们以一个简单的例子来说明其步骤。

比如我们要将trunk上的修改合并到分支b上，操作可以分为4步：

1.	切换到分支b上（之前执行过`svn co /path/branches/b`之后的目录）
2.	使用`svn log --stop-on-copy`命令得到该分支的最早版本号
3.	使用`svn merge --dry-run -rXXX:HEAD /path/trunk`来预览合并列表
4.	合并

在第二步中，一个典型的输出是这样的：

```sh
$ svn log --stop-on-copy                                                                   
...

r231625 | juntao | 2014-07-10 13:33:36 +1000 (Thu, 10 Jul 2014) | 1 line

Juntao Change the version in pom.xml
------------------------------------------------------------------------
r231623 | abruzzi | 2014-07-10 13:22:00 +1000 (Thu, 10 Jul 2014) | 1 line

Spike on data structure of c-wifi, a workable prototype
------------------------------------------------------------------------
r231610 | juntao | 2014-07-10 12:29:01 +1000 (Thu, 10 Jul 2014) | 1 line

Create a new branch for c-wifi
------------------------------------------------------------------------
```

一旦有了这个修订号(231610)，就可以开始合并了：

```sh
$ svn merge --dry-run -r231610:HEAD /path/trunk
```

这个命令会列出从修订好r231610到当前版本之中，trunk和分支b之间的所有需要合并的文件列表：

```
--- Merging r235763 through r236311 into 'src/test/java':
U    src/test/java/tcom/checkout/CheckoutServiceTest.java
U    src/test/java/bundles/checkout/accordion/AppointmentTest.java
U    src/test/java/common/service/ServiceHandlerTest.java
...
Summary of conflicts:
  Text conflicts: 2
```

最后，svn会给出冲突信息（如果有的话），这时，我们来决定是否合并，以及合并哪些修订号区间的修改。如果预览之后觉得可以直接合并，则可以直接运行：

```sh
$ svn merge -r231610:HEAD /path/trunk
```

过程中，遇到冲突的情况，svn会询问采取哪种方式来处理

```sh
Select: (p) postpone, (df) diff-full, (e) edit,
        (mc) mine-conflict, (tc) theirs-conflict,
        (s) show all options: p
```

如果拿不准，可以使用`p`子命令，然后等到最后在IDE或者编辑器中合并，如果想要丢弃自己的修改，使用`tc`子命令；如果要丢弃别人的修改，使用`mc`子命令。

最后，在编辑器中修改完了这些冲突之后，使用:

```sh
$ svn resolved pom.xml
Resolved conflicted state of 'pom.xml'
```

来标记该冲突已经被解决。最后，运行测试并提交本次修改：

```sh
$ mvn clean test
$ svn ci -m "Merge branch b with trunk"
```

