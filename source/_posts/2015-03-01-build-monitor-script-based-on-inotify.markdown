---
layout: post
title: "使用inotify/fswatch构建自动监控脚本"
date: 2015-03-01 14:12
comments: true
categories: 
- command line
- shell
---

## 自动告警脚本

最近项目上有这样一个需求：系统中有一个后台服务会不断的生成监控日志，根据系统的运行情况，它每天会在目录`/var/alarms`下生成一个文件，文件名带有时间戳，其中内容格式如下：

```sh
$ cat /var/alarms/alarms-20150228130522.csv
node,summary,occurrence,proiority
VIQ002,heartbeat failure,2/12/2015 01:23 AM,critical
VIQ002,packages are rejected,2/12/2015 01:22 AM,major
VIQ002,connection cannot be established,2/11/2015 01:23 AM,medium
VIQ001,packages are rejected,2/11/2015 01:23 AM,warning
VIQ001,connection cannot be established,2/09/2015 01:23 AM,medium
...
```

运维团队需要监控这个目录，如果里边的文件发生了变化，就要及时的发送邮件给工程团队解决。我们当然不可能人工的监控该目录，然后编写邮件，再拷贝粘贴，所以需要编写一个脚本来自动化这个任务。

处理方法有两种：

1.    编写一个crontab的任务，每隔五分钟轮询一下，然后编写脚本来探测变化，发送邮件
2.    使用操作系统提供的`inotify`相关API探测变化，编写脚本发送邮件

不过作为程序员，第二种方法显然更高级一些。另外相对于检测文件变化（对比目录树，检查时间戳，而且还要记录上一次变更的状态等），编写一个发送邮件的脚本要简单得多。

### 使用inotify

如果在`Linux`下，我们可以使用`inotify`相关的工具，你可以使用你正在使用的系统下的包管理工具来安装。也可以直接从源码包编译安装。

安装之后，系统中就有了一个叫做`inotifywait`的命令，这个命令提供多个参数。默认的`inotifywait`在接收到指定的事件（文件变化）后，会打印信息并退出。可以使用`-m`参数让`inotifywati`处于监听状态。`-e`参数指定需要监听的事件类型，下面是几个常见的事件类型：

1.  `CREATE`，创建
2.  `MODIFY`，修改
3.  `CLOSE_WRITE,CLOSE`，写入成功

还可以通过`--format`来指定事件的输出，`%w`表示监控的文件名，`%f`表示如果被监控的对象是目录，则当发生事件时返回文件名。比如下面的命令：

```sh
$ inotifywait -m -e close_write /var/alarms --format "%w%f"
```

表示以监控模式（事件发生后不退出，继续监听），监听`close_write`事件，在`/var/alarms`目录上，并且输出的格式为`%w%f`。

这样我们在另一个窗口上模拟事件发生：

```sh
$ touch /var/alarms/alarms-20150228130522.csv 
```

当前的窗口就会出现`/var/alarms/alarms-20150228130522.csv`这样的输出。有了这个功能，我们只需要编写一段简单的脚本就可以完成上一小节中的问题了：

```sh
#!/bin/bash
DIR=$1

inotifywait -m -e close_write $DIR --format "%w%f" | while read FILE
do
	cat ${FILE} | mail -s "Alarm: $FILE" juntao.qiu@gmail.com
done
```

命令`mail`是Linux下默认的邮件客户端，可以完成邮件的发送功能。将上边的脚本命名为`monitor.sh`，添加可执行权限，并启动监控：

```sh
$ chmod +x monitor.sh
$ ./monitor.sh /var/alarms
```

这样，当目标目录`/var/alarms`发生变化后，我们就可以收到告警邮件了！


### Mac OSX下使用fswatch

如果是在`Mac OSX`下，虽然没有了`inotify`相关的API，但是我们可以使用`fswatch`来完成同样的工作。

使用`brew`安装`fswatch`：

```sh
$ brew install fswatch
```

即可。`fswatch`也有很多选项，我们这里仅使用`-0`（表示以传统的NUL作为字符串终结符，因为*nix下文件名可以包含任意字符，比如空格）。我们可以很容易的用`xargs`将检测到的事件进行进一步的处理：

```sh
fswatch -0 /var/alarms | xargs -0 -n 1 ~/bin/send-notify.sh
```

其中，`-0`的意思与`fswatch`的命令中的`-0`一致，`-n 1`表示每条`NUL`结尾的字符串都执行一次脚本。脚本`send-notify.sh`的内容如下：

```sh
#!/bin/bash

FILE=$1
cat $FILE | mail -s "Alarm: $FILE" jutao.qiu@gmail.com
```

这样，当文件发生变化时，脚本就会发送一封邮件到指定邮箱了（由于我自己的laptop的hostname不像是一个合理的主机名，所以Gmail会把这封邮件放到垃圾邮件列表中，这里只是用作示例而已）。

![fswatch](/images/2015/03/mail-resized.png)

当然，由于脚本是我们自己可以编写的，所以理论上当检测到变化之后，我们可以做任何事情，比如[说几句话](http://icodeit.org/2014/09/simple-idea-and-simple-script/)，播放一段音乐等。


