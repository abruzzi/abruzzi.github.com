---
layout: post
title: "保护你的API（下）"
date: 2016-05-12 22:50
comments: true
categories: 
- Spring
- Nginx
- Ruby
- Integration
---

## 前后端分离之后

前后端分离之后，在部署上通过一个反向代理就可以实现动静态分离，跨域问题的解决等。但是一旦引入鉴权，则又会产生新的问题。通常来说，鉴权是对于后台API/API背后的资源的保护，即**未经授权的用户不能访问受保护资源**。

要实现这个功能有很多种方式，在应用程序之外设置完善的安全拦截器是最常见的方式。不过有点不够优雅的是，一些不太纯粹的、非功能性的代码和业务代码混在同一个代码库中。

另一方面，各个业务系统都可能需要某种机制的鉴权，所以很多企业都会搭建SSO机制，即[Single Sign-On](https://en.wikipedia.org/wiki/Single_sign-on)。这样可以避免人们在多个系统创建不同账号，设置不同密码，不同的超时时间等等。如果SSO系统已经先于系统存在了很久，那么新开发的系统完全不需要自己再配置一套用户管理机制了（一般SSO只会完成**鉴权**中**鉴别**的部分，**授权**还是需要各个业务系统自行处理）。

本文中，我们使用基础设施（反向代理）的一些配置，来完成**保护未授权资源**的目的。在这个例子中，我们假设系统由这样几个服务器组成：

### 系统组成

这个实例中，我们的系统分为三部分

1.  `kanban.com:8000`（业务系统前端）
1.  `api.kanban.com:9000`（业务系统后端API）
1.  `sso.kanban.com:8100` （单点登录系统，登陆界面）

前端包含了HTML/JS/CSS等资源，是一个纯静态资源，所以本地磁盘即可。后端API则是一组需要被保护的API（比如查询工资详情，查询工作经历等）。最后，单点登录系统是一个简单的表单，用户填入用户名和密码后，如果登录成功，单点登录会将用户重定向到登录前的位置。

我们举一个具体场景的例子：

1.  未登录用户访问`http://kanba.com:8000/index.html`
1.  系统会重定向用户到`http://sso.kanban.com:8100/sso?return=http://kanba.com:8000/index.html`
1.  用户看到登录页面，输入用户名、密码登录
1.  用户被重定向回`http://kanba.com:8000/index.html`
1.  此外，`index.htm`l页面上的`app.js`对`api.kanban.com:9000`的访问也得到了授权

#### 环境设置

简单起见，可以通过修改/etc/hosts文件来设置服务器环境：

```
127.0.0.1 sso.kanban.com
127.0.0.1 api.kanban.com
127.0.0.1 kanban.com
```

### nginx及auth_request

反向代理nginx有一个auth_request的模块。在一个虚拟host中，每个请求会先发往一个内部`location`，这个内部的`location`可以指向一个可以做鉴权的Endpoint。如果这个请求得到的结果是200，那么nginx会返回用户本来请求的内容，如果返回401，则将用户重定向到一个预定义的地址：

```
server {
    listen 8000;
    server_name kanban.com;

    root /usr/local/var/www/kanban/;

    error_page 401 = @error401;

    location @error401 {
        return 302 http://sso.kanban.com:8100/sso?return=$scheme://$http_host$request_uri;
    }

    auth_request /api/auth;

    location = /api/auth {
        internal;

        proxy_pass http://api.kanban.com:9000;

        proxy_pass_request_body     off;

        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        if ($http_cookie ~* "w3=(\w+)") {
            set $token "$1";
        }

        proxy_set_header X-KANBAN-TOKEN $token;
    }
}
```

比如上面这个例子中，`auth_request`的URL为`/api/auth`，它是一个内部的location，外部无法访问。在这个`locaiton`中，请求会被转发到`http://api.kanban.com:9000`，根据nginx的正则语法，请求将会被转发到`http://api.kanban.com:9000/api/auth`（我们随后可以看到这个Endpoint的定义）。

我们设置了请求的原始头信息，并禁用了request_body，如果cookie中包含了`w3=(\w+)`字样，则将这个w3的值抽取出来，并赋值给一个`X-KANBAN-TOKEN`的HTTP头。

#### 权限Endpoint

对应的`/api/auth`的定义如下：

```java
@RestController
@RequestMapping("/auth")
public class AuthController {

    @RequestMapping
    public ResponseEntity<String> simpleAuth(@RequestHeader(value="X-KANBAN-TOKEN", defaultValue = "") String token) {
        if(StringUtils.isEmpty(token)) {
            return new ResponseEntity<>("Unauthorized", HttpStatus.UNAUTHORIZED);
        } else {
            return new ResponseEntity<>("Authorized", HttpStatus.OK);
        }
    }
}
```

如果HTTP头上有`X-KANBAN-TOKEN`且值不为空，则返回200，否则返回401。

当这个请求得到401之后，用户被重定向到`http://sso.kanban.com:8100/sso`

```
error_page 401 = @error401;

location @error401 {
    return 302 http://sso.kanban.com:8100/sso?return=$scheme://$http_host$request_uri;
}
```

### SSO组件（简化版）

这里用`sinatra`定义了一个简单的SSO服务器（去除了实际的校验部分）

```ruby
require 'sinatra'
require 'uri'

set :return_url, ''
set :bind, '0.0.0.0'

get '/sso' do
    settings.return_url = params[:return]
    send_file 'public/index.html'
end

post '/login' do
	credential = params[:credential]
	# check credential against database
	uri = URI.parse(settings.return_url)
	response.set_cookie("w3", {
		:domain => ".#{uri.host}",
	    :expires => Time.now + 2400,
	    :value => "#{credential['name']}",
	    :path => '/'
  	})
	redirect settings.return_url, 302
end
```

`/sso`对应的Login Form是：

```html
<form action="/login" method="post">
	<input type="text" name="credential[name]" />
	<input type="password" name="credential[password]" />
	<input type="submit">
</form>
```

当用户提交表单之后，我们只是简单的设置了`cookie`，并重定向用户到跳转前的URL。

### 前端页面

这个应用的前端应用非常简单，我们只需要将这些静态文件放到`/usr/local/var/www/kanban`目录下：

```
$ tree /usr/local/var/www/kanban

├── index.html
└── scripts
    ├── app.js
    └── jquery.min.js
```

其中`index.html`中引用的`app.js`会请求一个受保护的资源：

```js
$(function() {
	$.get('/api/protected/1').done(function(message) {
		$('#message').text(message.content);
	});
});
```

从下图中的网络请求可以看到重定向的流程：

![redirection](/images/2016/05/redirection-resized.png)

### 总结

本文我们通过配置反向代理，将多个Endpoint组织起来。这个过程可以在应用程序中通过代码实现，也可以在基础设施中通过配置实现，通常来讲，如果可以通过配置来实现的，就尽量将其与负责业务逻辑的代码隔离出来。这样可以保证各个组件的独立性，也可以使得优化和定位问题更加容易。

完整的代码可以在这里下载：

-  [Fake SSO](https://github.com/abruzzi/fake-sso)
-  [Spring Security Demo](https://github.com/abruzzi/spring-security-demo)