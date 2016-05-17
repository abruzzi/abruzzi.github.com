---
layout: post
title: "为故障和失败做设计"
date: 2016-05-17 22:34
comments: true
categories: 
- Design
- Spring
- 
---

## 为故障和失败做设计

先来看一个笑话：

>QA工程师走进酒吧，要了一杯啤酒，要了0杯啤酒，要了999999999杯啤酒，要了一只蜥蜴，要了-1杯啤酒，要了一个sfdeljknesv，酒保从容应对，QA工程师 很满意。接下来，一名顾客来到了同一个酒吧，问厕所在哪，酒吧顿时起了大火，然后整个建筑坍塌了。

事实上，无论我们事先做多么详尽的计划，我们还是会失败。而且大多数时候，失败、故障都会从一个我们无法预期的角度发生，令人猝不及防。

如果没有办法避免失败（事先要考虑到这么多的异常情况不太现实，而且会投入过多的精力），那么就需要设计某种机制，使得当发生这种失败时系统可以将损失降低到最小。

另一方面，系统需要具备从灾难中回复的能力。如果由于某种原因，服务进程意外终止了，那么一个`watchdog`机制就会非常有用，比如supervisord就可以用来保证进程意外终止之后的自动启动。

```ini
[program:jigsaw]
command=java -jar /app/jigsaw.jar
startsecs=0
stopwaitsecs=0
autostart=true
autorestart=true
stdout_logfile=/var/log/jigsaw/app.log
stderr_logfile=/var/log/jigsaw/app.err
```

在现实世界中，设计一个无缺陷的系统显然是不可能的，但是通过努力，我们还是有可能设计出具有弹性，能够快速失败，从失败中恢复的系统来。

### 错误无可避免

#### 令人担心的错误处理

我们先来看两个代码片段，两段代码都是在实现一个典型的Linux下的Socket服务器：

```c
int main (int argc, char *argv[]) {
  int serversock;
  struct sockaddr_in server;

  serversock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
  setup_sockaddr(&server);
  bind(serversock, (struct sockaddr *) &server, sizeof(server));
  listen(serversock, MAXPENDING)
  //...
}
```

如果加上现实中可能出现的各种的处理，代码会变长一些：

```c
int main (int argc, char *argv[]) {
  int serversock;
  struct sockaddr_in server;

  if (argc != 2) {
    fprintf(stderr, "USAGE: server <port>\n");
    exit(-1);
  }
  
  if ((serversock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
    fprintf(stderr, "Failed to create socket\n");
    exit(-1);
  }
  
  setup_sockaddr(&server);
  if (bind(serversock, (struct sockaddr *) &server,
                               sizeof(server)) < 0) {
    fprintf(stderr, "Failed to bind the server socket\n");
    exit(-1);
  }

  if (listen(serversock, MAXPENDING) < 0) {
    fprintf(stderr, "Failed to listen on server socket\n");
    exit(-1);
  }

  //...
}
```

早在上学的时候，我在编写程序时就非常害怕处理错误情况。一方面加入错误处理会导致代码变长、变难看，另一方面是担心有遗漏掉的点，更多的则是对复杂多变的现实环境中不确定性的担忧。

每当写这样的代码时，我都会陷入深深的焦虑：如果真的出错了怎么办？事实上我也经常会遇到错误，比如命令行参数没有写对，绑定一个
已经被占用的端口，磁盘空间不足等等。工作之后，这些烦人的问题其实也并不经常出现。偶尔出现时我们也有很好的日志来帮助定位，最后问题总会解决，不过那种对不确定性的担心仍然深藏心底。

#### UDP协议

早在大学网络课上，我就已经对不靠谱的`UDP`协议非常不满了：作为一个网络协议，竟然不能保证数据可靠的传送到网络的另一端，如果数据没有丢失，也无法保证次序。这种有点不负责任的协议我从来不用，甚至在做练习时都会将其自动过滤，不管那种编程语言，我都会优先考虑`TCP`。

不过在学习网络视频传输的时候，我发现很多时候人们都会采用`UDP`。另外很多场景下，比如最早的`QQ`也都使用了`UDP`来作为内网穿透等设计者可能都没有考虑到的功能。

事实上，这种看似不靠谱的协议在很多IM软件中都在采用（混合模式），比如Skype：

```sh
lsof -i -n | grep -i skype | awk '{print $1, $8, $9}'    
Skype TCP 192.168.0.101:52093->91.190.219.39:12350
Skype UDP 127.0.0.1:50511
Skype TCP 192.168.0.101:53090->40.113.87.220:https
Skype UDP *:*
Skype TCP 192.168.0.101:52240->64.4.61.220:https
Skype TCP 192.168.0.101:14214
Skype UDP *:63639
Skype UDP 192.168.0.101:14214
Skype TCP 192.168.0.101:52544->168.63.205.106:https
Skype TCP 192.168.0.101:52094->157.55.56.145:40032
Skype TCP 192.168.0.101:52938->40.113.87.220:https
Skype TCP 192.168.0.101:53091->40.113.87.220:https
Skype TCP 192.168.0.101:53092->40.113.87.220:https
```

这种简单，不保证可靠性的协议有强大的适应性，在大部分网络环境都是适用的。在工程中，人们会将它和TCP混合适用，在诸如视频，语音的传输中，小规模的丢包，失序都是可以接受的，毕竟还有人类大脑这样的高级处理器负责纠正那些网络错误。

### 处理失败的模式

#### 超时机制

对于网络上的第三方依赖，你无法预料它的响应延迟是什么样子的，它可能每秒钟可以处理10000次请求而游刃有余，也可能在处理100个并发时就会无限期阻塞，你需要为这种情况有所准备。

`nginx`通常被用作一个网关，它总是处于请求的最前端，因此其中有很多关于超时的设置：

```
location /api {
  proxy_pass http://api.backend;
  proxy_connect_timeout 500s;
  proxy_read_timeout 500s;
  proxy_send_timeout 500s;

  proxy_set_header        X-Real-IP $remote_addr;
  proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header        Host $http_host;
 }
```

比如上面`/api`这个虚拟host中就有连接超时，读超时，后端写超时等设置。在实际环境中，`Fail Fast`是对无法预料错误的**最好**处理方法。缓慢的处理会阻塞其他请求，并很快堆积，然后耗尽系统资源。


系统超时配置只是一部分，在你自己的代码中也应该为所有网络依赖加上合适的超时机制：

```java
public Observable<Staff> fetchUserByName(String name) {
    String url = JIGSAW_ENDPOINT + name;

    Client client = ClientBuilder.newClient(new ClientConfig());
    client.property(ClientProperties.CONNECT_TIMEOUT, 10);
    client.property(ClientProperties.READ_TIMEOUT,    10);

    Invocation.Builder request = client.target(url).request(MediaType.APPLICATION_JSON);

    Observable<Staff> staff;

    try {
        staff = Observable.just(request.get(Staff.class));
    } catch (Exception ex) {
        staff = Observable.just(null);
    }

    return staff;
}
```

#### 回退机制

如果应用程序无法获得正常的响应，那么提供优雅的回退机制在大多数情况下是必须的，而且这样做通常也不会很复杂。以Netflix的`Hystrix`库为例，如果一个异步命令失败（比如网络异常，超时等），它提供`Fallback`机制来返回客户端一个默认实现（或者一份本地缓存中的数据）。

```java
@HystrixCommand(fallbackMethod = "getDefaultStaffInfo")
public Staff getStaffInfo(String loginName) {
	//fetch from remote server
}

public Staff getDefaultStaffInfo(String loginName) {
	return new Staff();
}
```

#### 熔断器

![Circuit Breaker](/images/2016/05/circuit_breaker.jpg)

熔断器模式指当应用在依赖方响应过慢或者出现很多超时时，调用方主动熔断，这样可以防止对依赖方造成更严重的伤害。过一段时间之后，调用方会以较慢的速度开始重试，如果依赖方已经恢复，则逐步加大负载，直到恢复正常调用。如果依赖方还是没有就绪，那就延长等待时间，然后重试。这种模式使得系统在某种程度上显现出动态性和智能。

Netflix的Hystrix库已经提供了这种能力，事实上，如果你使用Spring Cloud Netfilx，这个功能是内置在系统中的，你只需要一些注解就可以让系统具备这样的能力：

```java
@SpringBootApplication
@EnableCircuitBreaker
public class Application {

    public static void main(String[] args) {
    	SpringApplication.run(Application.class, args);
    }

}
```

如果5秒内连续失败了20次，Hystrix会进入`熔断`模式，后续的请求不会再发送。过一段时间之后，Hystrix又会逐步尝试恢复负载。

### 后记

扩展阅读：

-  [《发布！软件的设计与部署》](https://book.douban.com/subject/26304417/)
-  [《反脆弱》](https://book.douban.com/subject/24838618/)

技术文章：

-  [Spring Cloud & Docker](http://www.kennybastani.com/2015/07/spring-cloud-docker-microservices.html)
-  [Build Cloud Native Apps](http://ryanjbaxter.com/2015/10/12/building-cloud-native-apps-with-spring-part-5/)