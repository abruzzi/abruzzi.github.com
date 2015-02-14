---
layout: post
title: "Linux命令行中的7个小技巧"
date: 2015-02-14 17:48
comments: true
categories: 
- Linux
- Command line
---

### Linux命令行中的7个小技巧

命令行是开发者的好朋友，`*nix`系统（包括Mac OS X和各种Linux）都自带了强大的Shell环境，作为一个专业的程序员，Shell是离不开的。这里总结了几个常用的小技巧，都是我自己平时经常用，而又不想每次都去Google的。

#### 如何知道哪个进程在监听4000端口？

当启动服务时，经常会遇到想要`Address already in use`这样的异常，那么如何知道是哪个进程占用了该端口呢？

```sh
$ lsof -i :4000
```

`lsof`会列出系统目前打开的文件（List open files，Linux世界中，一切都是文件），`-i`表示网络地址（Internet address），注意此处的冒号。如果不带参数，lsof会列出所有打开的网络地址：

![lsof](/images/2015/02/lsof-resized.png)

```sh
$ lsof -i :4000
COMMAND   PID  USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ruby    32303 jtqiu    7u  IPv4 0x947b402a4bb8370b      0t0  TCP *:terabase (LISTEN)
```

#### Shell中如何设置代理？

很多公司都会有一个代理服务器供员工上外网使用，命令行中设置代理非常容易：

```sh
export http_proxy="http://username:password@hosename:port"
```

如果密码中有特设字符，比如`$`的话，需要转义一下。使用URLEncoding即可，比如`$`就是`%24`。最简单的就是在Chrome的`Console`中输入`encodeURIComponent("$")`来获得转义字符。

如果不想对某些地址使用代理，可以设置`no_proxy`环境变量：

```sh
export no_proxy="127.0.0.1, localhost, *.cnn.com, 192.168.1.10, domain.com:8080"
```

#### 如何为svn中的脚本设置可执行属性

你在Linux下创建了一个可执行脚本`e2e_test.sh`，但是团队里的其他人工作在Windows系统上，当你提交可执行脚本之后，他们checkout的是一个不能执行的文件！（其实也在情理之中，Windows这种垃圾货什么时候正常过呢？）

这时候可以通过给这个脚本设置一个`svn`的属性:

```sh
svn propset svn:executable "*" e2e_test.sh
```

这样在Windows上才heckout之后就正常了。

#### 在Bash脚本中如何判断一个文件是否可执行？

有时候我们在`Bash`中需要判断某个文件是否可以执行，这行脚本可以解救你：

```sh
if [ -x $FILENAME ]; then
  # the file is executable
fi
```

判断某个文件是否存在的脚本为：

```sh
if [ -f $FILENAME ]; then
  # the file is existing
fi
```

#### 我正在用的Linux是哪个发行版？

```sh
$ lsb_release -a
```

在`SUSE`系统中运行这条命令可以得到这样的输出:

```sh
$ lsb_release -a
LSB Version:    core-2.0-noarch:core-3.0-noarch:core-2.0-x86_64:core-3.0-x86_64:desktop-3.1-amd64:desktop-3.1-noarch:graphics-2.0-amd64:graphics-2.0-noarch:graphics-3.1-amd64:graphics-3.1-noarch
Distributor ID: SUSE LINUX
Description:    SUSE Linux Enterprise Server 10 (x86_64)
Release:        10
Codename:       n/a
```

而在`ubuntu`上则为:

```sh
$ lsb_release  -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 12.04.3 LTS
Release:        12.04
Codename:       precise
```

与之相关的还有个问题是我当前的操作系统是`32位还是64为呢`?

```sh
$ uname -m
x86_64
```

或者使用`file`命令来查看系统自带的执行文件的元数据信息:

```sh
$ file /usr/bin/file
/usr/bin/file: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.15, BuildID[sha1]=0xe04b36145abc21d863652b93e6a0d069f7dfd3f4, stripped
```

#### 查找文件(跳过某些指定目录)

你想要统计系统中所有的`JavaScript`文件的数量，但是又不想把外部的库文件（位于`libs`目录中）统计在内：

```sh
find . -path ./libs -prune -o -name "*.js" | wc -l
```

这里大概解释一下，上面的命令其实等于这条命令的缩写：

```sh
find . -path ./libs -a -prune -o -name "*.js" | wc -l
```

也即

```sh
find . -path ./libs -and -prune -or -name "*.js" | wc -l
```

翻译成伪代码相当于：

```ruby
if path == "./libs"
    prune
else
    find_by_name "*.js"
end
```

#### 断点续传

下载了一半，网络断了。小文件的话大不了重来一次，但是如果是一个7G的镜像呢？好在我们有`wget -c`。`wget`基本上是Linux中下载软件的标配了，它有很多的参数，甚至可以将整个静态网站克隆到本地，断点续传当然是支持的了：

```sh
$ wget -c https://downloads.cloudera.com/demo_vm/virtualbox/cloudera-quickstart-vm-4.6.0-0-virtualbox.7z --no-check-certificate
--2014-05-08 12:32:25--  https://downloads.cloudera.com/demo_vm/virtualbox/cloudera-quickstart-vm-4.6.0-0-virtualbox.7z
Connecting to 172.19.6.47:8080... connected.
Proxy request sent, awaiting response... 206 Partial Content
Length: 3393638045 (3.2G), 2951427152 (2.7G) remaining [text/plain]
Saving to: `cloudera-quickstart-vm-4.6.0-0-virtualbox.7z'

13% [++++++++++                                                                      ] 450,866,893 57.8K/s  eta 3h 57m
```
