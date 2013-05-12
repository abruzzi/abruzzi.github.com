---
layout: post
title: "proc in ruby"
date: 2013-05-12 16:01
comments: true
categories: 
- ruby
- programming language
 
---
##block in ruby
block在ruby中，相当于JavaScript中的匿名函数，可以用来实现诸如高阶函数等。高阶函数最好用的一个特点就是它很好的将“动作”（action）本身抽象成了一个对象来传递。

block本身不是对象，但是可以被转换成Proc类的实例，然后以一种特别的方式执行。

```
 > proc = lambda {puts "hello, world"}
 => #<Proc:0x007ff11284d068@(irb):8 (lambda)> 
```

或者

```
> proc = lambda do
> 	puts "hello, world"
> end
```

从irb打印的信息可以看出，`<Proc:0x007ff11284d068@(irb):8 (lambda)>`是一个Proc类的实例用lambda生成的block对象，看起来像一个ruby中定义的函数/方法一样，但是执行的时候需要特别的调用方式：

```
> proc.call
hello, world
 => nil
```

如果需要参数，可以这样指定：

```
> proc = lambda {|a, b| a + b}
 => #<Proc:0x007ff114843d40@(irb):14 (lambda)> 
> proc.call(1,2)
 => 3 
> proc.call("hello, ","world")
 => "hello, world" 
```

##proc自身
ruby中大名鼎鼎的rack应用程序，本质上就只是负责调用一个block来获得结果：

```
rack_proc = lambda {|env| [200, {}, ["<h1>Hello, world</h1>"]]}
rack_proc.call({})
```

也可以使用proc来创建一个Proc：

```
> x = proc {puts "hello, world"}
 => #<Proc:0x007ff114851698@(irb):18> 
> x.call
hello, world
 => nil 
```

也可以将proc实例返回出来，然后提供给其他函数使用，需要注意的是那个call方法：

```
def adder(number)
	proc {|x| x + number}
end

add15 = adder(15)
add15.call(10) == 25

add10 = adder(10)
add10.call(10) == 20
```
