---
layout: post
title: "在Mac下搭建Common Lisp开发环境(Emacs)"
date: 2013-06-03 16:22
comments: true
categories: 

---

####Lisp编译器（解释器）

首先需要一个Lisp的编译器，[SBCL](http://www.sbcl.org/platform-table.html)是一个开源的实现，支持所有POSIX平台。你可以选择从源码编译，也可以下载二进制包。而由于使用mac，可以用强大的homebrew来安装：

```
$ brew install sbcl
```

#####简单使用

使用`sbcl`启动交互环境，如果用lisp的术语来说，这是一个REPL(read–eval–print loop )。这个环境中就可以尝试Common Lisp编程了。

```
$ sbcl

This is SBCL 1.1.7.0-aeb9307, an implementation of ANSI Common Lisp.
More information about SBCL is available at <http://www.sbcl.org/>.

SBCL is free software, provided as is, with absolutely no warranty.
It is mostly in the public domain; some portions are provided under
BSD-style licenses.  See the CREDITS and COPYING files in the
distribution for more information.

* (+ 1 2 3 4 5 6)
**21**

* (quit)

$
```

但是这个环境对开发者不是非常友好，比如不支持上下键导航，不支持左右键，非常原始，可以使用Emacs来作为开发环境，当然如果你更喜欢vim（像我一样），也没有任何问题。不过这是一个很好的学习Emacs编辑环境的机会，可以尝试一下。

####Emacs + Slime

[Slime](http://common-lisp.net/project/slime/)是一个Emacs下开发Common Lisp程序的一个插件，它本身就是由lisp写成的，下载之后是一个压缩包，将其解压缩到`~/.eamcs.d/`目录中即可。
然后在`~/.emacs`文件中添加下面的配置：

```
; slime setup
(setq inferior-lisp-program "/usr/local/bin/sbcl")
(add-to-list 'load-path "~/.emacs.d/slime/")
(require 'slime)
(slime-setup)
```

#####Emacs的“开发者”配置

默认的eamcs界面比较简陋，我的vim使用的solarized主题，觉得配色非常合理，结果在github上发现了其对应的[emacs主题](https://github.com/sellout/emacs-color-theme-solarized)。现在之后，同样解压在`~/.emacs.d/`目录中，然后在`~/.emacs`加上一下配置即可。

```
; color theme setup 
(add-to-list 'custom-theme-load-path "~/.emacs.d/emacs-color-theme-solarized/")
(load-theme 'solarized-dark t)

; hide the tool bar
(tool-bar-mode -1)

; set the font
(set-face-attribute 'default nil :font "Monaco")
(set-face-attribute 'default nil :height 170)

```

####效果图

![image](http://abruzzi.github.com/images/2013/06/emacs.resized.png)