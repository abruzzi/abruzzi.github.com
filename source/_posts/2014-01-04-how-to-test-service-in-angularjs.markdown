---
layout: post
title: "如何测试AngularJS中的Service"
date: 2014-01-04 14:22
comments: true
categories: 
- JavaScript
- AngularJS
- Jasmine
- Test

---

### Service的典型示例
在AngularJS中，Service都是单例的实体，通常会将Service作为向后台交互的数据提供者，所有的需要数据的组件只需要依赖于这个Service即可。

```js

var app = angular.module('MyApp', []);

app.factory('SearchSettingService', 
    ['$http', '$q', function($http, $q) {
    return {
        setting: function() {
            var deferred = $q.defer();
            
            $http.get('/settings.json').success(function(result) {
                deferred.resolve(result);
            }).error(function(result) {
                deferred.reject("network error");
            });

            return deferred.promise;
        }
    };
}]);

```

#### $httpBackend

测试的时候，我们不需要真实的发送HTTP请求来获取数据。如果可以只测试Service的逻辑，当发送请求时，我们将这个请求拦截下来，然后返回一个预定义好的数据即可：

```js
it('should have settings from http request', function() {
    var result;
    var expected = {
        "period": "day",
        "date": "Sat Dec 21 12:56:53 EST 2013",
    };

    httpBackend.expectGET('/settings.json').respond(expected);

    var promise = settingService.setting();
    promise.then(function(data) {
        result = data;
    });

    httpBackend.flush();

    expect(result).toEqual(expected);
});
```

$httpBackend是AngularJS提供的一个测试用的服务，可以在spec中注入进来：

```js
beforeEach(function() {
    module('services');

    inject(function(SearchSettingService, $httpBackend) {
        settingService = SearchSettingService;
        httpBackend = $httpBackend;
    });
});
```

`httpBackend`服务有一些很方便测试的方法：

```js
httpBackend.expectGET(url).respond(data);
httpBackend.expectPOST(url, param).respond(data);
```

设置之后，当调用`httpBackend.flush`时，AngularJS会调用这个setup，发送的请求会被之前的setup拦截并返回，这样service中的数据就被填充好了。

#### Service测试的模板

或者说，当测试一个Service时，我们应该测那些方面呢？

1.	正常流程，一个完整的处理过程
2.	异常处理，如果服务器出错了，程序需要如何反馈？
3.	其他异常情况

正常流程很容易，在调用service提供的方法之后，在获得的promise对象上调用then方法来填充一个数据即可，然后调用`httpBackend.flush()`来**发送**请求，最后验证数据的格式/内容是否正确。

这个测试的主要目的是验证当调用service的方法时，service真实的发送了一个http请求：

```js
it('should have settings from http request', function() {
    var result;
    var expected = {
        "period": "day",
        "date": "Sat Dec 21 12:56:53 EST 2013",
    };

    httpBackend.expectGET('/settings.json').respond(expected);

    var promise = settingService.setting();
    promise.then(function(data) {
        result = data;
    });

    httpBackend.flush();

    expect(result).toEqual(expected);
});
```

对于异常的情况，比如服务器返回了错误，如`500`，那么最低程度，程序应该可以处理这个异常：

```js
it("should throw error when network expection", function() {
    var result, error;
    httpBackend.expectGET('/settings.json').respond(500);

    var promise = settingService.setting();
    promise.then(function(data) {
        result = data;
    }, function(data) {
        error = data;
    });

    httpBackend.flush();

    expect(result).toBeUndefined();
    expect(error).toEqual("network error");
});
```

#### *服务器* moco

[moco](https://github.com/dreamhead/moco)是同事[郑晔](http://dreamhead.blogbus.com/)开发的一个测试框架/工具，基本上来说，moco是一个用来集成测试的用的HTTP服务器。

你可以通过API方式或者启动moco服务器的方式来使用它，我比较喜欢将moco作为一个独立的服务器来使用：

```sh
java -jar moco-runner-0.9-standalone.jar start -p 12306 -c moco.conf.json
```

比如`moco.conf.json`中定义了一下规则：

```js
[
    {
        "request": {
            "method": "post",
            "uri": "/resource"
        },
        "response": {
            "status": 201,
            "text": "resource has been created"
        }
    },
    {
        "request": {
            "uri": "/resource"
        },
        "response": {
            "status": 200,
            "file": "resources.json"
        }
    }
]
```

则启动moco的服务器之后，所有发往`/resource`的`post`请求都会得到

```
201
resource has been created
```

的HTTP响应，这个功能在前端开发越来越独立的情况下变得非常好用。我最近在有很多小项目中都在尝试moco，非常的好用，后边会有相关的博客专门介绍。

