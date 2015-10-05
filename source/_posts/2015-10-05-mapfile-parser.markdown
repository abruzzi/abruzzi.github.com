---
layout: post
title: "工程中的编译原理 -- Mapfile解析器"
date: 2015-10-05 12:59
comments: true
categories: 
- Language
- JavaScript
---
### 前言

Mapfile是`MapServer`用来描述一个地图的配置文件。它是一个很简单的`声明式`语言，一个地图（Map）可以有多个层（Layer），每个层可以有很多属性（键值对）。在一个层的定义中，还可以定义若干个类（Class），这个类用以管理不同的样式（Style）。而每个类或者样式都可以由若干个属性（键值对）。

这里有一个实际的例子：

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

#### 最简单的层的定义

最简单的情形是，我们定义了一个层`Layer`，但是没有指定任何的属性：

```
LAYER
END
```

我们期望parser可以输出：

```js
{layer: null}
```

要做到这一步，首先需要定义符号`LAYER`和`END`，以及一些对空格，非法字符的处理等：

```js
\s+                     /* skip whitespace */
\n|\r\n                 /* skip whitespace */
"LAYER"                 return "LAYER"
"END"                   return "END"
<<EOF>>                 return 'EOF'
.                       return 'INVALID'
```

对于，空格，回车换行等，我们都直接跳过。对应的`BNF`也非常简单：

```js
expressions
    : decls EOF {return $1;}
    ;

decls
    : LAYER END {$$ = {layer: null}}
    ;
```

#### 为层添加属性


接下来我们来为层添加`Name`属性，首先还是添加符号`NAME`和对字符串的定义。这里的字符串被定义为：由双引号括起来的所有内容。

```js
"NAME"                  return "NAME"
'"'("\\"["]|[^"])*'"'   return 'STRING'
[a-zA-Z]+               return 'WORD'
```

然后我们就可以为`BNF`添加一个新的节：

```js
decls:
  LAYER decl END
  {$$ = {layer: $2}}
  ;

decl:
  NAME STRING
  {$$ = $2.substring(1, $2.length - 1)};
```

在`decl`中，我们将获得的字符串两头的引号去掉`$2.substring`。这样`decl`的值就会是字符串本身，而不是带着双引号的字符串了。修改之后的代码可以解析诸如这样的声明：

```
LAYER
	NAME "counties"
END
```

并产生这样的输出：

```js
{ layer: 'counties' }
```

但是如果我们用来解析两个以上的属性：

```js
LAYER
  NAME         "counties"
  DATA         "counties-in-shaanxi-3857"
END
```

解析器会报告一个错误：

```sh
$ node map.js expr

/Users/jtqiu/develop/ideas/jison-demo/mapfile/map.js:106
        throw new Error(str);
              ^
Error: Parse error on line 2:
...       "counties"  DATA         "counti
----------------------^
Expecting 'END', got 'WORD'
    at Object.parseError (/Users/jtqiu/develop/ideas/jison-demo/mapfile/map.js:106:15)
    at Object.parse (/Users/jtqiu/develop/ideas/jison-demo/mapfile/map.js:171:22)
    at Object.commonjsMain [as main] (/Users/jtqiu/develop/ideas/jison-demo/mapfile/map.js:620:27)
    at Object.<anonymous> (/Users/jtqiu/develop/ideas/jison-demo/mapfile/map.js:623:11)
    at Module._compile (module.js:456:26)
    at Object.Module._extensions..js (module.js:474:10)
    at Module.load (module.js:356:32)
    at Function.Module._load (module.js:312:12)
    at Function.Module.runMain (module.js:497:10)
    at startup (node.js:119:16)
```

即，期望一个`END`符号，但是却看到了一个`WORD`符号。我们只需要稍事修改，就可以让当前的语法支持多个属性的定义：

```js
decls:
  LAYER pairs END
  {$$ = {layer: $2}}
  ;

pairs:
  pair
  {$$ = $1}
  |
  pairs pair
  {$$ = merge($1, $2)}
  ;

pair:
  NAME STRING
  {$$ = {name: $2.substring(1, $2.length - 1)}}
  | DATA STRING
  {$$ = {data: $2.substring(1, $2.length - 1)}};
```

先看，`pair`的定义，它由`NAME STRING`或者`DATA STRING`组成，是我们语法中的终结符。再来看`pairs`的定义：

```js
pairs: pair | pairs pair;
```

这个递归的定义可以保证我们可以写一条`pair`或者多条`pairs pair`属性定义语句。而对于多条的情况，我们需要将这行属性`规约`在一起，即当遇到这样的情形时：

```
NAME         "counties"
DATA         "counties-in-shaanxi-3857"
```

我们需要产生这样的输出：`{name: "counties", data: "counties-in-shaanxi-3857"}`。但是由于符号是逐个匹配的，我们会得到这样的匹配结果：`{name: "counties"}`和`{data: "counties-in-shaanxi-3857"}`，因此我们需要编写一个简单的函数来合并这些属性：

```js
  function merge(o1, o2) {
    var obj = {};

    for(var k in o1) {
      obj[k] = o1[k];
    }
    for(var v in o2) {
      obj[v] = o2[v];
    }

    return obj;
  }
```

按照惯例，这种自定义的函数需要被定义在`%{`和`}%`括起来的`section`中：

```js
...
[a-zA-Z]+               return 'WORD'
[0-9]+("."[0-9]+)?      return 'NUMBER'
<<EOF>>                 return 'EOF'
.                       return 'INVALID'

/lex

%{
  function merge(o1, o2) {
    var obj = {};

    for(var k in o1) {
      obj[k] = o1[k];
    }
    for(var v in o2) {
      obj[v] = o2[v];
    }

    return obj;
  }
%}

%start expressions

%% /* language grammar */
...

```

现在我们的解析器就可以识别多条属性定义了：

```sh
$ node map.js expr
{ layer: { name: 'counties', data: 'counties-in-shaanxi-3857' } }
```

#### 嵌套的结构

现在新的问题又来了，我们的解析器现在可以识别对层的对个属性的解析了，不过由于`CLASS`并不是由简单的键值对定义的，所以还需要进一步的修改：

```js
classes:
  CLASS pairs END
  {$$ = {class: $2}}
  ;
```

类由`CLASS`关键字和`END`关键字定义，而类的属性定义和`Layer`的属性定义并无二致，都可以使用`pairs`（多条属性）。而`classes`事实上是`pair`的另一种形式，就像对属性的定义一样，所以：

```js
pair:
  NAME STRING
  {$$ = {name: $2.substring(1, $2.length - 1)}}
  | DATA STRING
  {$$ = {data: $2.substring(1, $2.length - 1)}}
  | classes
  {$$ = $1};
```

这样，解析器就可以识别`CLASS`子句了。我们注意到，在`CLASS`中，还可以定义`STYLE`，因此又需要稍作扩展：

```js
pair:
  NAME STRING
  {$$ = {name: $2.substring(1, $2.length - 1)}}
  | DATA STRING
  {$$ = {data: $2.substring(1, $2.length - 1)}}
  | classes
  {$$ = $1}
  | styles
  {$$ = $1};

styles:
  STYLE pairs END
  {$$ = {style: $2}}
  ;
```

这样，我们的解析器就可以处理样例中的所有语法了：

```sh
node map.js expr
{ layer: 
   { name: 'counties',
     data: 'counties-in-shaanxi-3857',
     status: 'default',
     type: 70,
     class: { name: 'polygon', style: [Object] } } }
```

完整的代码在github上的[这个repo中](https://github.com/abruzzi/jison-demos)。

### 总结

使用`BNF`定义一个复杂配置文件的规则，事实上一个比较容易的工作。要手写这样一个解析器需要花费很多的时间，而且当你需要parser多种配置文件时，这将是一个非常无聊且痛苦的事情。学习`jison`可以帮助你很快的编写出小巧的解析器，在上面的`Mapfile`的例子中，所有的代码还不到`100`行。下一次再遇到诸如复杂的文本解析，配置文件读取的时候，先不要忙着编写`正则表达式`，试试更高效，更轻便的`jison`吧。