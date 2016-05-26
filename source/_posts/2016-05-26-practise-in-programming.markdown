---
layout: post
title: "无他，但手熟尔"
date: 2016-05-26 22:56
comments: true
categories: 
- ThoughtWorks
- Methodology
- Fun
---

## 高效幻象

通过对自己的行为观察，我发现在很多时候，我以为我掌握了的知识和技能其实并不牢靠。我引以为豪的`高效`其实犹如一个彩色的肥皂泡，轻轻一碰就会破碎，散落一地。

### 你可能只是精通搜索

我们现在所处的时代，信息爆炸，每个人每天都会接触，阅读很多的信息，快速消费，快速遗忘。那种每天早上起来如同皇帝批阅奏折的、虚假的误以为掌握知识的错觉，驱动我们进入一个恶性循环。

即使在我们真的打算解决问题，进行主动学习时，更多的也只是在熟练使用搜索引擎而已（在一个领域待久了，你所使用的关键字准确度自然要比新人高一些，仅此而已）。精通了高效率搜索之后，你会产生一种你`精通搜索到的知识本身`的**错觉**。

![stack overflow](/images/2016/05/stackoverflow-oreilly.png)

#### 如何写一个Shell脚本

在写博客的时候，我通常会在文章中配图。图片一般会放在一个有固定格式的目录中，比如现在是2016年5月，我本地就会有一个名为`$BLOG_HOME/images/2016/05`的目录。由于使用的是`markdown`，在插入图片时我就不得不输入完整的图片路径，如：`/images/2016/05/stack-overflow.png`。但是我又不太记得路径中的`images`是单数(`image`)还是复数(`images`)，而且图片格式又可能是`jpg`,`jpeg`,`gif`或者`png`，我也经常会搞错，这会导致图片无法正确显示。另外，放入该目录的原始文件尺寸有可能比较大，我通常需要将其缩放成800像素宽（长度无所谓，因为文章总是要从上往下阅读）。

为了自动化这个步骤，我写了一个小的Shell脚本。当你输入一个文件名如：`stack-overflow.png`后，它会缩放这个文件到800像素宽，结果是一个新的图片文件，命名为`stack-overflow-resized.png`，另外它将符合`markdown`语法的文件路径拷贝到剪贴板里：`/images/2016/05/stack-overflow-resized.png`，这样我在文章正文中只需要用`Command+V`粘贴就可以了。

有了思路，写起来就很容易了。缩放图片的命令我是知道的：

```sh
$ convert -resize 800 stack-overflow.png stack-overflow-resized.png
```

但是要在文件明上加入`-resized`，需要分割文件名和文件扩展名，在`Bash`里如何做到这一点呢？Google一下：

```sh
FULLFILE=$1

FILENAME=$(basename "$FULLFILE")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

convert -resize 800 $FULLFILE $FILENAME-resized.EXTENSION
```

难看是有点难看，不过还是可以工作的。接下来是按照当前日期生成完整路径，`date`命令我是知道的，而且我知道它的`format`格式很复杂，而且跟`JavaScript`里Date对象的`format`又不太一样（事实上，世界上有多少种日期工具，基本上就有多少种格式）。再Google一下：

```sh
$ date +"/images/%Y/%m/"
```

最后一步将路径拷贝到剪贴板也容易，Mac下的`pbcopy`我也会用：`echo`一下字符串变量，再管道到`pbcopy`即可：

```sh
PREFIX=`date +"/images/%Y/%m/"`
echo "$PREFIX$FILENAME-resized.EXTENSION" | pbcopy
```

但是将内容粘贴到`markdown`里之后，我发现这个脚本多了一个换行。我想这个应该是`echo`自己的行为吧，会给字符串自动加上一个换行符。Google一下，发现加上`-n`参数就可以解决这个问题。

好了，完整的脚本写好了：

```sh
#!/bin/bash
FULLFILE=$1

FILENAME=$(basename "$FULLFILE")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"

convert -resize 800 $FULLFILE $FILENAME-resized.EXTENSION

PREFIX=`date +"/images/%Y/%m/"`
echo -n "$PREFIX$FILENAME-resized.EXTENSION" | pbcopy
```

嗯，还不错，整个过程中就用了我十几分钟时间而已，以后我在写博客时插入图片就方便多了！

不过等等，好像有点不对劲儿，我回过头来看了看这段脚本：7行代码只有1行是我独立写的！没有`Google`的话，查看`man date`和`man echo`也可以解决其中一部分问题，不过文件扩展名部分估计又得花较长时间。

仔细分析一下，之前的成就感荡然无存。

#### 更多的例子

我相信，过几周我再来写这样一个简单的脚本时，上面那一幕还是会出现。开发者的IDE的外延已经将`Google`和`Stack Overflow`集成了。很难想象没有这两个IDE的`插件`我要怎样工作。

其实除此之外，日常工作中这样的事情每时每刻都在发生：

1.  Ansible里如何创建一个给用户`robot`读写权限的目录？
1.  Python 3中启动简单HTTPServer的命令是？
1.  Spring Boot的Gradle String是？
1.  Mongodb中如何为用户`robot`授权？
1.  Gulp里一个Task依赖另一个Task怎么写？

等等等等，这个列表可以根据你的技术栈，偏向前端/后端的不同而不同，但是相同的是在`Google`和`Stack Overflow`上搜索，阅读会浪费很多时间，而这些本来都是可以避免的。

### 肌肉记忆

大脑在对信息存储上有很高级的设计，如果某件事情不值得记忆，大脑会自动过滤掉（比如我们很容易获得的搜索结果）。而对于那些频繁发生，计算结果又不会变化的信息，大脑会将其下放到“更低级别”的神经去记忆。比如各种运动中的肌肉记忆，习武之人梦寐以求的“拳拳服膺”，“不期然而然，莫知之而至”。

这里也有两个小例子：

#### 一个C语言的小程序

上周末我买了一个茶轴的机械键盘，打开包装之后我很兴奋，赶紧插在我的笔记本上，打开一个编辑器，心说敲一些代码体验一下。几秒钟后，我发现敲出来的是：

```c
# include <stdio.h>
# include <stdlib.h>

int main(int argc, char *argv[]) {
	if(argc != 3) {
		fprintf(stderr, "Usage: %s ip port\n", argv[0]);
		return -1;
	}

	fprintf(stdout, "Connecting to %s %d\n", argv[1], atoi(argv[2]));

	return 0;
}
```

然后在命令行里

```sh
$ gcc -o hello hello.c
$ ./hello
Usage: ./hello ip port

$ ./hello 10.180.1.1 9999
Connecting to 10.180.1.1 9999
```

整个过程极为流畅，上一次开发C代码已经是4年多前了。也就是说，我的手指已经记下了所有的这些命令：

1.  Linux下`main`函数的convention
1.  `fprintf`的签名
1.  `stderr/stdout`用法的区分
1.  `main`函数不同场景的返回值
1.  `gcc`命令的用法


另外一个小例子是`vim`编辑器。我使用`vim`已经有很多年了，现在在任何一个Linux服务器上，编辑那些`/etc/nginx/nginx.conf`之类的配置文件时，手指就会`自动`的找到快捷键，`自动`的完成搜索，替换，跳转等等操作。


### 刻意练习

对比这两个例子，一方面我惊讶于自己目前对搜索引擎、`Stack Overflow`的依赖；一方面惊讶于`肌肉记忆力`的深远和神奇。结合一下两者，我发现自己的开发效率有望得到很大的提升。

比如上面列出的那些略显尴尬的问题，如果我的手指可以`自动`的敲出这些答案，那么节省下的搜索、等待、阅读的时间就可以用来干别的事情，比如跑步啊，骑车啊，去驾校学车被教练骂啊等等，总之，去过自己的生活。

这方面的书籍，博客都已经有很多，比如我们在ThoughtWorks University里实践的`Code Kata`，`JavaScript Dojo`，`TDD Dojo`之类，都已经证明其有效性。

如果你打算做一些相关的练习，从`Kata`开始是一个不错的选择。每个`Kata`都包含一个简单的编程问题，你需要不断的去练习它（同一个题目做20遍，50遍等）。前几次你是在解决问题本身，慢慢就会变成在审视自己的编程习惯，发现并改进（比如快捷键的使用，语法的熟悉程度等等），这样在实际工作中你会以外的发现自己的速度变快了，而且对于重构的信心会变大很多。其实道理也很简单：如果你总是赶着deadline来完成任务，怎么会有时间来做优化呢？


这里有一些参考资料和`Kata`的题目，可供参考：

-  [Practicing Programming](https://sites.google.com/site/steveyegge2/practicing-programming)
-  [The Ultimate Code Kata](https://blog.codinghorror.com/the-ultimate-code-kata/)
-  [一些Kata的题目](http://codekata.com/)
