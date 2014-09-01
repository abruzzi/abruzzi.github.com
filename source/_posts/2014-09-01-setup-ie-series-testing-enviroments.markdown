---
layout: post
title: "快速搭建IE测试环境（Virtualbox+ievms）"
date: 2014-09-01 18:16
comments: true
categories: 
- test
- dev-ops

---
### IE下的测试

作为一个有追求的程序员，应该尽可能的远离Windows系统。不论从专业开发者的角度，还是仅仅作为最终用户从使用体验上来说，Windows都可以算是垃圾中的战斗机：`没有shell`、`响应极慢`（比如从开机到可用需要多久，再对比一下Mac下的体验）、大部分操作都强依赖于鼠标，没有对应的快捷键、各类`病毒`等等。

但是，最为一个职业的程序员，又很难绕开Windows这个`猥琐`而又事实上很现实的存在，毕竟Windows在非专业市场上的占有率还是不容小觑的。一般而言，开发人员可以很轻松的使用现代的操作系统，编辑器，开发工具完成实际的业务需求，这部分工作很可能占整个交付工作的40%，但是又不得不在多个浏览器（IE的各个版本）中花费另外的60%。

既然很难抛开，那么我们就需要想办法简化对其的使用，比如将Windows隔离为一个纯粹的测试环境（不安装任何其他的软件，并且一旦`感染病毒`之后可以快速恢复）。

1.	将Windows安装到虚拟机中
2.	使用工具将诸如下载镜像，安装系统，安装特定版本的IE等操作简化为一条命令
3.	可以很容易的创建一个干净，纯粹，稳定的Windows环境

[ievms](https://github.com/xdissent/ievms)正是这样一个工具，它提供安装了各种版本IE的Windows操作系统的镜像，支持IE6到IE11。默认的，用户可以安装从IE6到IE11的所有镜像，但是很可能你无须所有的环境，ievms也提供对应的参数来确保只下载某一个。

不过对于一个团队来讲，可以安装所有的镜像到团队的某台公共的机器上，供所有人来进行跨IE浏览器的各个版本的测试。

这些虚拟机镜像都是虚拟磁盘`vmdk`文件，因此你需要先安装[VirtualBox]((https://www.virtualbox.org/wiki/Downloads))。

#### 安装ievms

安装ievms非常容易，只需要下载一个脚本即可：

```sh
$ curl -s https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh -L
```

github会将该请求重定向，所以加上`-L`参数来跳转到实际的地址。下载之后，执行该脚本：

```sh
$ chmod +x ievms.sh
$ ./ievms.sh
```

默认的`ievms`会下载所有的虚拟机镜像，可以通过参数`IEVMS_VERSIONS`来选择特定版本的虚拟机：

```sh
$ ./ievms.sh IEVMS_VERSIONS="7 8 9"
```

当然，也可以将这些命令合并为一行命令：

```sh
$ curl -s https://raw.githubusercontent.com/xdissent/ievms/master/ievms.sh -L | IEVMS_VERSIONS="7 8 9" bash
```

#### 用法

安装之后，一个新的虚拟机会被添加到VirtualBox中，只需要启动这个虚拟机即可：

![image](/images/2014/09/ie8-prepaid-resized.png)

另外，在这个虚拟机中，可以很方便的连接到宿主机。比如在宿主机上的12306端口运行了某个Web应用，那么通过地址：http://10.0.2.2:12306 来访问这个应用。

`注意`: 由于是整个虚拟磁盘的形式发布，因此这些镜像的体积都非常大，所有的镜像安装之后，会占用37G的空间，对于任何一个开发机来说，这个尺寸过于庞大，但是对于整个团队来说，应该还是可以接受的。

官方给出的尺寸列表如下：

```sh
$ du -ch *
 11G    IE10 - Win7-disk1.vmdk
 11G    IE11 - Win7-disk1.vmdk
1.5G    IE6 - WinXP-disk1.vmdk
1.6G    IE7 - WinXP-disk1.vmdk
1.6G    IE8 - WinXP-disk1.vmdk
 11G    IE9 - Win7-disk1.vmdk
 37G    total
```

