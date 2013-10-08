---
layout: post
title: "使用Grunt作为构建工具(build tool)"
date: 2013-10-07 18:14
comments: true
categories: 
- JavaScript
- lightweight

---

### Grunt简介

Grunt是一个基于JavaScript的构建工具。和其他的构建工具类似，grunt主要用于一些将一些繁琐的工作自动化，比如运行测试，代码的静态检查，压缩JavaScript源代码等等。

#### 安装grunt-cli
要在命令行运行grunt，需要安装grunt的命令行工具：

```
$ npm install -g grunt-cli
```

grunt-cli本身并不会提供Grunt构建工具，而只是一个Grunt的调用器。`-g`参数表示将grunt-cli安装在全局的路径中，这样我们可以在不同的项目中使用grunt-cli，而由于grunt-cli本身只是一个调用器，所以对于不同的项目，真正运行的Grunt可以是不同的版本，而命令行的借口则完全一致。

grunt-cli提供的命令行可执行文件的名称为`grunt`，这个工具每次运行时都会检查当前目录下的Grunt。

#### 使用grunt-cli
如果在一个既有的npm模块中，可以很容易的加入grunt的支持，只需要修改package.json，加入依赖，然后运行`npm install`来完成依赖的安装即可。

如果是一个新启动的项目，那么在项目中添加两个文件：package.json和Gruntfile。其中package.json用来定义当前项目是一个npm的模块，而Gruntfile用来定义具体的任务，以及加载Grunt的其他插件(Grunt提供丰富的插件，比如运行测试，代码静态检查等功能都是通过插件来完成的)

#### package.json
package.json定义了一个工程的元数据，这些数据被npm管理器来使用，npm本身提供了`init`参数可以很容易的生成一个package.json文件：

```
$ npm init 
```

根据提示可以很容易的生成一个新的package.json

```
{
  "name": "chapter-testing",
  "version": "0.0.0",
  "description": "This is the demo for how to use grunt.js",
  "main": "my.conf.js",
  "directories": {
    "test": "test"
  },
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "Juntao",
  "license": "BSD-2-Clause"
}
```

一般来说，package.json文件中有一个`devDependencies`的小节，定义了本项目的外部依赖。

可以通过运行

```
$ npm install grunt --save-dev
```
来为工程文件package.json添加`devDependencies`小节的定义：

```
"devDependencies": {
  "grunt": "~0.4.1"
}
```

该命令会为工程添加一条依赖关系，如果别人拿到这个文件，就可以在本地“复原”你的开发环境，以保证整个团队使用同样地**库**文件。

完成之后，该命令会在本地生成一个目录(如果没有的话)`node_modules`，其中包括了完成的Grunt的可执行文件，这时候在命令行运行grunt(由grunt-cli提供的命令行工具)，就会尝试在此目录中查找Grunt的可执行文件。

#### Gruntfile

要运行Grunt，还需要定义你自己的任务，默认的任务定义在Gruntfile中，Gruntfile有一定的格式。

所有的任务需要定义在一个函数中：

```
module.exports = function(grunt) {
  // task defination
};
```

一般而言，使用Grunt会读取一些项目的信息(定义在package.json中)：

```
grunt.initConfig({
    pkg: grunt.file.readJSON('package.json')
});
```

亦可以在这个时刻指定一些其他的插件的选项：

```
grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
        all: ['Gruntfile.js', 'lib/**/*.js', 'test/**/*.js']
    }
});
```

然后需要加载其他的插件(如果需要的话)

```
grunt.loadNpmTasks('grunt-contrib-jshint');
```

最后，需要指定一个grunt的入口任务(default任务)：

```
grunt.registerTask('default', function() {
	console.log("default task");
});

```

然后运行`grunt`，我们此处定义的default任务仅仅在控制台上打印一行字符串:

```
$ grunt
Running "default" task
default task

Done, without errors.
```

### Grunt插件
Grunt已经得到了很多的开源软件贡献者的支持，已经又众多的插件被开发出来。比如:

1. [grunt-contrib-jshint](https://github.com/gruntjs/grunt-contrib-jshint)
2. [grunt-contrib-uglify](https://github.com/gruntjs/grunt-contrib-uglify)
3. [grunt-contrib-qunit](https://github.com/gruntjs/grunt-contrib-qunit)
4. [grunt-karma](https://github.com/karma-runner/grunt-karma)

等等，使用这些插件可以快速的为你的项目开发提供很多的便利，以grunt-jshint为例，
首先需要安装此插件：

```
$ npm install grunt-contrib-jshint --save-dev
```

然后在grunt.initConfig中指定jshint需要的参数：

```
grunt.initConfig({
    jshint: {
        files: ['js/*.js'],
        options: {
            ignores: ['js/jquery*.js']
        }
    }
});
```

然后加载此插件：

```
grunt.loadNpmTasks('grunt-contrib-jshint');
```

最后，可以将`jshint`加入到默认的任务中：

```
grunt.registerTask('default', ['jshint']);
```

运行结果`可能`如下:

![image](http://abruzzi.github.com/images/2013/10/jshint.png)
