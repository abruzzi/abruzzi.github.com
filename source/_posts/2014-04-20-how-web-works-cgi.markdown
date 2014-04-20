---
layout: post
title: "Web是怎么工作的: CGI脚本"
date: 2014-04-20 19:22
comments: true
categories: 
- lightweight
- cgi
- web

---

#### CGI的一些背景

Web在设计之初只是可以提供静态内容，用于诸如文档分享，论文引用这样的内容。但是很快人们就不满足于静态的内容了，根据UNIX系统的哲学，人们倾向于让不同的应用程序通过已有的机制（进程间通信如管道，UNIX域socket，以及TCP/IPsocket）连接起来。

在Web服务器，诸如Apache httpd中加入与外部应用程序的通信接口就显得非常自然了。[CGI(Common Gateway Interface)](http://en.wikipedia.org/wiki/Common_Gateway_Interface)即是在这种背景下被发明的。

基本来说，CGI可以是任何的可执行程序，可以是Shell脚本，二进制应用，或者其他的脚本（Python脚本，Ruby脚本等）。CGI的基本流程是这样：

1.	Apache接收到客户端的请求
2.	通过传统的fork-exec机制启动外部应用程序（cgi程序）
3.	将客户端的请求数据通过环境变量和重定向发送给外部应用（cgi程序）
4.	将cgi程序产生的输出写回给客户端（浏览器）
5.	停止cgi程序（kill）

![image](/images/2014/04/cgi.png)

#### 配置Apache支持CGI

本文的所有示例都是在Mac OSX环境下编写和实验。

先创建一个cgi的运行目录`/Users/jtqiu/Sites/cgi-bin/`，然后创建一个空的文件`echo.cgi`：	

```sh
$ mkdir -p /Users/jtqiu/Sites/cgi-bin/
$ touch echo.cgi
```

在这个文件中，添加一小段python代码：

```python
#!/usr/bin/env python

print("Content-Type: text/html\n\n")
print("<b>Hello, World</b>\n")
```

修改文件的执行权限：

```sh
$ chmod +x echo.cgi
```

这段python代码并无特别，如果在shell运行这个脚本，可以得到：

```
Content-Type: text/html

<b>Hello, World</b>
```

这个可执行文件将作为我们的第一个CGI脚本，完成了这一步，我们需要配置Apache来支持CGI，首先，在目录`/etc/apache2/users/`中创建一个文件，文件名就是你的用户名称，如`jtqiu.conf`。

```sh
$ sudo vi /etc/apache2/users/jtqiu.conf
```

添加以下配置，其中`/Users/jtqiu/Sites/cgi-bin/`目录就是所有cgi脚本所在的目录，在次配置中`AddHandler cgi-script .cgi`表示为所有后缀为cgi的添加`cgi-script`的`Handler`。

```xml
<Directory "/Users/jtqiu/Sites/cgi-bin/">
    AddHandler cgi-script .cgi
    Options +ExecCGI
</Directory>
```

然后重启apache:

```sh
$ sudo apachectl restart
```

下面我们就通过`curl`来进行测试：

```sh
curl -v http://localhost/~jtqiu/cgi-bin/echo.cgi
```

##### 更进一步

传统的CGI脚本的生命周期很短，Web服务器在接收到一次请求之后，会fork出一个进程来执行CGI脚本，一旦请求完成，这个进程就会被终止。

我们可以设置一个超时来查看：

```python
#!/usr/bin/env python

import time

time.sleep(5)

print("Content-Type: text/html\n\n")
print("<b>Hello, World</b>\n")
```

```sh
curl -v http://localhost/~jtqiu/cgi-bin/echo.cgi
```

再次通过curl脚本来查看，另起一个窗口，通过`ps -Af | grep cgi`来查看

![[image]](/images/2014/04/cgi-ps-resized.png)


##### 一个稍微有点用的脚本

Web服务器通过环境变量来和CGI脚本进行部分的数据传递，比如下面这个例子会打印所有的，来自Web服务器的环境变量：

```python
#!/usr/bin/env python
import os

print "Content-type: text/html\n\n";
print "<b>Environment</b>\n";

print "<ul>"
for param in os.environ.keys():
      print "<li>%20s: %s</li>" % (param, os.environ[param])

print "</ul>"
```

通过`curl`来测试：

```
$ curl http://localhost/\~jtqiu/cgi-bin/echo.cgi
```

会的到一个完整的环境变量列表：

```html
<b>Environment</b>

<ul>
<li>VERSIONER_PYTHON_PREFER_32_BIT: no</li>
<li>     SERVER_SOFTWARE: Apache/2.2.26 (Unix) DAV/2 PHP/5.4.24 mod_ssl/2.2.26 OpenSSL/0.9.8y</li>
<li>         SCRIPT_NAME: /~jtqiu/cgi-bin/echo.cgi</li>
<li>    SERVER_SIGNATURE: </li>
<li>      REQUEST_METHOD: GET</li>
<li>     SERVER_PROTOCOL: HTTP/1.1</li>
<li>        QUERY_STRING: </li>
<li>                PATH: /usr/bin:/bin:/usr/sbin:/sbin</li>
<li>     HTTP_USER_AGENT: curl/7.30.0</li>
<li>         SERVER_NAME: localhost</li>
<li>         REMOTE_ADDR: ::1</li>
<li>         SERVER_PORT: 80</li>
<li>         SERVER_ADDR: ::1</li>
<li>       DOCUMENT_ROOT: /Library/WebServer/Documents</li>
<li>     SCRIPT_FILENAME: /Users/jtqiu/Sites/cgi-bin/echo.cgi</li>
<li>        SERVER_ADMIN: you@example.com</li>
<li>           HTTP_HOST: localhost</li>
<li>         REQUEST_URI: /~jtqiu/cgi-bin/echo.cgi</li>
<li>         HTTP_ACCEPT: */*</li>
<li>   GATEWAY_INTERFACE: CGI/1.1</li>
<li>         REMOTE_PORT: 64361</li>
<li>__CF_USER_TEXT_ENCODING: 0x46:0:0</li>
<li>VERSIONER_PYTHON_VERSION: 2.7</li>
</ul>

```

#### 更进一步FastCGI

传统的CGI脚本，生命周期很短，只会serve一次请求就终止了。如果有高并发的场景的话，显然服务器性能会收到极大的冲击。因此人们又设计了[FastCGI](http://en.wikipedia.org/wiki/FastCGI)。FastCGI的生命周期很长，甚至可以被实现成一个TCP/IP的服务器，这样就会永远运行下去。

目前，Apache，Nginx等Web服务器都已经支持FastCGI。
