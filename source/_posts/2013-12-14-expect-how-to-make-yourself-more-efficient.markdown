---
layout: post
title: "使用expect来自动化交互式命令"
date: 2013-12-14 17:40
comments: true
categories: 
- Efficient
- Expect

---

### 一个实际的场景

大部分命令行程序都被设计成了可以被管道连接起来的，这样在命令行里可以很容易的讲很多命令串起来，从而完成极为强大的功能。比如：

```
$ find . -name "*.js" | xargs basename | uniq | wc -l
```

这个命令会递归的查找当前目录下所有的JavaScript文件，然后用`basename`去掉可能存在的路径字符串(比如，`basename path/to/file`会返回`file`)，然后我们使用uniq来保证查找列表中得每个条目都是唯一的，最后用`wc -l`来统计行数。

但是并非所有场景都不需要人的干预，比如一个**vpn**链接的建立过程：

1. 选择vpn的Group名称
2. 填写用户名
3. 填写密码
4. 等待连接建立，然后程序退出

![image](http://abruzzi.github.com/images/2013/12/vpnlogin.png)

像这种需要用户交互操作的程序，是无法通过常规的方式来完成自动化的。如果你经常需要做这样的操作，比如网络环境并不稳定，每天需要连接2-3次，那也是一个非常烦人的事情。

[Expect](http://expect.sourceforge.net/)正是为这种场景设计的。

### Expect简介

[Expect](http://expect.sourceforge.net/)用来自动化这些`交互式`的命令行程序，比如telnet, ftp等。

Expect脚本非常简单，基本的模式是：

1. 启动一个命令A
2. 当命令的输出中包含字符串X的话
3. 输入Y

用expect的脚本来表示的话，代码如下：

```
#!/usr/bin/expect

spawn A
expect "X"
send "Y"
```

`spawn`会启动一个进程，`expect`会负责和这个进程来交互。如果没有匹配到指定的字符串，则在一个超时时间内expect就会退出。当然可以通过`set timeout -1`来让程序expect永远等待下去。

### 两个小例子
#### 自动的登录到vpn服务器上

```
#!/usr/bin/expect

set addr "vpn.service.com.au"
set user "qiu.juntao"
set pass "mypassword"

set timeout -1 
spawn /opt/cisco/anyconnect/bin/vpn connect $addr

expect "Group: "
send "1\r"

expect "Username: " 
send "$user\r"

expect "Password: " 
send "$pass\r"

expect ">> state: Connected"
```

#### 自动通过ssh登录到远程

另外一个问题是，如果需要这个session保持下去，比如需要自动`ssh`到一个远程的服务器上，但是又不想每次都输入认证信息，则可以进入`inactive`模式：

```
#!/usr/bin/expect

set pass "mypassword"

set timeout -1 
spawn ssh user@remote.dev.env.com

expect "Password:"
send "$pass\r"

interact
```

这样就可以完成自动登录了，而expect回一直等到你从ssh中退出。