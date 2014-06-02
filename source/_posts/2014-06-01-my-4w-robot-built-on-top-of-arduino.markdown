---
layout: post
title: "我的第一个Arduino机器人"
date: 2014-06-01 15:21
comments: true
categories: 
- hardware
- arduino
- robot

---

### 我的第一个机器人

以我的视角拍摄的机器人

<embed src="http://player.youku.com/player.php/sid/XNzIwNzE4NjYw/v.swf" allowFullScreen="true" quality="high" width="480" height="400" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash"></embed>

以机器人自身的视角拍摄的

<embed src="http://player.youku.com/player.php/sid/XNzIwNzI4NDQw/v.swf" allowFullScreen="true" quality="high" width="480" height="400" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash"></embed>

虽然迟了4年，但是我终于完成了我的第一台机器人的安装和配置。

1.	基于Arduino的[Duemilanove开发板](http://arduino.cc/en/Main/arduinoBoard)
2.	可以躲开障碍物继续前进（有距离探测器，与障碍物的距离小于20cm时会自动转向）
3.	4轮驱动

我回忆了一下，这块板子和外设是我2010年3月在昆明的时候买的，那段时间对硬件突然有了极高的热情，但是买了之后准备开始之际，发现了几点困难：

1.	当时航空管制，电池不能空运，因此网购的小车没有电池
2.	缺乏基本的硬件常识，四个电机如何接在两个电机端口上
3.	不会焊接电机
4.	没有买杜邦线，没有测试用的面包板

基于这些困难，又加上我当时在找工作，准备面试之类，机器人的制造就放了下来。结果一放就是4年，中途从昆明搬家回到西安，不过细心的孙曼思将那一大包的零部件都打包好带了回来，多亏她认真负责的态度，才让这个机器人的产生有了可能。

#### ThoughtWorks西安硬件小组

2013年，在ThoughtWorks的西安Office有了硬件小组，他们研究开源硬件，以及这些小芯片在实际环境中的应用。比如RCA的高亮，做出了一个“半自动”地移动上的story的产品。2014年Hackday的时候，CASA团队又做出了一个看房机器人Dora，dora可以在房间中移动，由于装置了一个摄像头，因此可以实时的看到它看到的东西，而且Dora有安装了无线模块，你可以在远程操控它并得到实时图像。

好了，这么多铺垫事实上是有意义的，如果没有西安Office的硬件小组，我的这个机器人的诞生可能又需要若干年。它给我提供了丰富的资源，比如：

1.	有丰富硬件经验的张新宇，高亮，王超，可以让我很容易问问题并得到答案
2.	张新宇帮我焊了一个电源的接头
3.	王超提供了一个7.2V的电池
4.	高亮的百宝箱中有一个9V电池盒
5.	CASA团队桌子上开发Dora的一些下脚料
6.	杜邦线，热缩管，电烙铁，松香，镊子，钳子，各种螺丝刀等等

#### 4年 vs 4天

虽然拖的时间很长（4年），但是事实上加起来搭建它的所有时间差不多是4天。

1.	单独测试URM模块
2.	单独测试电机驱动L298N模块


我发现，其实硬件开发和软件一样，化分模块，小步前进，测试，持续集成等等概念可以很好的运用其中，而且效果极好，比如我的小车基本上可以划分为这样几个小功能的逐步实现：

1.	测距模块的单独启动
2.	测距模块控制一个LED（距离小于5cm，点亮一个LED）
3.	电机的单独启动（正转，反转）
4.	测距模块控制电机（距离小于5cm，转动电机）
5.	多个电机联合（如何联线）
6.	测距模块控制多个电机

当到达最后一步时，基本上所有要验证的功能都已经就绪了，只需要拼装在小车的底座上，进行集成测试即可。其实，当划分好任务之后，每一个小的任务都不会花费很多时间。


#### 故障

当我兴高采烈的去掉USB线，加上一个7.2V的电池给整个系统时，URM37测距模块伴随着浓郁的电器焦味中烧坏了，就是因为一个跳线的连接不当。这个系统中，电机需要单独加电，但是由于我自己电气知识的匮乏，导致了这个悲剧的发生。

不过，我又在Office的CASA团队的桌子上发现了另外一个测距模块，不过这次只经过了15分钟就完成了替换掉了老板子，换上了新的测距模块。

```c
#include <NewPing.h>

#define TRIGGER_PIN  12  // 12端口
#define ECHO_PIN     11  // 11端口
#define MAX_DISTANCE 400

int ledpin = 13;

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);

void setup() {
  Serial.begin(9600); // Sets the baud rate to 9600
  pinMode(ledpin, OUTPUT);   //设置13号口为输出
}

void loop()
{
  unsigned int uS = sonar.ping(); // 把扫描时间转化成us
  int dis = uS / US_ROUNDTRIP_CM; //转成距离
  
  if (dis <= 20) {
    digitalWrite(ledpin, HIGH);    
  } else {
    digitalWrite(ledpin, LOW);  
  }
  

  Serial.print("Distance = ");
  Serial.println(dis);
  
  delay(150);
}
```

#### 安装过程

测距模块很早之前就[已经整理过](http://icodeit.org/2012/01/arduino%E8%B6%85%E5%A3%B0%E6%B3%A2%E6%B5%8B%E8%B7%9D%E6%A8%A1%E5%9D%97%E4%BD%BF%E7%94%A8/)了，可以看看这里。不过我最后的成品已经没有使用URM37了，取而代之的是HC-SR04。

连接电机与电机驱动模块：

![image](/images/2014/06/motor-resized.png)

第一次焊接电机，话说这种电机的触头也太粗糙了吧，不自己焊接的话，根本就用不成，完全没有进入模块化世界。

![image](/images/2014/06/motor-repaired-resized.png)

连接之后
![image](/images/2014/06/motors-connected-resized.png)

装车
![image](/images/2014/06/4w-car-resized.png)

![image](/images/2014/06/debug-car-resized.png)


#### 最终的代码

```c
#include <NewPing.h>

#define TRIGGER_PIN  12  // 12端口
#define ECHO_PIN     11  // 11端口
#define MAX_DISTANCE 400

int E1 = 6;
int M1 = 7;

int E2 = 5;                         
int M2 = 4;                           

int ledpin = 13;

void setup() {
  Serial.begin(9600);                  // Sets the baud rate to 9600
  pinMode(ledpin, OUTPUT);   //设置13号口为输出
  
  pinMode(M1, OUTPUT);
  pinMode(M2, OUTPUT);
  
  digitalWrite(ledpin, LOW); //灭掉LED  

  delay(200); //Give sensor some time to start up --Added By crystal  from Singapo, Thanks Crystal.
}


void advance() {
    digitalWrite(M1,HIGH);          
    digitalWrite(M2,HIGH);
    analogWrite(E1, 200);
    analogWrite(E2, 200);
}

void backoff() {
    digitalWrite(M1,LOW);          
    digitalWrite(M2,LOW);
    analogWrite(E1, 200);
    analogWrite(E2, 200);
}

void left() {
    digitalWrite(M1,LOW);
    digitalWrite(M2,HIGH);
    analogWrite(E1, 150);
    analogWrite(E2, 150);
    delay(1000);
}

void right() {
    digitalWrite(M1,HIGH);
    digitalWrite(M2,LOW);
    analogWrite(E1, 150);
    analogWrite(E2, 150);
    delay(1000);
}

void stop() {
    analogWrite(E1, 0);
    analogWrite(E2, 0);
}

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);

void loop()
{
  unsigned int uS = sonar.ping(); // 把扫描时间转化成us
  int dis = uS / US_ROUNDTRIP_CM; //转成距离
  
  if (dis <= 20) {
    stop();
    left();
    delay(30);
    digitalWrite(ledpin, HIGH);    
  } else {
    advance();
    delay(30);
    digitalWrite(ledpin, LOW);  
  }
  

  Serial.print("Distance = ");
  Serial.println(dis);
  
  delay(150);
}

```

#### 体会

1.	和开发软件一样，硬件开发也可以使用“敏捷开发”
2.	实用主义，比如bluetip的使用，杜邦线拼接等
3.	迭代开发，小步快跑
