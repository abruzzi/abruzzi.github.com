---
layout: post
title: "Ruby元编程的一个示例：InactiveRecord"
date: 2013-12-15 15:18
comments: true
categories: 
- ruby
- meta programming
- language

---

#### 一个场景
元编程在所有的Lisp系语言中应该都是一个必备的feature，coommon lisp, scheme等包含该功能自然不在话下，而比较主流的编程语言如JavaScript，python之流，也或多或少的受到了lisp得影响，在面向对象的同时，也嵌入了一些元编程的特性。

而元编程在ruby中，虽然不如在lisp的宏那样灵活/强大，但是对于被“主流”编程语言影响很久的程序员 -- 如我，来说，已经非常震撼了。

很多ruby程序员都是通过rails才慢慢接触到ruby本身的，在rails中，ORM是通过强大到无穷大得[ActiveRecord](http://guides.rubyonrails.org/active_record_basics.html)来完成的。

一个简单的示例如：

```
class Person < ActiveRecord::Base
end
```
对应的，数据库中有一个Person的表：

```
CREATE TABLE person (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   age int,
   email varchar(255),
   PRIMARY KEY  (id)
);
```

这样，在使用模型Person的地方，可以很容易的编写这样的代码：

```
juntao = Person.new

juntao.name = 'juntao'
juntao.age = 28
juntao.email = 'juntao.qiu@gmail.com'

juntao.save
```

也就是说，开发者仅仅需要简单的创建一个与数据库同名的ruby类，然后这个类(Person)只需要继承自`ActiveRecord::Base`，那么它就自动的获得了很多的功能。这些神奇的功能就是通过ruby的元编程来完成的。


#### 一个ActiveRecord的拙劣模仿
我们在这里将编写一个简单的类`InactiveRecord`，当有其他类继承自此类时，会完成如`ActiveRecord`那样的功能，当然第一步我们并没有数据校验之类的功能，只是简单的将数据存储起来即可：

在person.rb文件中

```
class Person < InactiveRecord::Base
end
```

在address.rb中：

```
class Address < InactiveRecord::Base
end
```

而在使用他们的地方：


```
require './person'
require './address'

def test
    juntao = Person.new do |p| 
        p.name = 'Juntao'
        p.age = 28
        p.email = 'juntao.qiu@gmail.com'
    end 

    juntao.save

    nicholas = Person.new
    nicholas.name = 'Nicholas'
    nicholas.email = 'nicholas.ren@gmail.com'

    nicholas.save

    thougtworks = Address.new do |a| 
        a.street = 'Jinye 1st Rd'
        a.city = 'Xian'
        a.state = 'Shaanxi'
        a.country = 'China'
    end 

    thougtworks.save
end

test
```

预期的，test测试会打印出一下信息：

```
$ ruby main.rb 
{"name"=>"Juntao", "age"=>28, "email"=>"juntao.qiu@gmail.com"}
{"name"=>"Nicholas", "email"=>"nicholas.ren@gmail.com"}
{"street"=>"Jinye 1st Rd", "city"=>"Xian", "state"=>"Shaanxi", "country"=>"China"}
```

这里的save方法仅仅打印出当前对象上的属性即可。

#### InactiveRecord的实现
首先，对于最简单的case：

```
def test
    nicholas = Person.new
    nicholas.name = 'Nicholas'
    nicholas.email = 'nicholas.ren@gmail.com'

    nicholas.save
end
```

只需要动态的创建`name=`或者`email=`这样的方法即可，这里有个比较trick的地方是，`nicholas.name = 'Nicholas'`其实是在`nicholas`对象上调用了一个名叫`name=`的方法，ruby会将等号和对象间的空格去掉。

此时的实现非常简单，只需要在`method_missing`时，将调用时的key,value存在一个hash表中即可。这意味着，test中的那些*赋值*方法其实至始至终都并不存在，当ruby调用`name=`的时候，发现`nicholas`对象上并没有这个方法，然后ruby会沿着方法查找链向上追溯，直到顶级对象BasicObject时，还是没有发现，这时候，ruby会fallback到method_missing上，这个时刻，如果我们捕获这个调用，并完成对@attrs的赋值的话，那么这个方法事实上并不存在，但是又不会抛出异常。

当然在这个时刻，我们事实上可以为类动态的定义一些方法，由于这些方法不能通过常规方式看到(类定义中无法看到，而且在对象的methods列表中也无法看到)，因此它被称之为幽灵方法。

```
module InactiveRecord
    class Base
        def initialize(&block)
            @attrs = {}
        end 
            
        def method_missing(method, *args, &block)
           attr = method.to_s
           if attr =~ /=$/
               @attrs[attr.chop] = args[0]
           else
               @attrs[attr]
           end 
        end 

        def save
            p @attrs
        end 
    end 
end
```

更进一步，对于下边这种形式的创建方式：

```
juntao = Person.new do |p| 
	p.name = 'Juntao'
	p.age = 28
	p.email = 'juntao.qiu@gmail.com'
end 

juntao.save
```

则需要对`InactiveRecord::Base`中做一些修改：

```
def initialize(&block)
    @attrs = {}
    if block_given?
        if block.arity == 1
            yield self
        end
    end
end
```

如果调用者传递了一个block(可执行的单元)进来，那么使用`yield`将对象本身传递给该block。

#### 专业的spec

[同事任晓君](http://nicholasren.github.io/)是一个ruby专家，他为这个InactiveRecord设计了一个spec：

```
require 'spec_helper'

InactiveRecord::Base.config do |config|
  config.schemas "spec/fixtures/schema.yml"
end

class Person < InactiveRecord::Base
end

describe "InactiveRecord" do
  context "save attribtues" do
    subject {
      juntao = Person.new do |p|
        p.name = 'juntao'
        p.age = 28
        p.email = 'juntao.qiu@gmail.com'
      end
      juntao
    }

    it "should read saved attributes " do
      subject.name.should == 'juntao'
      subject.age.should == 28
      subject.email.should == "juntao.qiu@gmail.com"
    end
  end

  context "schema validation" do
    subject {
      juntao = Person.new do |p|
        p.name = 'juntao'
        p.age = 28
        p.email = 'juntao.qiu@gmail.com'
      end
      juntao
    }

    context "change a valid field" do
      it "should succeed" do
        subject.age = 29
        subject.age.should == 29
      end
    end

    context "change a invalid field" do
      it "should raise error" do
        expect { subject.weight= 60 }.to raise_error(StandardError)
      end
    end
  end
end
```

在`spec/fixtures/schema.yml`中，定义了Person的schema，`ActiveRecord`会从数据库中获得元数据，`InactiveRecord`在一点上大大的简化了：

```
---
Person:
  Name: String
  Age: Integer
  Email: String
```

预期的运行结果应当是：

![image](http://abruzzi.github.com/images/2013/12/rspec.png)

#### 基于这个spec的进一步实现

由于加入了对schema的校验，即，对于非法的赋值`juntao.weight=60`，InactiveRecord会报告一个异常，因为`weight`并不存在在schema中。

ruby在对象模型中提供了一些hook，当别的类包含一个模块，或者集成一个类时，这些hook会被触发，这个特性被很多ruby框架使用，从而实现很多有趣的代码风格。

由于所有的model都需要继承自`InactiveRecord::Base`，因此我们可以在该类上注册一个hook：

```
def inherited(who)
    table_name = who.name.downcase
    table = YAML.load_file("./metadata/#{table_name}.yml")
        
    who.class_eval do
        define_method :schema do
            table[who.name]
        end 
    end 
end
```

这样，对于每一个继承自`InactiveRecord::Base`的类，就动态的添加了一个方法，方法名为schema，这个方法可以获得类名对应的yml文件中定义的shema信息。此处的`define_method`动态的定义了一个新的方法，方法名为`schema`，后边的block中定义了方法体，在此处仅仅是返回从yml中读取的schema。

最后，在method_missing中，需要在赋值方法被调用时，查看该方法是否存在于schema中：

```
def method_missing(method, *args, &block)
   attr = method.to_s
   if @attrs.key?(attr)
       @attrs[attr]
   elsif attr =~ /=$/
       raise StandardError.new("invalid attribute") 
       unless valid?(attr.chop)
       @attrs[attr.chop] = args[0]
   else
       super.method_missing(method, args, &block)
   end
end

def valid? attr
    schema.keys.map{|key| key.downcase}.include? attr
end
```

如果schema中并不包含赋值字段：

```
person.style = "#004c97"
```

则会抛出一个错误退出:

```
/Users/twer/develop/tutorial/meta/inactive_record.rb:38:in `method_missing': invalid attribute (StandardError)
	from main.rb:38:in `test'
	from main.rb:41:in `<main>'
```
