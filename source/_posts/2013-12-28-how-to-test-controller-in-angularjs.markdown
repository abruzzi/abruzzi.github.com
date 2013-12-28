---
layout: post
title: "如何测试AngularJS中的Controller"
date: 2013-12-28 17:40
comments: true
categories: 
- JavaScript
- AngularJS
- Test
- Jasmine

---

### AngularJS中的一个典型的Controller

在AngularJS中，Controller主要用于hold一些跟view的有关的状态，以及数据模型，比如界面上某些元素是否展示，以及展示那些内容等。通常来说，Controller会依赖与一个Service来提供数据：

```js
app.controller('EventController', ['$scope', 'EventService',
	function($scope, EventService) {
		EventService.getEvents().then(function(events) {
			$scope.events = events;
		});
	}]);

```

而service本身则需要通过向后台服务发送请求来获取数据：

```js
app.factory('EventService', ['$http', '$q',
	function($http, $q) {
		return {
			getEvents: function() {
				var deferred = $q.defer();

				$http.get('/events.json').success(function(result) {
					deferred.resolve(result);
				}).error(function(result) {
					deferred.reject(result);
				});

				return deferred.promise;
			}
		};
	}]);
```

通常的做法是返回一个[promise](http://docs.angularjs.org/api/ng.$q)对象，然后当数据准备完整之后，controller的then会被执行。

那么对于这种情况（在AngularJS中，算是一个非常典型的场景），我们如何进行单元测试呢？

### 测试依赖与Service的Controller
通常来讲，在单元级别的测试中，我们肯定不希望Service真正的发送请求，这样就变成了集成测试，而且前端的开发完全依赖与后台的开发进度/稳定程度等。

所以我们需要做一个假的Service，这个假的Service仅仅在测试中存在：

```js

var app = angular.module('MyApp');

describe("EventController", function() {
	var scope, q;
	var controllerFactory;
	var mockSerivce = {};

	var events = ["Event1", "Event2", "Event3"];

	beforeEach(function() {
		module("MyApp");
		inject(function($rootScope, $controller, $q) {
			controllerFactory = $controller;
			scope = $rootScope.$new();
			q = $q;
		});
	});

	beforeEach(function() {
		var deferred = q.defer();
		deferred.resolve(events);
		mockSerivce.getEvents = jasmine.createSpy('getEvents');
		mockSerivce.getEvents.andReturn(deferred.promise);
	});

	function initController() {
		return controllerFactory('EventController', {
			$scope: scope,
			EventService: mockSerivce
		});
	}

	it("should have a events list", function() {
		initController();
		scope.$digest();
		expect(scope.events.length).toEqual(3);
		expect(scope.events).toEqual(events);
	});
});
```

此处有很多值得注意的事情：

#### 在何处实例化Controller

不要在注入`beforeEach`中初始化Controller，很多示例中都会在注入了`$controller`之后紧接着实例化Controller，如果Controller有多个外部的依赖的话，那么在`beforeEach`中的代码将越来越多，而且读每一个测试用例时会有一些疑惑。

一个好的做法是将依赖注入到`describe`中的临时变量中，然后将初始化的动作延后到一个函数中：

```js
function initController() {
	return controllerFactory('EventController', {
		$scope: scope,
		EventService: mockSerivce
	});
}
```

#### 如何mock一个service

由于在AngularJS中，Service一般会返回一个[promise](http://docs.angularjs.org/api/ng.$q)对象。因此在测试时需要有一些技巧来绕过：

```js
var events = ["Event1", "Event2", "Event3"];

beforeEach(function() {
	var deferred = q.defer();
	deferred.resolve(events);
	mockSerivce.getEvents = jasmine.createSpy('getEvents');
	mockSerivce.getEvents.andReturn(deferred.promise);
});
```

这样，当使用注入`EventService.getEvents().then(callback)`的地方就可以访问到此处的promise对象了。

如果添加了新的用例，

```js
app.controller('EventController', ['$scope', 'EventService',
	function($scope, EventService) {
		EventService.getEvents().then(function(events) {
			$scope.events = events;
			$scope.recentEvent = $scope.events[0];
		});
	}]);
```

则在用例开始完成创建Controller的动作即可：

```js
it("should have a recent event", function() {
	initController();
	scope.$digest();
	expect(scope.recentEvent).toEqual("Event1");
});
```


完整的代码[请看此处](https://github.com/abruzzi/angularjs-controller-demo)

