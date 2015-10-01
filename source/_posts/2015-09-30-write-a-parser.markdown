---
layout: post
title: "徒手编写解释器 -- JavaScript版本"
date: 2015-09-30 18:45
comments: true
categories: 
- JavaScript
- Language
---

### 前言

在代码编写中，很多时候我们都会处理字符串：发现字符串中的某些规律，然后将想要的部分抽取出来。对于发杂一些的场景，我们会使用`正则表达式`来帮忙，正则表达式强大而灵活，主流的变成语言如`Java`，`Ruby`的标准库中都对其由很好的支持。

但是有时候，当接收到的字符串结构更加复杂（往往会这样）的时候，正则表达式要么会变的不够用，要么变得超出我们能理解的复杂度。这时候，我们可能借助一些更为强大的工具。

下面是一个实际的例子，这个代码片段是MapServer的配置文件，它用来描述地图中的一个层，其中包含了嵌套的`CLASS`，而`CLASS`自身又包含了一个嵌套的`STYLE`节。显然，正则表达式在解释这样复杂的结构化数据方面，是无法满足需求的。

```
LAYER
  NAME         "counties"
  DATA         "counties-in-shaanxi-3857"
  STATUS       default
  TYPE         POLYGON
  TRANSPARENCY 70

  CLASS
    NAME       "polygon"
    STYLE
      COLOR     255 255 255
      OUTLINECOLOR 40 44 52
    END
  END
END
```

在UNIX世界，很早的时候，人们就开发出了很多用来生成`解释器`(parser)的工具，比如早期的[lex](https://en.wikipedia.org/wiki/Lex_(software))/[yacc](https://en.wikipedia.org/wiki/Yacc)之类的工具和后来的[bison](https://en.wikipedia.org/wiki/GNU_bison)。通过这些工具，程序员只需要定义一个结构化的文法，工具就可以自动生成解释器的C代码，非常容易。在JavaScript世界中，有一个非常类似的工具，叫做[jison](https://zaach.github.io/jison/)。在本文中，我将以jison为例，说明在JavaScript中自定义一个解释器是何等的方便。

**注意**，我们这里说的`解释器`不是一个编译器，编译器有非常复杂的后端（抽象语法树的生成，虚拟机器指令，或者机器码的生成等等），我们这里仅仅讨论一个编译器的**前端**。

### 一点理论知识

本文稍微需要一点理论知识，当年编译原理课的时候，各种名词诸如`规约`，`推导式`，`终结符`，`非终结符`等等，

#### 上下文无关文法（Context Free Grammar）

先看看维基上的这段定义：

>在计算机科学中，若一个形式文法 G = (N, Σ, P, S) 的产生式规则都取如下的形式：V -> w，则称之为上下文无关文法（英语：context-free grammar，缩写为CFG），其中 V∈N ，w∈(N∪Σ)* 。上下文无关文法取名为“上下文无关”的原因就是因为字符 V 总可以被字串 w 自由替换，而无需考虑字符 V 出现的上下文。

基本上跟没说一样。要定义一个上下文无关文法，数学上的精确定义是一个在4元组：`G = (N, Σ, P, S)`，其中

1.	N是“非终结符”的集合
2.	Σ是“终结符”的集合，与N的交集为空（不想交）
3.	P表示规则集（即N中的一些元素以何种方式）
4.	S表示起始变量，是一个“非终结符”

其中，规则集P是重中之重，我们会在下一小节解释。经过这个形式化的解释，基本还是等于没说，在继续之前，我们先来看一下BNF，然后结合一个例子来帮助理解。

话说我上一次写这种[学院派的文章](http://www.cnblogs.com/abruzzi/archive/2009/06/06/1497449.html)还是2009年，时光飞逝。

#### 巴科斯范式（Backus Normal Form）

维基上的解释是：

>巴科斯范式（英语：Backus Normal Form，缩写为 BNF），又称为巴科斯-诺尔范式（英语：Backus-Naur Form，也译为巴科斯-瑙尔范式、巴克斯-诺尔范式），是一种用于表示上下文无关文法的语言，上下文无关文法描述了一类形式语言。它是由约翰·巴科斯（John Backus）和彼得·诺尔（Peter Naur）首先引入的用来描述计算机语言语法的符号集。

简而言之，它是由推导公式的集合组成，比如下面这组公式：

```
S -> T + T | T - T | T
T -> F * F | F / F | F
F -> NUMBER | '(' S ')'
NUMBER ->  0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

可以被“继续分解”的元素，我们称之为“非终结符”，如上式中的`S`, `T`, `NUMBER`，而无法再细分的如`0..9`，`(`，`)`则被称之为终结符。`|`表示或的关系。在上面的公式集合中，`S`可以被其右边的`T+T`替换，也可以被`T-T`替换，还可以被`T`本身替换。回到上一小节最后留的悬疑，在这里：

1.	N就是{`S`, `T`, `F`, `NUMBER`}
2.	Σ就是{`0`, `1`, ..., `9`, `(`, `)`, `+`, `-`, `*`, `/`}
3.	P就是上面的BNF式子
4.	S就是这个的`S`(第一个等式的左边状态)

上面的BNF其实就是四则运算的形式定义了，也就是说，由这个BNF可以解释一切出现在四则运算中的文法，比如：

```
1+1
8*2+3
(10-6)*4/2
```

而所谓上下文无关，指的是在推导式的左边，都是非终结符，并且可以**无条件**的被其右边的式子替换。此处的**无条件**就是上下文无关。

### 实现一个四则运算计算器

我们这里要使用[jison](https://zaach.github.io/jison/)，jison是一个npm包，所以安装非常容易：

```sh
npm install -g jison
```

安装之后，你本地就会有一个命令行工具`jison`，这个工具可以将你定义的`jison`文件编译成一个`.js`文件，这个文件就是解释器的源码。我们先来定义一些`符号`(token)，所谓`token`就是上述的`终结符`：

#### 第一步：识别数字

创建一个新的文本文件，假设就叫`calc.jison`，在其中定义一段这样的符号表:

```js
\s+                   /* skip whitespace */
[0-9]+("."[0-9]+)?    return 'NUMBER'
<<EOF>>               return 'EOF'
.                     return 'INVALID'
```

这里我们定义了4个符号，所有的空格（`\s+`），我们都跳过；如果遇到数字，则返回`NUMBER`；如果遇到文件结束，则返回`EOF`；其他的任意字符(.)都返回`INVALID`。

定义好符号之后，我们就可以编写`BNF`了：

```js
expressions
    : NUMBER EOF
        {
        console.log($1);
        return $1;
        }
    ;
```

这里我们定义了一条规则，即`expressions -> NUMBER EOF`。在`jison`中，当匹配到规则之后，可以执行一个代码块，比如此处的输出语句`console.log($1)`。这个产生式的右侧有几个元素，就可以用`$加序号`来引用，如`$1`表示`NUMBER`实际对应的值，`$2`为`EOF`。

通过命令

```sh
jison calc.jison
```

可以在当前目录下生成一个`calc.js`文件，现在来创建一个文件`expr`，文件内容为一个数字，然后执行：

```sh
node calc.js expr
```

来测试我们的解释器：

```sh
$ echo "3.14" > expr
$ node calc.js expr
3.14
```

目前我们完整的代码仅仅20行：

```js
/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
[0-9]+("."[0-9]+)?    return 'NUMBER'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

%start expressions

%% /* language grammar */

expressions
    : NUMBER EOF
        {
        console.log($1);
        return $1;
        }
    ;

```

#### 加法

我们的解析器现在只能计算一个数字（输入给定的数字，给出同样的输出），我们来为它添加一条新的规则:加法。首先我们来扩展目前的BNF，添加一条新的规则：

```js
expressions
    : statement EOF
        {
        console.log($1);
        return $1;
        }
    ;

statement:
  NUMBER PLUS NUMBER
  {$$ = $1 + $3}
  |
  NUMBER
  {$$ = $1}
  ;
```

即，`expressions`由`statement`组成，而`statement`可以有两个规则规约得到，一个就是纯数字，另一个是`数字 加号 数字`，这里的`PLUS`是我们定义的一个新的符号：

```js
"+"    return "PLUS"
```

当输入匹配到规则`数字 加号 数字`时，对应的块`{$$ = $1 + $3}`会被执行，也就是说，两个`NUMBER`对应的值会加在一起，然后赋值给整个表达式的值，这样就完成了**语义**的翻译。

我们在文件`expr`中写入算式：`3.14+1`，然后测试：

```sh
$ jison calc.jison
$ node calc.js expr
13.14
```

嗯，结果有点不对劲，两个数字都被当成了字符串而拼接在一起了，这是因为JavaScript中，`+`的二义性和弱类型的自动转换导致的，我们需要做一点修改：

```js
statement:
  NUMBER PLUS NUMBER
  {$$ = parseFloat($1) + parseFloat($3)}
  |
  NUMBER
  {$$ = $1}
  ;
```

我们使用JavaScript内置的`parseFloat`将字符串转换为数字类型，再做加法即可：

```sh
$ jison calc.jison
$ node calc.js expr
4.140000000000001
```

#### 更多的规则

剩下的事情基本就是把BNF翻译成`jison`的语法了：

```
S -> T + T | T - T | T
T -> F * F | F / F | F
F -> NUMBER | '(' S ')'
NUMBER ->  0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

```js
expressions
    : statement EOF
        {
        console.log($1);
        return $1;
        }
    ;

statement:
  term PLUS term {$$ = $1 + $3}
  |
  term MINUS term {$$ = $1 - $3}
  |
  term {$$ = $1}
  ;

term:
  factor MULTIPLE factor {$$ = $1 * $3}
  |
  factor DIVIDE factor {$$ = $1 / $3}
  |
  factor {$$ = $1}
  ;

factor:
  NUMBER {$$ = parseFloat($1)}
  |
  LP statement RP {$$ = $2}
  ;

```

这样，像复杂一些的四则运算：`(10-2) * 3 + 2/4`，我们的计算器也已经有能力来计算出结果了：

```sh
$ jison calc.jison
$ node calc.js expr
24.5
```

### 总结

我们在本文中讨论了BNF和上下文无关文法，以及这些理论如何与工程实践联系起来。这里的`四则运算计算器`当然是一个很简单的例子，不过我们从中可以看到将`BNF`形式文法翻译成实际可以工作的代码是多么方便。我在后续的文章中会介绍`jison`更高级的用法，以及如何在实际项目中使用`jison`产生的解释器。
