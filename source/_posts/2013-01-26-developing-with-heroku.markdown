---
layout: post
title: "将应用程序部署到heroku"
date: 2013-01-26 19:02
comments: true
categories: 
- ThoughtWorks
- open source
tags: [open source, heroku]

---
###heroku
使用heroku，开发人员可以很容易的将自己的应用程序公开给世界上的其他用户使用，heroku会为你提供一个url，一些预设的空间如数据库（postgresql）等。这对于需要频繁远程showcase的场景提供了非常好的方式，当然对于开发人员向其他的开发人员或者最终用户展现自己的框架的外观/行为等场景也会非常有用。

###在heroku上注册用户
首先，当然是在heroku上[注册一个开发账户](https://api.heroku.com/signup/devcenter)，如果你已经注册过，就请接着第二步

###下载heroku的本地Toolbox
heroku提供了一个很好用的[工具包](https://toolbelt.heroku.com/)，通过这个工具包，开发人员可以很容易的对部署在heroku上的应用程序做操作。

###在本地登陆heroku
如果没有上传过key的话，heroku会提醒你创建一个新的ssh公钥，然后上传到heroku（这个过程与使用github非常类似）

```
$ heroku login
Enter your Heroku credentials.
Email: adam@example.com
Password: 
Could not find an existing public key.
Would you like to generate one? [Yn] 
Generating new SSH public key.
Uploading ssh public key /Users/adam/.ssh/id_rsa.pub
```

如果已经上传过key，则可以直接登陆

###准备工作
在本地生成一个应用程序的基本结构，如：`Gemfile`，目录结构等。然后在本地配置好git环境，比如：

```
$ git init
$ git add .
$ git commit -m "init"
```
准备Procfile：

```
web: bundle exec ruby app.rb -p $PORT -E production
```
`app.rb`相当于你的应用程序的主入口(main)，`-E`指定运行环境（此处指定为production），你的应用程序可能会根据次设置来进行一些资源的选择（数据库指向，资源文件位置等）

在上传之前，需要确保自己的应用程序可以在本地正常运行：

```
foreman start
```
应用程序将在本地的5000端口上运行，此时可以做一些简单的验证，保证应用程序运行正常。

```
$ git add .
$ git commit -m "ready for deploy app to heroku"
```

###上传你的App
这时，可以很轻易的将App上传到heroku了：

```
$ heroku create
$ git push heroku master
```
当然，第一次上传可能会比较慢（取决于你应用程序的大小），如果一切正常，heroku将会尝试根据你的Gemfile来安装依赖，安装完成之后，会尝试根据Procfile中的配置启动你的应用程序。

如果你的应用程序会访问数据库（非postgresql的数据库），那么建议在Gemfile中指定当测试时使用该数据库，而在production环境中使用postgresql，因为heroku使用的正是postgresql：

```
configure :test do
    DataMapper.setup(:default, ENV['DATABASE_URL'] || "local-db-url")
    DataMapper.finalize.auto_upgrade!
end
```

我的应用在本地使用sqlite，而在heroku中使用其提供的postgresql。