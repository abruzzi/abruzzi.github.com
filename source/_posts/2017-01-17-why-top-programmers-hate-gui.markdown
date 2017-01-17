---
layout: post
title: "为什么优秀的程序员喜欢命令行"
date: 2017-01-17 21:06
comments: true
categories: 
- 文化
- UNIX
- Graphite
- Grafana
- Shell
---

## 程序员的日常工作

>The three chief virtues of a programmer are: Laziness, Impatience and Hubris. -- Larry Wall

`懒惰`这个特点位于`程序员的三大美德`之首：唯有懒惰才会驱动程序员尽可能的将日常工作自动化起来，解放自己的双手，节省自己的时间。而`GUI`，不得不说，天然就是为了让**自动化**变得困难的一种设计。GUI更强调的是与人类的直接交互：通过视觉手段将信息以多层次的方式呈现，使用视觉元素进行指引，最后系统在后台进行实际的处理，并将最终结果以视觉手段展现出来。

这种更强调`交互`过程的设计初衷使得自动化变得非常困难。另一方面，由于GUI是为人类设计的，它的响应就不能太快，至少要留给操作者反应时间（甚至有些用户操作需要人为的加入一些延迟，以提升用户体验）。

程序员除了写代码之外，还有很多事情要做，比如自动化测试，基础设施的配置和管理，持续集成/持续发布环境，甚至有些团队好需要做一些与运维相关的事情（线上问题监控，环境监控等）。

- 开发/测试
- 基础设施管理
- 持续集成/持续发布
- 运维工作
- <del>娱乐</del>

### UNIX编程哲学

关于UNIX哲学，其实坊间有多个版本，这里有一个比较[详细的清单](https://zh.wikipedia.org/wiki/Unix%E5%93%B2%E5%AD%A6)。虽然有不同的版本，但是有很多一致的地方：

1. 小即是美
1. 让程序只做好一件事
1. 尽可能早地创建原型(然后逐步演进)
1. 数据应该保存为文本文件
1. 避免使用可定制性低下的用户界面

这里列举一些小的例子，我们来看看命令行工具是如何通过应用这些哲学来简化工作，提高效率的。一旦你熟练掌握这些技能，就再也无法摆脱它，也再也忍受不了低效而难用的各种`GUI`工具了。

### 命令行如何帮助程序员提升效率

#### 一个高阶计算器

在我的编程生涯的早期，读过的最为振奋的一本书是[《UNIX编程环境》](https://book.douban.com/subject/1033144/)，和其他基本UNIX世界的大部头比起来，这本书其实还是比较小众的。我读大二的时候这本书已经出版了差不多22年(中文版也已经有7年了)，有一些内容已经过时了，比如没有返回值的`main`函数，外置的参数列表等等，不过在学习到`HOC`(High Order Calculator)的全部开发过程时，我依然被深深的震撼到了。

简而言之，这个`HOC`语言的开发过程需要这样几个组件：

- 词法分析器`lex`
- 语法分析器`yacc`
- 标准数学库`stdlib`

另外还有一些自定义的函数等，最后通过`make`连接在一起。我跟着书上的讲解，对着书把所有代码都敲了一遍。所有的操作都是在一台很老的IBM的ThinkPad T20上完成的，而且全部都在命令行中进行（当然，还在命令行里听着歌）。

这也是我第一次彻底被UNIX的哲学所折服的体验：

- 每个工具只做且做好一件事
- 工具可以协作起来
- 一切面向文本

下面是书中的`Makefile`脚本，通过简单的配置，就将一些**各司其职**的小工具协作起来，完成一个`编程语言`程序的预编译、编译、链接、二进制生成的动作。

```make
YFLAGS = -d
OBJS = hoc.o code.o init.o math.o symbol.o

hoc5:	$(OBJS)
	cc $(OBJS) -lm -o hoc5

hoc.o code.o init.o symbol.o: hoc.h

code.o init.o symbol.o: x.tab.h

x.tab.h: y.tab.h
	-cmp -s x.tab.h y.tab.h || cp y.tab.h x.tab.h

pr:	hoc.y hoc.h code.c init.c math.c symbol.c
	@pr $?
	@touch pr

clean:
	rm -f $(OBJS) [xy].tab.[ch]
```

虽然现在来看，这本书的很多内容已经过期（特别是离它第一次出版已经过去了近30年），有兴趣的朋友可以读一读。

### 基础设施自动化

开发过程中，工程师还需要关注的一个问题是：软件运行的环境。我在上学的时候，刚开始学习Linux的时候，会在Windows机器上装一个虚拟机软件VMWare，然后在VMWare中安装一个`Redhat Linux 9`。这样当我不小心把Linux玩坏了之后，只需要重装一下就行了，不影响我的其他数据（比如课程作业，文档之类）。不过每次重装也挺麻烦，需要找到`iso`镜像文件，再挂载到本地的虚拟光驱上，然后再用VMWare来安装。

而且这些动作都是在GUI里完成的，每次都要做很多重复的事情：找镜像文件，使用虚拟光驱软件挂载，启动VMWare，安装Linux，配置个人偏好，配置用户名/密码等等。熟练之后，我可以在30分钟 -- 60分钟安装和配置好一个新的环境。

#### Vagrant

后来我就发现了`Vagrant`，它支持开发者通过配置的方式将机器描述出来，然后通过命令行的方式来安装并启动，比如下面这个配置：

```rb
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "precise64"
  config.vm.network "private_network", :ip => "192.168.2.100"
end
```

它定义了一个虚拟机，使用`Ubuntu Precise 64`的镜像，然后为其配置一个网络地址`192.168.2.100`，定义好之后，我只需要执行：

```sh
$ vagrant up
```

我的机器就可以在几分钟内装好，因为这个动作是命令行里完成的，我可以在持续集成环境里做同样的事情 -- 只需要一条命令。定义好的这个文件可以在团队内共享，可以放入版本管理，团队里的任何一个成员都可以在几分钟内得到一个和我一样的环境。

#### Ansible

一般而言，对于一个软件项目而言，一个全新的操作系统基本上没有任何用处。为了让应用跑起来，我们还需要很多东西。比如Web服务器，Java环境，cgi路径等，除了安装一些软件之外，还有大量的配置工作要做，比如`apache httpd`服务器的文档根路径，JAVA_HOME环境变量等等。

这些工作做好了，一个环境才算就绪。我记得在上一个项目上，不小心把测试环境的Tomcat目录给删除了，结果害的另外一位同事花了三四个小时才把环境恢复回来（包括重新安装Tomcat，配置一些JAVA_OPTS，应用的部署等）。

不过还在我们有很多工具可以帮助开发者完成环境的自动化准备，比如：Chef, Puppet, Ansible。只需要一些简单的配置，然后结合一个命令行应用，整个过程就可以自动化起来了：

```yaml
- name: setup custom repo
  apt: pkg=python-pycurl state=present

- name: enable carbon
  copy: dest=/etc/default/graphite-carbon content='CARBON_CACHE_ENABLED=true'

- name: install graphite and deps
  apt: name={{ item }} state=present
  with_items: packages

- name: install graphite and deps
  pip: name={{ item }} state=present
  with_items: python_packages

- name: setup apache
  copy: src=apache2-graphite.conf dest=/etc/apache2/sites-available/default
  notify: restart apache

- name: configure wsgi
  file: path=/etc/apache2/wsgi state=directory
```

上边的配置描述了安装`graphite-carbon`，配置`apahce`等很多手工的劳动，开发者现在只需要执行：

```sh
$ ansible 
```

就可以将整个过程自动化起来。现在如果我不小心把`Tomcat`删了，只需要几分钟就可以重新配置一个全新的，当然整个过程还是自动的。这在GUI下完全无法想象，特别是有如此多的定制内容的场景下。

### 持续集成/持续发布

日常开发任务中，除了实际的编码和环境配置之外，另一大部分内容就是持续集成/持续发布了。借助于命令行，这个动作也可以非常高效和自动化。

#### Jenkins

持续集成/持续发布已经是很多企业IT的基本配置了。各个团队通过持续集成环境来编译代码、静态检查、执行单元测试、端到端测试、生成报告、打包、部署到测试环境等等。

![](/images/2017/01/jenkins-resized.png)

比如在`Jenkins`环境中，在最前的版本中，要配置一个构建任务需要很多的GUI操作，不过在新版本中，大部分操作都已经可以写成脚本。

这样的方式，使得自动化变成了可能，要复制一个已有的`pipline`，或者要修改一些配置、命令、变量等等，再也不需要用鼠标点来点去了。而且这些代码可以纳入项目代码库中，和其他代码一起被管理，维护，变更历史也更容易追踪和回滚（在GUI上，特别是基于Web的，回滚操作基本上属于不可能）。

```groovy
node {
   def mvnHome
   
   stage('Preparation') { // for display purposes
      git 'https://github.com/jglick/simple-maven-project-with-tests.git'
      mvnHome = tool 'M3'
   }
   
   stage('Build') {
      sh "'${mvnHome}/bin/mvn' -Dmaven.test.failure.ignore clean package"
   }
   
   stage('Results') {
      junit '**/target/surefire-reports/TEST-*.xml'
      archive 'target/*.jar'
   }
}
```

上面这段`groovy`脚本定义了三个`Stage`，每个`Stage`中分别有自己的命令，这种以代码来控制的方式显然比GUI编辑的方式更加高效，自动化也编程了可能。

### 运维工作

#### 自动化监控

Graphite是一个功能强大的监控工具，不过其背后的理念倒是很简单：

- 存储基于时间线的数据
- 将数据渲染成图，并定期刷新

用户只需要将数据按照一定格式定期发送给`Graphite`，剩下的事情就交给`Graphite`了，比如它可以消费这样的数据：

```
instance.prod.cpu.load 40 1484638635
instance.prod.cpu.load 35 1484638754
instance.prod.cpu.load 23 1484638812
```

第一个字段表示数据的**名称**，比如此处`instance.prod.cpu.load`表示`prod`实例的CPU负载，第二个字段表示数据的**值**，最后一个字段表示时间戳。

这样，`Graphite`就会将所有同一个名称下的值按照时间顺序画成图。

![](/images/2017/01/graphite-demo-resized.png)

[图片来源](https://techblog.chegg.com/2013/06/17/making-best-use-of-graphite-for-dynamic-services/)

默认地，`Graphite`会监听一个网络端口，用户通过网络将信息发送给这个端口，然后`Graphite`会将信息持久化起来，然后定期刷新。简而言之，只需要一条命令就可以做到发送数据：

```sh
echo "instance.prod.cpu.load 23 `date +%s`" | nc -q0 graphite.server 2003
```

`date +%s`会生成当前时间戳，然后通过`echo`命令将其拼成一个完整的字符串，比如：

```sh
instance.prod.cpu.load 23 1484638812
```

然后通过管道`|`将这个字符串通过网络发送给`graphite.server`这台机器的`2003`端口。这样数据就被记录在`graphite.server`上了。

##### 定时任务

如果我们要自动的将数据每隔几秒就发送给`graphite.server`，只需要改造一下这行命令：

1. 获取当前CPU的load
1. 获取当前时间戳
1. 拼成一个字符串
1. 发送给`graphite.server`的`2003`端口
1. 每隔5分钟做重复一下1-4

获取CPU的load在大多数系统中都很容易：

```sh
ps -A -o %cpu 
```

这里的参数:

- `-A`表示统计所有当前进程
- `-o %cpu`表示仅显示`%cpu`列的数值

这样可以得到每个进程占用CPU复杂的数字：

```sh
%CPU
  12.0
  8.2
  1.2
  ...
```

下一步是将这些数字加起来。通过`awk`命令，可以很容易做到这一点：

```sh
$ awk '{s+=$1} END {print s}' 
```

比如要计算`1 2 3`的和：

```sh
$ echo "1\n2\n3" | awk '{s+=$1} END {print s}'
6
```

通过管道可以讲两者连起来：

```sh
$ ps -A -o %cpu | awk '{s+=$1} END {print s}'  
```

我们测试一下效果：

```sh
$ ps -A -o %cpu | awk '{s+=$1} END {print s}'  
28.6
```

看来还不错，有个这个脚本，通过`crontab`来定期调用即可：

```sh
#!/bin/bash
SERVER=graphite.server
PORT=2003
LOAD=`ps -A -o %cpu | awk '{s+=$1} END {print s}'`

echo "instance.prod.cpu.load ${LOAD} `date +%s`" | nc -q0 ${SERVER} ${PORT}
```

当然，如果使用`Grafana`等强调UI的工具，可以很容易的做的更加酷炫：

![](/images/2017/01/grafana-demo-resized.png)

[图片来源](http://www.virtual-valley.net/netapp-performance-monitor/)

*想想用GUI应用如何做到这些工作。*

### 娱乐

#### 命令行的MP3播放器

最早的时候，有一个叫做`mpg123`的命令行工具，用来播放MP3文件。不过这个工具是商用的，于是就有人写了一个工具，叫`mpg321`，基本上是`mpg123`的开源克隆。不过后来`mpg123`自己也开源了，这是后话不提。


将我的所有`mp3`文件的路径保存成一个文件，相当于我的歌单：

```sh
$ ls /Users/jtqiu/Music/*.mp3 > favorites.list
$ cat favorites.list
...
/Users/jtqiu/Music/Rolling In The Deep-Adele.mp3
/Users/jtqiu/Music/Wavin' Flag-K'Naan.mp3
/Users/jtqiu/Music/蓝莲花-许巍.mp3
...
```

然后我将这个歌单交给mpg321去在后台播放：

```sh
$ mpg321 -q --list favorites.list &           
[1] 10268
```

这样我就可以一边写代码一边听音乐，如果听烦了，只需要将这个后台任务切换到前台`fg`，然后就可以关掉了：

```sh
$ fg
[1]  + 10268 running    mpg321 -q --list favorites.list
```

### 小结

综上，优秀的程序员借助命令行的特性，可以成倍（有时候是跨越数量级的）地提高工作效率，从而有更多的时间进行思考、学习新的技能，或者开发新的工具帮助某项工作的自动化。这也是**优秀的程序员之所以优秀**的原因。而面向手工的，原始的图形界面会拖慢这一过程，很多原本可以自动化起来的工作被淹没在“简单的GUI”之中。

最后补充一点，本文的关键在于强调`优秀的程序员`与命令行的关系，而不在GUI应用和命令行应用的优劣。GUI应用当然有其使用场景，比如做3D建模，`GIS`系统，设计师的创作，图文并茂的字处理软件，电影播放器，网页浏览器等等。