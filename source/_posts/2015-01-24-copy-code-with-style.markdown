---
layout: post
title: "高亮剪贴板里的代码片段"
date: 2015-01-24 00:17
comments: true
categories: 
- Presentation
- Tool
---

### 高亮剪贴板里的代码片段
我前几天在准备一个培训的slides的时候，想在Keynote中粘贴一段代码，默认的粘贴板中的内容并没有样式，粘进去之后就是纯文本，没有语法高亮不说，默认的，代码的字体会采用Keynote默认的字体，非常难看。

之前在Intellij中有个插件`'Copy' on steroids`，这个插件可以将Intellij的编辑器中的高亮过的文本拷贝到剪贴板，然后就可以在Keynote中使用了。

我就想能不能有对应的命令行工具，结果还真的找到一个，就叫`highlight`，[主页在这里](http://www.andre-simon.de/doku/highlight/en/highlight.php)。（这里略微吐槽一下，这个官方页面的风格以今天的眼光来看，无论是配色还是样式布局等，都非常难看，完全是10年前的风格，不过这个小工具确实很好用）。

#### 基本使用

在Mac下，安装非常简单：

```sh
$ brew install highlight
```

`highlight`支持很多格式，`HTML`，`RTF`甚至还有`LaTeX`。不过如果要在Keynote或者PowerPoint中使用，用`RTF`(Rich Text Format)就可以了。

选择要高亮的文件，比如`app.rb`

```rb
require 'sinatra'
require 'rack/contrib'
require 'active_record'
require 'json'

require './model/plants'

class FrontendApplication < Sinatra::Base
    get '/' do
        File.open('index.html').read
    end
end
```

然后使用命令：

```sh
$ highlight -O rtf app.rb | pbcopy
```

即可将高亮过的内容复制到剪切板中，然后只需要`CMD+V`就可以粘贴了：

![app.rb](/images/2015/01/ruby-highlight-resized.png)

如果要生成HTML格式，只需要指定:


```sh
$ highlight -O html app.rb > app.rb.html
```

#### 自定义语言（扩展）

如果遇到不支持的语言时，默认的`highlight`会报错，要查看所有支持的语言，可以使用

```sh
$ highlight -p
```

所有的`highlight`内置的语言高亮配置都存储在本地的一个目录中，比如在我的机器上，存储位置为`/usr/local/Cellar/highlight/3.18_1/share/highlight/langDefs/`。

还以Java为例，该目录下会有一个文件，名为`java.lang`，内容如下：

```
Description="Java"

Keywords={
  { Id=1,
    List={"abstract", "default", "if", "private", "this", "do", "implements",
"protected", "throw", "break", "import", "public", "throws", "else",
"instanceof", "return", "transient", "case", "extends", "try", "catch", "final",
"interface", "static", "finally", "strictfp", "volatile", "class", "native",
"super", "while", "const", "for", "new", "switch", "continue", "goto",
"package", "synchronized", "as", "in", "def", "property"}, },
  { Id=2,
    List={"boolean", "double", "byte", "int", "short", "void", "char", "long", "float"},
  },
 { Id=3,
    Regex=[[@\w+]],
  },
  { Id=4,
    Regex=[[(\w+)\s*\(]],
  },
}

Strings={
  Delimiter=[["|']],
  Escape = [[ \\u\d{4}|\\x?\d{3}|\\\w|\\[\'\\\"] ]]
}

IgnoreCase=false

Comments={
  { Block=false,
    Delimiter= { [[\/\/]] },
  },
  { Block=true,
    Nested=false,
    Delimiter= { [[\/\*]],[[\*\/]],}
  }
}

Operators=[[\(|\)|\[|\]|\{|\}|\,|\;|\.|\:|\&|<|>|\!|\=|\/|\*|\%|\+|\-|\|]]

EnableIndentation=true
```

基本上，这些配置都是自解释的，比如关键字列表的定义，字符串的正则pattern，是否区分大小写，注释的格式，操作符的格式，是否启用缩进等。

我在准备Slide的时候，想要加入一段`Cucumber`的feature文件，然后发现并不支持，于是就参照着Java的定义新建了一个文件：

```
Description="Gherkin"

Keywords={
  { Id=1,
    List={"Feature", "Scenario", "Given", "When", "Then", "And", "World", "Outline"},
  },
}

Strings={
  Delimiter=[["|']],
  Escape = [[ \\u\d{4}|\\x?\d{3}|\\\w|\\[\'\\\"] ]]
}

Comments={
  { Block=false,
    Delimiter= { [[#]] },
  },
}

IgnoreCase=false
```

将这个文件保存为`feature.lang`，这样我们就可以高亮下面这个`cucumber`的feature文件了（其实feature文件本身是有一个叫做Gherkin的语言编写的）

```gherkin
Feature:  Connected Home Purchase

	Scenario: Purchase T-Broadband
		Given I am purchasing "T-BROADBAND-50GB"
		When I go to checkout page
		And I am an existing telstra broadband customer
		When I select "Professional Installation" in Premium service and support
		# And I select "None" in Community Wifi
		And I select "None" in Optional extras
		Then I should see "Telstra Broadband 50GB" in my shopping cart
		And I should see "Professional Installation" in add on list
		And I should see the total price is "$72.00"

	Scenario: Purchase Entertainerment Bundle
		Given I am purchasing "Telstra Entertainer Supreme Bundle M"
		When I go to checkout page
		And I am an existing telstra broadband customer
		And I select "Foxtel iQ3 ($125 one-off)" in Inclusions
		And I select "Professional Installation" in Premium service and support
		# And I select "None" in Community Wifi
		And I select "None" in Optional extras
		Then I should see "Telstra Entertainer Supreme Bundle Entertainment M" in my shopping cart
		And I should see "Professional Installation" in add on list
		And I should see the total price is "$120.00"

```

![cucumber feature](/images/2015/01/feature-highlight-resized.png)

如果你经常写代码，喜欢分享自己学到的，并且喜欢以简短的代码来举例子，那么这个工具非常适合你。