---
layout: post
title: "一个简单的午餐推荐脚本"
date: 2014-09-18 21:55
comments: true
categories: 
- Ruby
- Apple Script

---

### 千古谜题 --- 中午吃啥？

如果要列出一些日常最频繁的会问/被问的问题的一个列表，***吃啥？***绝对会排在前三位，对于程序员来说，一样频繁的还有诸如***这是谁写的？***，***这尼玛啥意思啊？***之类。

**吃啥**作为一个每天都会面对的问题，我们自然而言会想很多办法，比如随大流，其他人去哪儿我们跟着就行，但是这种方法最大的问题是：大部分人其实都没有很好的想法，大家都很迷茫。作为程序员，一个非常直观的想法就是找出一个列表，然后随机/伪随机的从这个列表中拿出一条来作为推荐。

#### 基本思路

一个基本的思路是这样的，或者说，要开发的软件应该满足这几个基本的需求

1.	维护一个饭店/饭菜的列表
2.	随机的从这个列表中取出一项
3.	每天定时的触发，比如**11:30**准时提醒
4.	这个工具最终要以弹出窗口等方式来提醒

饭店/饭菜的列表比较容易，比如一个静态的JSON文件：

```js
[
    {
        "name": "关中客大碗面"
    },
    {
        "name": "王华峰肉夹馍"
    },
    {
        "name": "傻得帽冒菜"
    },
    {
        "name": "蒸饺"
    },
    {
        "name": "樊家肉夹馍"
    },
    {
        "name": "马奴哈羊肉泡馍"
    },
    {
        "name": "子午路张记肉夹馍"
    },
    {
        "name": "东滩水盆"
    }
]

```

然后我们需要一个小程序来读取这段JSON，并已随机/伪随机的方式返回一个推荐：

```ruby
# encoding: UTF-8
require 'json'

def first
    JSON.parse(File.open("food.json").read).shuffle[0]["name"]
end

puts "今天去吃#{first}吧?"

```

测试一下，将上边这个ruby程序运行几次，可以得到一下结果：

```sh
$ ruby lunch.rb 
今天去吃东滩水盆吧?

$ ruby lunch.rb
今天去吃子午路张记肉夹馍吧?

$ ruby lunch.rb
今天去吃傻得帽冒菜吧?

$ ruby lunch.rb
今天去吃马奴哈羊肉泡馍吧?
```

效果不错，最起码它可以在控制台上打印比较随机的一个推荐了。

#### 界面

最开始界面当然会考虑用诸如Sinatra做一个Web页面，然后吃饭前大家派代表去摇一下，然后听天由命。但是这样的弊端是不直观，用户需要打开该网站，然后主动的获取信息。

我们更想要的是**推送**的方式来获得这个信息，经过简单的测试，发现Mac系统自带的`osascript`比较适合，这个工具可以执行苹果的脚本语言[AppleScript](https://developer.apple.com/library/mac/documentation/AppleScript/Conceptual/AppleScriptX/AppleScriptX.html)，当然还可以执行[OSA](https://developer.apple.com/library/mac/documentation/applescript/conceptual/applescriptx/concepts/osa.html)，不过这篇的重点并不是这个，我们可以在另一篇文件中讨论这个主题。

比如一个很简单的`osascript`脚本是这样的：

```applescript
display notification "Hello, world"
```

在命令行输入：

```sh
$ osascript hello.osa
```

来执行这个脚本，这时你会看到一个弹出窗口：

![image](/images/2014/09/hello-osa-resized.png)

可以通过指定title来设置弹出窗口的标题：

```applescript
display notification "Hello, world" with title "This is Title"
```

![image](/images/2014/09/hello-osa-with-title-resized.png)

这样我们的实现就比较容易了，一个最简单的版本如下：

```sh
#!/bin/bash

chisha=`ruby lunch.rb`
osascript -e "display notification \"${chisha}\" with title \"Chisha?\""
```

首先执行`ruby lunch.rb`得到一个推荐的饭店，然后将这个饭店名称传入osascript来生成通知：

![image](/images/2014/09/chisha-resized.png)

#### 定时任务

有了这个脚本，我们可以很容易的使用`crontab`将其作为定时任务，比如将上述的脚本保存为`lunch.sh`，然后定义一个`crontab`脚本：

```sh
$ crontab -l
30 11 * * 1-5 /Users/jtqiu/develop/ruby/chisha/lunch.sh
```

这个脚本会在每周的周一到周五的中午11点30分执行一次，对于[crontab的语法](http://en.wikipedia.org/wiki/Cron)请参考此处。

一个直观的图示如下：

![image](/images/2014/09/crontab-syntax.gif) 

图片来源(http://www.webenabled.com/sites/default/files/crontab-syntax.gif)

对应的[代码都放在Github上](https://github.com/abruzzi/chisha)，而且这个README是我目前写的最详细的一个，:)。
