---
layout: post
title: "Install powerline (fancy status line) for vim in Mac OS"
date: 2013-02-19 10:53
comments: true
categories: 
- vim
- opensource
- tools
tags: [vim, tolls, powerline]

---
###Powerline

[powerline](https://github.com/Lokaltog/powerline)会将vim的status line变的非常漂亮，看起来像一个“主流”的编辑器那样，而又不会引入额外的“重量”。基本原理是使用字体将特殊字符展现成特殊形状（如三角形），额外的有一些漂亮的配色。

####效果
![image](http://abruzzi.github.com/images/2013/02/vim-power-line-resized.png)

####安装
有几个额外的点需要确保：

#####保证你的vim包含了对python的支持
`vim --version | grep python`的结果应该包含`+python`，如：

```
+path_extra -perl +persistent_undo +postscript +printer -profile +python/dyn 
```
如果没有的话，需要将vim重新编译，比如在Mac OS下：

```
brew install macvim --env-std --override-system-vim
```

#####安装powerline
最简单的方式是直接clone到本地，比如：

```
git clone git://github.com/Lokaltog/powerline.git ~/PowerLine/
```

#####配置.vimrc
为你的vimrc添加下面的配置：

```
set rtp+={path_to_powerline}/powerline/bindings/vim
set laststatus=2
set noshowmode
```

这时，如果你启动vim，应该已经可以看到powerline了，但是有可能有“乱码”的问题，幸运的是，已经有很多的预定义字体。

###Fonts
[这里](https://github.com/Lokaltog/powerline-fonts)有许多额外的预定义fonts。选中需要的字体，安装到本地即可（双击字体文件或者拷贝到`~/Library/Fonts`下）。然后在.vimrc中使用这个字体，比如：

```
set encoding=utf-8
set guifont=Menlo\ for\ Powerline:h14
```