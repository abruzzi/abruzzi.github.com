---
layout: post
title: "保护你的API（上）"
date: 2016-05-10 19:12
comments: true
categories: 
- Spring
- Security
- RESTful
---

## 保护你的API

在大部分时候，我们讨论API的设计时，会从功能的角度出发定义出完善的，易用的API。而很多时候，非功能需求如安全需求则会在很晚才加入考虑。而往往这部分会涉及很多额外的工作量，比如与外部的SSO集成，Token机制等等。

这篇文章会以一个简单的例子，从应用程序和部署架构上分别讨论几种常见的模型。这篇文章是这个系列的第一篇，会讨论两个简单的主题：

-  基于Session的用户认证
-  基于Token的RESTful API（使用Spring Security）

### 使用Session

由于HTTP协议本身是无状态的，服务器需要某种机制来区分每个请求。比如在返回给客户的响应中加入一些ID，客户端再次请求时带上这个ID，这样服务器就可以区分出来每个请求，并完成事务性的操作（完成订单的创建，更新，商品派送等等）。

在多数Web容器中，这种机制通过Session来实现。Web容器会为每个首次请求创建一个Session，并将Session的ID以浏览器Cookie的方式返回给客户端。客户端（常常是浏览器）在后续的请求中带上这个Session的ID来表明自己的身份。这种机制同样被用在了鉴权方面，用户登录系统之后，系统分配一个Session ID给他。

除非Session过期，或者用户从客户端的Cookie中主动删了Session ID，否则在服务器端来看，用户的信息会和这个Session绑定起来。后台系统也可以随时知道请求某个资源的真实用户是谁，并以此来判断该用户时候真的有权限这么做。

```java
HttpSession session = request.getSession();
String user = (String)session.getAttribute("user");

if(user != null) {
    //
}
```

#### Session的问题

这种做法在小规模应用中工作良好，随着用户的增多，企业往往需要部署多台服务器形成集群来对外提供服务。在集群模式下，当某个节点挂掉之后，由于Session默认是保存在部署Web容器中的，用户会被误判为未登录，后续的请求会被重定向到登陆页面，影响用户体验。

这种将应用程序状态内置的方法已经完全无法满足应用的扩展，因此在工程实践中，我们会采用将Session外置的方式来解决这个问题。即集群中的所有节点都将Session保存在一个公用的键值数据库中：

```java
@Configuration
@EnableRedisHttpSession
public class HttpSessionConfig {
}
```

上面这个例子是在Spring Boot中使用Redis来外置Session。Spring会拦截所有对HTTPSession对象的操作，后续的对Session的操作，Spring都会自动转换为与后台的Redis服务器的交互，从而避免节点挂掉之后Session丢失的问题。

```java
spring.redis.host=192.168.99.100
spring.redis.password=
spring.redis.port=6379
```

如果你跟我一样懒的话，直接启动一个redis的docker container就可以：

```sh
$ docker run --name redis-server -d redis
```

这样，多个应用共享这一个实例，任何一个节点的终止、异常都不会产生Session的问题。

### 基于Token的安全机制

上面说到的场景中，使用Session需要额外部署一个组件（或者引入更加复杂的Session同步机制），这会带来另外的问题，比如如何保证这个节点的高可用，除了Production环境之外，Staging和QA环境也需要这个组件的配置、测试和维护。

很多项目现在会采用另外一种更加简单的方式：基于Token的安全机制。即不使用Session，用户在登陆之后，会获得一个Token，这个Token会以HTTP Header的方式发送给客户，同样，客户再后续的资源请求中也需要带着这个Token。通常这个Token还会有过期时间的限制（比如只能使用1周，一周之后需要重新获取）。

基于Token的机制更加简单，和RESTful风格的API一起使用更加自然，相较于传统的Web应用，RESTful的消费者可能是人，也可能是Mobile App，也可能是系统中另外的Service。也就是说，并不是所有的消费者都可以处理一个登陆表单！

#### Restful API

我们通过一个实例来看使用Spring Security保护受限制访问资源的场景。

对于Controller：

```java
@RestController
@RequestMapping("/protected")
public class ProtectedResourceController {

    @RequestMapping("/{id}")
    public Message getOne(@PathVariable("id") String id) {
        return new Message("Protected resource "+id);
    }
}
```

我们需要所有请求上都带有一个`X-Auth-Token`的Header，简单起见，如果这个Header有值，我们就认为这个请求已经被授权了。我们在Spring Security中定义这样的一个配置：

```java
@Override
protected void configure(HttpSecurity http) throws Exception {
    http.
            csrf().disable().
            sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS).
            and().
            authorizeRequests().
            anyRequest().
            authenticated().
            and().
            exceptionHandling().
            authenticationEntryPoint(new RestAuthenticationEntryPoint());
}
```

我们使用`SessionCreationPolicy.STATELESS`无状态的Session机制（即Spring不使用HTTPSession），对于所有的请求都做权限校验，这样Spring Security的拦截器会判断所有请求的Header上有没有"X-Auth-Token"。对于异常情况（即当Spring Security发现没有），Spring会启用一个认证入口：`new RestAuthenticationEntryPoint`。在我们这个场景下，这个入口只是简单的返回一个401即可：

```java
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException ) throws IOException {
        response.sendError( HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized" );
    }
}
```

这时候，如果我们请求这个受限制的资源：

```sh
$ curl http://api.kanban.com:9000/api/protected/1 -s | jq .
{
  "timestamp": 1462621552738,
  "status": 401,
  "error": "Unauthorized",
  "message": "Unauthorized",
  "path": "/api/protected/1"
}
```

#### 过滤器（Filter）及预认证（PreAuthentication）

为了让Spring Security可以处理用户登录的case，我们需要提供一个`Filter`。当然，Spring Security提供了丰富的`Filter`机制，我们这里使用一个预认证的`Filter`（即假设用户已经在别的外部系统如SSO中登录了）:

```java
public class KanBanPreAuthenticationFilter extends AbstractPreAuthenticatedProcessingFilter {
    public static final String SSO_TOKEN = "X-Auth-Token";
    public static final String SSO_CREDENTIALS = "N/A";

    public KanBanPreAuthenticationFilter(AuthenticationManager authenticationManager) {
        setAuthenticationManager(authenticationManager);
    }

    @Override
    protected Object getPreAuthenticatedPrincipal(HttpServletRequest request) {
        return request.getHeader(SSO_TOKEN);
    }

    @Override
    protected Object getPreAuthenticatedCredentials(HttpServletRequest request) {
        return SSO_CREDENTIALS;
    }
}
```

过滤器在获得Header中的Token后，Spring Security会尝试去认证用户：

```java
@Override
protected void configure(AuthenticationManagerBuilder builder) throws Exception {
    builder.authenticationProvider(preAuthenticationProvider());
}

private AuthenticationProvider preAuthenticationProvider() {
    PreAuthenticatedAuthenticationProvider provider = new PreAuthenticatedAuthenticationProvider();
    provider.setPreAuthenticatedUserDetailsService(new KanBanAuthenticationUserDetailsService());

    return provider;
}
```

这里的`KanBanAuthenticationUserDetailsService`是一个实现了Spring Security的UserDetailsService的类：

```java
public class KanBanAuthenticationUserDetailsService
        implements AuthenticationUserDetailsService<PreAuthenticatedAuthenticationToken> {

    @Override
    public UserDetails loadUserDetails(PreAuthenticatedAuthenticationToken token) throws UsernameNotFoundException {
        String principal = (String) token.getPrincipal();

        if(!StringUtils.isEmpty(principal)) {
            return new KanBanUserDetails(new KanBanUser(principal));
        }

        return null;
    }
}
```

这个类的职责是，查看从`KanBanPreAuthenticationFilter`返回的`PreAuthenticatedAuthenticationToken`，如果不为空，则表示该用户在系统中存在，并正常加载用户。如果返回null，则表示该认证失败，这时根据配置，Spring Security会重定向到认证入口`RestAuthenticationEntryPoint`。

加上这个过滤器的配置之后：

```java
@Override
protected void configure(HttpSecurity http) throws Exception {
    //...
    http.addFilter(headerAuthenticationFilter());
}

@Bean
public KanBanPreAuthenticationFilter headerAuthenticationFilter() throws Exception {
    return new KanBanPreAuthenticationFilter(authenticationManager());
}
```

这样，当我们在Header上加上`X-Auth-Token`之后，就会访问到受限的资源了：

```sh
$ curl -H "X-Auth-Token: juntao" http://api.kanban.com:9000/api/protected/1 -s | jq .
{
  "content": "Protected resource for 1"
}
```

### 总结

下一篇文章会以另外一个方式来完成鉴权机制和系统的集成问题。我们会在反向代理中做一些配置，将多个Endpoint组织起来。要完成这样的功能，使用Spring Security也可以做到，不过可能会为应用程序本身引入额外的复杂性。