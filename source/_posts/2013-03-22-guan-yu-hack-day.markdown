---
layout: post
title: "关于Hack day"
date: 2013-03-22 20:55
comments: true
categories: 
- thoughtworks
- innovation

---

####关于Hackday

Hackday是一个技术活动，每三个月举行一次，每次正式时间为两天，每次的hackday都有一个主题，比如对某个业务模块的数据挖掘，关于某个模块的功能/执行效率的改进。

Hackday中的idea多是工作中接触到的痛点，但是又有一些挑战，很难在工作的时候将其完成，或者是一些有意思的主题，平时想做又不太合适（比如一些没有经过确认创新的点子）。

####Hackday 1st

第一次Hackday是跟[Adam](http://adams.co.tt/blog)一起做一个数据展现的idea，Adam是墨尔本Office里一个相当senior的咨询师，我们当时做的idea是根据系统中已有的数据信息，来做一些简单的数据分析，如：

1. 找出一个地区内的所有中介，看看哪些中介持有最多的房产资料
2. 找出一个地区中，可以最快卖掉手中房产的中介


![image](http://abruzzi.github.com/images/2013/03/hackday-agent-info.resized.png)

我们的应用使用sinatra作为服务器；由于数据库系统已经存在，所以ORM需要做的是将对象和已存在的数据表关联，因此功能强大且可以独立使用的ActiveRecord就成了首选；模板使用haml；UI框架风格使用了BootStrap。

搭建环境大概只用了1到1.5个小时，在整个开发过程中，我学习到了一个专业的敏捷开发的流程：

1. 划分大的目标，使之称为小的task
2. 小步前进，做完一个功能之后，进行快速的review（首先有一个可以工作的版本）
3. 如果发现有潜在的问题，进行重构，以方便下一个小的task

两天之后，当一个可以工作，并且很容易扩展的应用程序真实的放在我们面前的时候，我觉得十分有意思，这当然不是因为build something本身的乐趣，而是我看到一种理论在实际的生活中可以工作（而且是以一种非常有意思的方式），这个过程让我对这种开发方式产生了很多新的认识。

####Hackday 2nd

第二次的idea是一个基于google map的应用，比如某人的公司在A地，老婆的公司在B地，他们最喜欢的超市在C地，然后他们想找一个离这三个地方距离都很近的房子。

![image](http://abruzzi.github.com/images/2013/03/hackday-neighborhood.resized.png)

同样也使用了Sinatra+haml+javascript。由于idea本身就是西安团队想出来的，所以这次的参与者都是西安office的，这样可以省去交流的成本，做起来肯快，但是问题也很严重，就是没有人做演示，别的团队也不清楚我们在干什么。

####Hackday 3rd

经历了前两次，第三次的就非常official了，有story wall，有producer，有站会，有showcase，正好这段时间我们的一个客户designer在西安office出差，所以还设计了一些海报。

![image](http://abruzzi.github.com/images/2013/03/hackday-rango-stories.resized.png)

有了专业的designer参与，应用程序的外观立马得到了改善，看起来非常有产品的感觉：

![image](http://abruzzi.github.com/images/2013/03/hackday-rango-homepage.resized.png)

这次本来计划开发离线版本，使用浏览器的localStorage，但是静态网页在iPad上无法工作。team快速的做出了调整，使用sinatra（又一次）搭建了服务器，然后将应用部署在cloud上。

####总结

虽然每次的“成果”都不大，但是整个hack的过程都非常有意思，每次都可以使用前几次活动中好的工作方式，而前几次中做的不好的则可以进行改进，技术仅仅是其中的一个方面，与团队成员的协作，对自己信心的加强，通过创新来给客户带来价值，这一系列的，不那么明显的“成果”才是更重要的。

另一个“成果”是，我对轻量级的框架如[sinatra](http://www.sinatrarb.com/)，引擎[haml](http://haml.info/)等有了非常浓厚的兴趣，用这些工具可以快速的搭建用于showcase的应用程序，而且非常容易改进，非常适合小步迭代的开发方式。
