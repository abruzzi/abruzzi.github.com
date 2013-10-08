---
layout: post
title: "Grunt的几个常用插件"
date: 2013-10-08 16:42
comments: true
categories: 
- JavaScript
- Lightweight

---

### Grunt的几个常用插件

#### grunt-karma 简介

[grunt-karma](https://github.com/karma-runner/grunt-karma)是一个karma的Grunt插件，[上一篇文章](http://icodeit.org/2013/10/using-karma-as-the-javascript-test-runner/)中已经介绍了karma的基本用法。这里简单介绍如何在Grunt中使用karma。

首先需要安装grunt-karma插件：

```
$ npm install grunt-karma --save-dev
```

然后在Gruntfile.js中加载该插件：

```
grunt.loadNpmTasks('grunt-karma');
```

在使用karma之前，需要生成一个karma的配置文件`karma.conf.js`:

```
$ karma init karma.conf.js
```

然后在Gruntfile.js中，加入初始化karma的参数，并指定，karma需要使用`karma.conf.js`文件作为配置来运行：

```
grunt.initConfig({
	karma: {
	  unit: {
	    configFile: 'karma.conf.js'
	  }
	}
});
```

大多数情况下，如果要把karma作为CI的一部分，应该启动单次运行模式:

```
singleRun: true
```

这样karma会启动浏览器，运行所有的测试用例，然后退出。

```
grunt.loadNpmTasks('grunt-contrib-jshint');
grunt.loadNpmTasks('grunt-karma');

grunt.registerTask('default', ['jshint', 'karma']);
```

![image](http://abruzzi.github.com/images/2013/10/grunt-karma-resized.png)


注意此处的default后边带了一个任务数组，其中每个任务会按照声明的顺序依次被执行。事实上此处的'default'是后边整个列表的一个别名(alias)。

#### grunt-jshint / grunt-uglify / grunt-concat

[grunt-contrib-jshint](https://github.com/gruntjs/grunt-contrib-jshint)是一个用于JavaScript静态语法检查的工具，它会帮助开发者在进行较为严格的语法检查。

和其他的Grunt插件一样，它是以一个npm的包的形式发布的，因此安装非常容易:

```
$ npm install grunt-contrib-jshint --save-dev
```

然后在Gruntfile.js中加载该插件:

```
grunt.loadNpmTasks('grunt-contrib-jshint');
```

即可，类似的还有：用以连接所有JavaScript源代码为一个独立文件的[grunt-contrib-concat](https://github.com/gruntjs/grunt-contrib-concat)，以及用以最小化JavaScript源码的[grunt-contrib-uglify](https://github.com/gruntjs/grunt-contrib-uglify)。

#### 自定义插件

[grunt-init](https://github.com/gruntjs/grunt-init)是一个帮助开发人员快速搭建基于Grunt项目的工具，比如开发jQuery插件，Gruntfile，或者Grunt插件本身。安装方式很简单，我们需要在其他项目也用到grunt-init，因此安装在全局路径下`-g`:

```
$ npm install -g grunt-init
```

开发Grunt插件，我们需要一个基本的模板，将这个模板clone到home下的.grunt-init目录下：

```
$ git clone git://github.com/gruntjs/grunt-init-gruntplugin.git ~/.grunt-init/gruntplugin
```

然后新建一个目录，并在该目录下运行：

```
$ mkdir beautify
$ cd beautify
$ grunt-init gruntplugin
```

grunt-init会让你回答一些问题，比如插件名称，版本号，github链接等。之后，grunt-init会生成一个基本的模板，开发者只需要完成自己插件的逻辑代码即可。逻辑实现在`tasks/<plugin-name>.js`中即可。

完成后可以通过`npm publish`来发布，发布之后，你的插件就可以向上边提到的常用插件那样被其他的开发者使用了。

