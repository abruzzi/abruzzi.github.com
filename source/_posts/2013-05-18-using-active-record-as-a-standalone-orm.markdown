---
layout: post
title: "在既有数据库中使用ActiveRecord"
date: 2013-05-18 14:56
comments: true
categories: 
- ruby
- ORM
- ActiveRecord

---
###ActiveRecord

作为rails中的ORM(object relation-db mapping)框架，ActiveRecord在初次出现之时带给了人们以无限的惊喜和热情，也使得很多不堪忍受其他语言中粗糙的ORM框架的开发者转而投入rials的怀抱。而有很多的其他语言也在不断尝试模仿ActiveRecord，比如著名的php框架[codeigniter](http://codeigniter.org.cn/)。

在rails的后期版本中，ActiveRecord可以作为一个独立的库来在rails之外使用，这对使用ruby进行其他数据库应用开发的用户来说非常方便。

####在新的项目中使用ActiveRecord
如果在一个全新的rails应用程序中使用ActiveRecord，那么关于数据库方面的一切都可以托管给它，开发者在初期可能连一行代码都不需要编写就可以让程序“像模像样”的运行起来。

####在已有的数据库上使用ActiveRecord

现实世界中，最可能遇到的问题是数据库已经存在了（毕竟，对于关系型数据库而言，修改schema的影响太大）。这时候，我们仍然可以使用ActiveRecord来方便的访问数据库，得到ruby对象，而跳过冗长且容易出错的数据库访问层。

###一个例子

####数据库结构

数据库中有一个访客表(visitor)：

```
+-----------------------+--------------+-----+
| Field                 | Type         | Key |
+-----------------------+--------------+-----+
| visitor_uid           | varchar(32)  | PRI |
| visitor_login_id      | varchar(128) | MUL |
| visitor_password      | varchar(32)  |     |
| visitor_name          | varchar(100) |     |
| created_timestamp     | timestamp    |     |
| password_expiration   | timestamp    |     |
| last_used_timestamp   | timestamp    | MUL |
| visitor_alias         | varchar(128) | MUL |
| visitor_password_hash | binary(64)   |     |
+-----------------------+--------------+-----+
```

有一个访客浏览过的`分组`表(list_group)：

```
+------------------+---------------------+-----+
| Field            | Type                | Key |
+------------------+---------------------+-----+
| list_group_id    | bigint(20) unsigned | PRI |
| list_type        | varchar(32)         | MUL |
| visitor_uid      | varchar(32)         | MUL |
| list_name        | varchar(128)        |     |
| create_timestamp | timestamp           |     |
+------------------+---------------------+-----+
```

每个`分组`中，都有一些条目，具体到每个条目(list_group_item)：

```
+----------------------+---------------------+-----+
| Field                | Type                | Key |
+----------------------+---------------------+-----+
| list_group_item_id   | bigint(20) unsigned | PRI |
| list_group_id        | bigint(20) unsigned | MUL |
| item_id              | varchar(128)        | MUL |
| create_timestamp     | timestamp           |     |
| last_use_timestamp   | timestamp           |     |
| note                 | varchar(4000)       |     |
+----------------------+---------------------+-----+
```

三张表的关系如下：

![image](http://abruzzi.github.com/images/2013/05/active_record.png)


####示例程序的目录结构

```
├── Gemfile
├── Gemfile.lock
├── app.rb
├── config
│   └── database.yml
├── debug.log
└── model
    ├── list_group.rb
    ├── list_group_item.rb
    └── visitor.rb
```

####models

使用ActiveRecord，只需要简单的在模块上声明模块见的关系即可：

visitor类的定义，读起来非常自然：

```
require 'active_record'

class Visitor < ActiveRecord::Base
    has_many :groups, 
        :class_name => 'ListGroup', 
        :foreign_key => 'visitor_uid'

    self.table_name  = 'visitor'
    self.primary_key = 'visitor_uid'
end
```

ListGroup类的定义：

```
class ListGroup < ActiveRecord::Base
    self.table_name  = 'list_group'
    self.primary_key  = 'list_group_id'

    has_many :items, 
        :class_name => 'ListGroupItem', 
        :foreign_key => 'list_group_id'

    belongs_to :visitor, 
        :class_name => 'Visitor', 
        :foreign_key => 'visitor_uid'
end
```

最后是ListGroupItem的定义：

```
class ListGroupItem < ActiveRecord::Base
    self.table_name = 'list_group_item'
    self.primary_key = 'list_group_item_id'

    belongs_to :list_group, 
        :class_name => 'ListGroup', :foreign_key => 'list_group_id'
end
```

这种比较复杂的层级关系在现实中经常见到，而大部分HelloWorld型的介绍又touch不到，因此就将代码全部列于此处，以便索引。

####使用这些model

```
def main
    attr = visitor_attr('juntao.qiu#thoughtworks.com')
    visitor = Visitor.new attr
    visitor.visitor_uid = attr[:visitor_uid]
    visitor.save

    visitors = Visitor.find(:all)
    visitors.each do |visitor|
        p visitor[:visitor_login_id]
    end
end
```
这里即可任意的使用诸如new/save,find等ActiveRecord为我们包装起来的方法了。
