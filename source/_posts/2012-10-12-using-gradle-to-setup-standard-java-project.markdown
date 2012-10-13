---
layout: post
title: "Using gradle to setup standard java project"
date: 2012-10-12 23:24
comments: true
categories: 
---
##Generate typical project layout
If you are as lazy as I am, you may want to generate typecial project layout automatically, let's do it by using [gradle](http://www.gradle.org/).

Simply add the following lines into your build.gradle:

    apply plugin: 'java'

    task "create-dirs" << {
        sourceSets*.java.srcDirs*.each {it.mkdirs()}
        sourceSets*.resources.srcDirs*.each {it.mkdirs()}
    }

then using gradle to run the task defined "create-dirs":

    $ gradle create-dirs

you will get the directories structure like this:

    .
    ├── build.gradle
    └── src
        ├── main
        │   ├── java
        │   └── resources
        └── test
            ├── java
            └── resources
If you are using intellij as your default IDE, then you can apply the 'idea' plugin for the project:

    apply plugin: 'java'
    apply plugin: 'idea'

and then:

    $ gradle idea

it should generate 3 files out: file.iml, file.ipr, file.iws. You can then open intellij and have fun with code inside, I would like to make a new post to talking about how to setup a java project by using intellij, and using [TDD](http://en.wikipedia.org/wiki/Test-driven_development) for coding.
