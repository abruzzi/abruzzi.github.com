---
layout: post
title: "微服务中的自动化测试"
date: 2016-10-01 18:49
comments: true
categories: 
-  Testing
-  Microservice
-  Automation
---
## 新的挑战

微服务和传统的单块应用相比，在测试策略上，会有一些不太一样的地方。简单来说，在微服务架构中，测试的层次变得更多，而且对环境的搭建要求更高。比如对单块应用，在一个机器上就可以setup出所有的依赖，但是在微服务场景下，由于依赖的服务往往很多，要搭建一个完整的环境非常困难，这对团队的`DevOps`的能力也有比较高的要求。

相对于单块来说，微服务架构具有以下特点：

-  每个微服务在物理上分属不同进程
-  服务间往往通过`RESTful`来集成
-  多语言，多数据库，多运行时
-  网络的不可靠特性
-  不同的团队和交付周期

上述的这些微服务环境的特点，决定了在微服务场景中进行测试自然会面临的一些挑战：

-  服务间依赖关系复杂
-  需要为每个不同语言，不同数据库的服务搭建各自的环境
-  端到端测试时，环境准备复杂
-  网络的不可靠会导致测试套件的不稳定
-  团队之间的`沟通成本`

### 测试的分层

相比于常见的[三层测试金字塔](https://www.mountaingoatsoftware.com/blog/the-forgotten-layer-of-the-test-automation-pyramid)，在微服务场景下，这个层次可以被扩展为5层（如果将UI测试单独抽取出来，可以分为六层）。

-  单元测试
-  集成测试
-  组件测试
-  契约测试
-  端到端测试

![Test layers](/images/2016/10/microservice-testing-zhcn-resized.png)

和测试金字塔的基本原则相同：

1.  越往上，越接近业务/最终用户；越往下，越接近开发
1.  越往上，测试用例越少
1.  越往上，测试成本越高（越耗时，失败时的信息越模糊，越难跟踪）

#### 单元测试

单元测试，即每个微服务内部，对于领域对象，领域逻辑的测试。它的隔离性比较高，无需其他依赖，执行速度较快。

对于业务规则：

1.  商用软件需要License才可以使用，License有时间限制
1.  需要License的软件在到期之前，系统需要发出告警

```java
@Test
public void license_should_expire_after_the_evaluation_period() {
    LocalDate fixed = getDateFrom("2015-09-03");
    License license = new License(fixed.toDate(), 1);

    boolean isExpiredOn = license.isExpiredOn(fixed.plusYears(1).plusDays(1).toDate());
    assertTrue(isExpiredOn);
}

@Test
public void license_should_not_expire_before_the_evaluation_period() {
    LocalDate fixed = getDateFrom("2015-09-05");
    License license = new License(fixed.toDate(), 1);

    boolean isExpiredOn = license.isExpiredOn(fixed.plusYears(1).minusDays(1).toDate());
    assertFalse(isExpiredOn);
}
```

上面这个例子就是一个非常典型的单元测试，它和其他组件基本上没有依赖。即使要测试的对象对其他类有依赖，我们会Stub/Mock的手段来将这些依赖消除，比如使用[mockito](http://mockito.org/)/[PowerMock](https://github.com/jayway/powermock)。

#### 集成测试

系统内模块（一个模块对其周边的依赖项）间的集成，系统间的集成都可以归类为集成测试。比如

-  数据库访问模块与数据库的集成
-  对外部`service`依赖的测试，比如对第三方支付，通知等服务的集成

集成测试强调模块和外部的交互的验证，在集成测试时，通常会涉及到外部的组件，比如数据库，第三方服务。这时候需要尽可能真实的去与外部组件进行交互，比如使用和真实环境相同类型的数据库，采用独立模式（Standalone）的[WireMock](http://wiremock.org/)来启动外部依赖的RESTful系统。

通常会用来做模拟外部依赖工具包括：

-  [WireMock](http://wiremock.org/)
-  [mountebank](http://www.mbtest.org/)

其中，mountbank还支持Socket级别的Mock，可以在非HTTP协议的场景中使用。

![Integration Test](/images/2016/10/1905-funcional-teamwork.jpg)

#### 组件测试

贯穿应用层和领域层的测试。不过通常来说，这部分的测试不会访问真实的外部数据源，而是使用同`schema`的内存数据库，而且对外部service的访问也会使用Stub的方式：

-  内存数据库
-  Stub外部服务（[WireMock](http://wiremock.org/)）
-  [RestAssured](https://github.com/rest-assured/rest-assured)

比如使用[h2](http://www.h2database.com/html/main.html)来做内存数据库，并且自动生成schema。使用WireMock来Stub外部的服务等。

```java
@Test
public void should_create_user() {
    given().contentType(ContentType.JSON).body(prepareUser()).
            when().post("/users").
            then().statusCode(201).
            body("id", notNullValue()).
            body("name", is("Juntao Qiu")).
            body("email", is("juntao.qiu@gmail.com"));
}

private User prepareUser() {
    User user = new User();
    user.setName("Juntao Qiu");
    user.setEmail("juntao.qiu@gmail.com");
    user.setPassword("password");
    return user;
}
```

如果使用Spring，还可以通过`profile`来切换不同的数据库。比如下面这个例子中，默认的profile会连接数据库`jigsaw`，而`integration`的profile会连接`jigsaw_test`数据库：

```
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/jigsaw
    driver-class-title: com.mysql.jdbc.Driver
    username: root
    password: password

---

spring:
  profiles: integration

  datasource:
    url: jdbc:mysql://localhost:3306/jigsaw_test
    driver-class-title: com.mysql.jdbc.Driver
    username: root
    password: password
```

组件测试会涉及到的组件包括：

-  URL路由
-  序列化与反序列化
-  应用对领域层的访问
-  领域层对数据的访问
-  数据库访问层

##### 前后端分离

除了后端的测试之外，在目前的前后端分离场景下，前端的应用越来越复杂，在这种情况下，前端的组件测试也是一个测试的重点。

一个前端应用至少包括了这样一些组件：

-  前端路由
-  模板
-  前端的MVVM
-  拦截器
-  事件的响应

要确保这些组件组合起来还能如预期的执行，相关测试必不可少。[这篇文章](http://icodeit.org/2015/06/whats-next-after-separate-frontend-and-backend/)详细讨论了前后端分离之后的测试及开发实践。

#### 契约测试

在微服务场景中，服务之间会有很多依赖关系。根据`消费者驱动契约`，我们可以将服务分为消费者端和生产者端，通常消费者自己会定义需要的数据格式以及交互细节，并生成一个契约文件。然后生产者根据自己的契约来实现自己的逻辑，并在持续集成环境中持续验证。

[Pact](https://github.com/realestate-com-au/pact)已经基本上是`消费者驱动契约`（Consumer Driven Contract）的事实标准了。它已经有多种语言的实现，Java平台的可以使用`pact-jvm`及相应的`maven`/`gradle`插件进行开发。

-  [pact](https://github.com/realestate-com-au/pact)/[pact-jvm](https://github.com/DiUS/pact-jvm)
-  [pact-broker](https://github.com/bethesque/pact_broker)

![pact example](/images/2016/10/pactExample-resized.png)

(图片来源：[Why you should use Consumer-Driven Contracts for Microservice integration tests](http://techblog.newsweaver.com/why-should-you-use-consumer-driven-contracts-for-microservices-integration-tests/))

通常在工程实践上，当消费者根据需要生成了契约之后，我们会将契约上传至一个公共可访问的地址，然后生产者在执行时会访问这个地址，并获得最新版本的契约，然后对着这些契约来执行相应的验证过程。

一个典型的契约的片段是这样的（使用pact）：

```json
"interactions": [
    {
        "description": "Project Service",
        "request": {
            "method": "GET",
            "path": "/projects/11046"
        },
        "response": {
            "status": 200,
            "headers": {
                "Content-Type": "application/json; charset=UTF-8"
            },
            "body": {
                "project-id": "004c97"
            },
            "matchingRules": {
                "$.body.project-id": {
                    "match": "type"
                }
            }
        },
        "providerState": "project service"
    }
]
```

#### 端到端测试

端到端测试是整个微服务测试中最困难的，一个完整的环境的创建于维护可能需要花费很大的经历，特别是当有多个不同的团队在独立开发的场景下。

另一方面，从传统的测试金字塔来看，端到端测试应该覆盖那些业务价值最高的Happy Path。也就是说，端到端测试并不关注异常场景，甚至大部分的业务场景都不考虑。要做到这一点，需要在设计测试时，从最终用户的角度来考虑，通过`用户画像`和`User Journey`来确定测试场景。

在端到端测试中，最重要的反而不是测试本身，而是环境的自动化能力。比如可以通过一键就可以将整个环境`provision`出来：

-  安装和配置相关依赖
-  自动将测试数据Feed到数据库
-  自动部署
-  服务的自动重启

随着容器技术和容器的编排技术的成熟，这部分工作已经可以比较好的自动化，依赖的工具包括：

-  [Docker](https://www.docker.com/)
-  [Rancher](http://rancher.com/)

一个典型的流程是：

1.  搭建持续发布流水线
1.  应用代码的每一次提交都可以构建出docker镜像
1.  将docker镜像发布在内部的docker-hub上
1.  触发部署任务，通过rancher的upgrade命令将新的镜像发布
1.  执行端到端测试套件

端到端测试还可以细分为两个不同的场景：

-  没有用户交互的场景，如一系列的微服务组成了一个业务API
-  有用户交互的场景

##### UI测试

最顶层的UI测试跟传统方式的UI测试并无二致。我们可以使用BDD与实例化需求（[Specification By Example](https://books.gojko.net/specification-by-example/)）的概念，从用户使用的角度来描述需求，以及相关的验收条件。这里我们会使用WebDriver来驱动浏览器，并通过诸如[Capybara](https://github.com/jnicklas/capybara)等工具来模拟用户的操作。

-  BDD工具：[Cucumber](https://cucumber.io/)
-  Web应用验收测试工具：[Capybara](https://github.com/jnicklas/capybara)
-  Page Object的DSL工具：[Site_prism](https://github.com/natritmeyer/site_prism)

### 扩展阅读

-  [产品环境下的QA](http://www.infoq.com/cn/articles/QA-in-Production-practice)
-  [醒醒吧少年，只用Cucumber不能帮助你BDD](http://insights.thoughtworkers.org/bdd/)
-  [Testing Strategies in a Microservice Architecture](http://martinfowler.com/articles/microservice-testing/)
-  [编写体面的UI测试](http://icodeit.org/2015/01/page-object-with-site-prism/)

