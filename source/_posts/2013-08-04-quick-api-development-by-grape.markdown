---
layout: post
title: "使用Grape快速开发API"
date: 2013-08-04 10:29
comments: true
categories: 
- lightweight
- ruby
- grape

---

### Grape简介

[Grape](http://intridea.github.io/grape)是一个基于Rack的非常轻量级的框架，用于快速的开发API。一般来说，Rails对于单独的API来说，太过于重量级；而Sinatra虽然足够小巧，但是又没有为开发API提供足够的默认支持（如果从可控制性，灵活性上来说，Sinatra可能更好一些，但是如果有专门的更好用的工具，为什么不用呢？）。

安装非常简便：

```
$ gem install grape
```

或者使用在自己的Gemfile中，与其他的gem一起搭建API:

```
gem 'grape'
```

### 为既有系统添加API

#### 简单一试

之前的一篇介绍[ActiveRecord在既有系统中使用](http://icodeit.org/2013/05/using-active-record-as-a-standalone-orm/)的文章中，我使用ActiveRecord为既有的数据库visitor中的三个表(visitor, listGroup, listGroupItem)建立了ruby对应的模型。现在我们可以为这些模型包装一组API，以方便客户端（消费者）可以通过web来访问。

```
module MySys
    class API < Grape::API
        format :json

        resource :visitors do

            desc "get all visitor information"
            get do
                Visitor.limit(20)
            end

        end
    end
end
```

首先，MySys::API扩展了Grape::API。`format`定义我们的API会产生JSON格式的输出，resource定义了这一组API是为资源visitors提供的，因此访问API的url为：

```
http://localhost:9292/visitors/
```

当然，grape提供一个很方便的设置prefix，可以使得API的路径更有意义:

```
format :json
prefix "mysys"
```

url则相应地变为:

```
http://localhost:9292/mysys/visitors/
```

#### 处理参数

在对参数的处理上，grape也非常灵活，比如接上例，我们想要获取某一个具体的用户的信息：

```
http://localhost:9292/visitors/8a9d82b13b9786e1013b978766150001
```

我们可以添加一个新的endpoint：

```
desc "return a visitor"
params do
    requires :visitor_uid, :type => String, :desc => "visitor id"
end
route_param :visitor_uid do
    get do
        Visitor.find(params[:visitor_uid])
    end
end
```

params中要求，需要一个类型为String的参数visitor_uid。然后在handler中，通过params来引用这个参数的值。

#### 助手函数(Helper)

Grape允许开发者将编解码，权限校验等等的通用的操作分离出来，放入助手函数，这些Helper可以被所有的API使用:

```
helpers do
    def generate_default_visitor(email, site) 
        {
            :visitor_uid => SecureRandom.hex,
            :password_expiration => (Time.now + 60 * 60 * 24),
            :last_used_timestamp => (Time.now - 60 * 60 * 24),
            :visitor_login_id => email,
            :site_name => site
        }
    end
end
```

使用上边定义的助手函数`generate_default_visitor`：

```
desc "create a visitor"
params do
    requires :email, :type => String, :desc => "Email address"
    requires :site, :type => String, :desc => "Site"
end
post do
    attr = generate_default_visitor(params[:email], params[:site])
    visitor = Visitor.new attr
    visitor.visitor_uid = attr[:visitor_uid]
    visitor.save
end
```

### 对API进行测试

通过Web测试API有非常多的方式，比如通过浏览器的插件(POSTMan)，RSpec，但是我最喜欢，也是最轻便的方式是通过命令行工具curl：

```
curl http://localhost:9292/visitors/8a9d82b13b9786e1013b978766150001
```

或者：

```
curl -H "Content-Type: application/json" -X POST -d "{\"email\":\"jtqiu@tw.com\", \"site\":\"mysys\"}" http://localhost:9292/visitors/
```

命令行的程序curl是一个非常灵活，强大的工具，可以定制HTTP头信息，User Agent，支持所有的HTTP动词，最重要的是，在命令行很容易将工具们组合在一起，并完成自动化。
