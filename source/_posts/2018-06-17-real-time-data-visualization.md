---
layout: post
title: "实时数据的可视化"
date: 2018-06-17 11:21
comments: true
categories: 
- visualization
- data
- d3
- shell
---

## 实时数据

通常来说，可视化的报表会以更高效率的方式将数据背后隐藏的信息传递给我们。通过一个简单的`BarChart`，我们就很容易对比某商品在第二季度中的销量差异；而通过一条简单的`LineChart`，则很容易看出员工平均工作时间在某个月份的分布。这些报表都或多或少与时间相关：随着时间的流逝，某项指标会因为各种各样的因素而产生变化。

另一方面，在某些领域，我们需要更高时效性的报表。比如产品的线上指标分析：有多少用户当前在线，主站的负载情况如何，有多少在线交易正在形成等等。此外，很多运维数据也希望有更高的实时性，比如目前服务器的负载如何，过去的5分钟的负载情况又是什么样子的等等。

这类报表的特点是：

* 高时效性
* 对于细粒度的指标，数据量可能会很大
* 过了某段特定的时间段，数据的价值会骤降

![mac-cpu](/images/2018/06/cpu-load-resized.png)

比如上图是Mac上的CPU使用情况的实时报表，它展现了一段时间内的各个核上的计算负载。这些信息不断产生，有不断被丢弃，没有人关注一个小时之前的CPU占用，只要能展示出最近几分钟的就好。

基于这些特性，如何存取数据、如何分析度量结果、如何滚动历史数据等等都会遇到和其他图表不尽相同的问题。另外，由于实时数据的可视化与时间是强相关的 -- 它本质上必须是一个动态的图表，这与其他的图表类型又有不同。我们在这篇文章中将会讨论这些问题，以及解决这些问题的常见方案。

### 数据指标

对于实时数据，我们关注不同事件发生的次数，以及事件发生时持续的时长等。我们首先需要定义一些对象：

1. 计数器（counter）
2. 计时器（timer）
3. 标量（gauge）

#### 计数器

计数器涉及需要被记录次数的事件（通常是每发生一次，计数器加一/减一），比如：

- 响应为200的请求
- 登陆失败
- 从某session产生的请求

#### 计时器

计时器涉及所有应该记录时间长度的事件，通常这类时间我们可以通过引入一个时间段（interval）来计算一些统计信息，比如平均值，方差，标准差，最大值，最小值等。比如：

- 请求响应时间
- 停留时间
- 下载速度

#### 标量

还有一种经常会用到的量，我们不关注过程中它的变化倾向，只关注某个时刻上的数字，比如：

- 某一时刻的进程数
- 某一时刻的CPU负载
- 某一时刻的内存占用率

<!--

## metric

1. 日志
2. 事件
3. 拉取 - WebSocket 
4. 轮询 - interval

-->

### 数据处理流程

对于生产环境，实时数据既可以以日志的形式提供，也可以是来源于事件数据库。日志是最常见的形式，几乎所有的系统都会以各种各样的方式记录日志，大部分的日志会提供滚动机制：日志会被记录到一个固定尺寸的文件中，旧的日志会被滚动的写入到另一个文件（通常还会有配套的定时任务来清理更早的日志等）。另一方面，对于很多基于事件的软件系统中，事件会被写入到数据库中，这些数据也可以用作实时数据可视化的来源。

原始数据往往不能直接用来做可视化展现，通常我们需要做一些预处理，这些过程包括：

- 原始数据获取
- 结构化
- 初步统计
- 高阶统计

#### 数据结构化

有很多的工具可以帮助我们实现这些步骤，比如我们通过一个简单的配置，就可以让[logstash](https://www.elastic.co/products/logstash)自动将源源不断产生的日志数据写入到[statsd](https://github.com/etsy/statsd)（最终周期性的写入到[graphite](https://graphiteapp.org/)数据库中）:

```sh
input {
  stdin {}
}

filter {
  grok {
    match => {
      "message" => "%{DATA:time} %{DATA:status} %{NUMBER:request_time} %{DATA:campaign} %{DATA:mac} %{DATA:ap_mac} %{GREEDYDATA:session}"
    }
  }
}

output {
  stdout { codec => rubydebug }

  statsd {
    host => 'localhost'
    increment => "airport.%{session}"
  }

  statsd {
    host => 'localhost'
    increment => "airport.%{status}"
  }
}
```

`logstash`是一个非常灵活其高度可定制的工具，我们只需要指定输入数据源，匹配规则，输出数据源即可做到：对于`输入`中，如果有满足`匹配规则`的数据，则将这些数据写入到`输出`中。这个听起来是不是有点像[IFTTT](https://ifttt.com/)(If This Then That)工具做的事情呢？

```sh
tail -f /var/logs/nginx/access.log | logstash -f log.conf
```

在这个例子中，我们使用标准输入为数据源，当输入中有`time status request_time campaign mac ap_mac session`这样的字符串时，则认为是匹配成功，对于匹配成功的数据，将其通过`statsd`插件写入到`localhost`中。`increment`指令对上述的`counter`数据类型，即每发生一次匹配，对应的值自增一。

比如当输入的日志内容为：

```
1529242838 403 0.02 f3715a7f52d8cef53fef1f73134e487a 00:61:71:53:ff:b0 T2-CL*-49-D* 2293c8e9-8801-485b-9f1d-9e5a7f5a8965
```

匹配结果为：

```json
{
        "campaign" => "f3715a7f52d8cef53fef1f73134e487a",
    "request_time" => "0.02",
          "status" => "403",
         "session" => "2293c8e9-8801-485b-9f1d-9e5a7f5a8965",
         "message" => "1529242838 403 0.02 f3715a7f52d8cef53fef1f73134e487a 00:61:71:53:f4:0b T2-CL13-49-D87 2293c8e9-8801-485b-9f1d-9e5a7f5a8965",
        "@version" => "1",
            "host" => "juntao-qiu.local",
          "ap_mac" => "T2-CL*-49-D*",
            "time" => "1529242838",
             "mac" => "00:61:71:53:ff:b0",
      "@timestamp" => 2018-06-17T13:40:39.023Z
}
```

这时候，`logstash`会为`airport.2293c8e9-8801-485b-9f1d-9e5a7f5a8965`这个`counter`加一：

```js
counter["airport.2293c8e9-8801-485b-9f1d-9e5a7f5a8965"] += 1
```

#### 统计

对于结构化的数据，我们需要按照一定的周期来对数据进行初步的统计，比如对于计时器类型的数据，需要做求和，平均值，方差、标准差，中位数等的计算；而对于计数器，则需要累计其值。我们可以通过`statsd`来完成这些动作。

`statsd`本质上来说，是一个非常简单的服务，它可以工作在`TCP`或者`UDP`模式上。而对于大多数情况，为了避免在数据量变大的时候`TCP`的巨大开销，通常会使用`UDP`的不可靠（但是高效）连接。`statsd`在接受到客户端请求后，会在本地维护一些`counter`和`timer`的计数，然后定时的(默认为15秒)会向后台的`graphite`发送一次数据。

### 可视化

- 呈现方式
- 周期
- 实时性要求

## 直接呈现

### Logstalgia

`Logstalgia`可以将特定格式的日志文件分析，并以一种非常酷炫的方式展现出来，就好像是在玩经典游戏`打砖块`一样。

![logstalia](/images/2018/06/logstalgia-resized.png)

`Logstalgia`要求一些必填字段：

- UNIX时间戳
- 请求的hostname/ip
- 请求资源的路径
- 响应码（201, 500等）
- 响应的大小

```sh
1529206121|12.21.18.246|/dispatcher/campaigns/2de808e08dccec2c7e55e41ecbd5a421|200|20
```

如果原始日志不是这个格式，你可以写一个简单的转换器来适配：

```js
const source = '[$time_local] "$remote_addr - $remote_user" "$request" $status $body_bytes_sent "$http_referer" $request_time "$http_user_agent"'; 

const NginxParser = require('nginxparser');
const parser = new NginxParser(source);

const moment = require('moment');

parser.read('-', (row) => {
	const ts = moment(row.time_local, "DD/MMM/YYYY:HH:mm:ss Z").unix();
	const parsed = row.request.split(/\s+/)
	console.log(`${ts}|${row.ip_str}|${parsed[1]}|${row.status}|${row.body_bytes_sent}`);
}, (err) => {
    throw err;
});
```

注意这个脚本的输入和输出是标准输入和输出，即你可以通过管道将它接入到命令行中。比如：

```sh
tail -f /var/log/nginx/access.log | node adaptor.js | logstalgia
```

不过，`logstalgia`只能运行在Desktop上，应用的外观比较固定，基本上无法定制（比如动画效果的配置等）。更多时候，我们希望可以将实时数据的呈现放在Web端，以提高可定制性。

### 实时数据呈现

如果要做到实时呈现，我们可以直接读取日志，并将日志通过WebSocket发送给客户端。这种做法的好处是实时，比如一个相应为500的错误，一个交易失败的异常等，可以非常直观的展现出来。它的缺点也很明显，一方面如果信息量很大，即日志写入速度太快，前端很可能处理不过来，另一方面，这种被`摊平`的原始信息可能太过于粗糙，无法做到统计分析。

#### WebScoket + D3.js

```js
const _ = require('lodash');
const { spawn } = require('child_process');
const generator = spawn('./generator.sh');

const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });

function parse(data) {
	//...
}

wss.on('connection', (ws) => {

  const output = (data) => {
    ws.send(JSON.stringify(parse(data)));
  }

  generator.stdout.on('data', output);

  ws.on('close', () => {
    generator.stdout.removeListener('data', output);
  });
});
```

我们通过`spawn`来在子进程中启动一个shell脚本，这个脚本会不断的从远程服务器上的日志文件中读取日志，并输出到控制台上。当有新的WebSocket连接建立时，我们会将`generator`子进程上产生的数据写入该连接，当然，在写入前会将基于行的日志解析成客户端消费的结构化的数据，并以JSON格式返回。

最后，当客户端主动断开连接时，我们需要将`generator`上的事件监听函数删除掉。

这里的`generator.sh`内容可以是任何能从日志读取信息，并输出到控制台的脚本。比如最简单的可能是这样：

```sh
tail -f /var/logs/nginx/access.log
```

如果本地没有访问流量，我们可以将其指向测试环境：

```sh
ssh qa-env tail -f /var/logs/wifi-portal/wifi-portal-2018-06-13-access.log
```

对于客户端而言，只需要在页面加载时建立一个WebSocket连接，当数据到来时做重新处罚绘制接口。此处使用了一个D3.js的[实时报表插件](https://bl.ocks.org/boeric/6a83de20f780b42fadb9)。

```js
var ws = new WebSocket("ws://localhost:8080");

ws.onopen = function() {
  console.log('connected');
};

ws.onmessage = function (evt) { 
  const event = JSON.parse(evt.data);
  categroies.push(_.truncate(event.campaign, { 'length': 8 }));
  const campaigns = _.uniq(categroies);

  chart.yDomain(campaigns);
  chart.yDomain().forEach(function(cat, i) {
    var now = new Date(event.date);

    var mills = event.mills * 200;

    const obj = {
      time: now,
      color: color(mills),
      opacity: 1,
      category: _.truncate(event.campaign, { 'length': 8}),
      type: "circle",
      size: mills,
    }

    chart.datum(obj);
  });

};
```

![](/images/2018/06/websocket-d3-pretty-resized.png)

上图对应的图例为：

- 横轴表示时间
- 纵轴表示被请求的特定资源（比如某个API，或者某个静态图片）
- 每一个时刻被请求到的资源会在画布上形成一个点
- 点的大小反应了响应时长

## 统计信息的呈现

### Graphite

`graphite`自带了一个可视化的界面，你可以选择将多个指标展现在同一个界面上：

![](/images/2018/06/graphite-campaigns.png)

除此之外，`graphite`还提供了更强大的`render`API，使用这个API，你可以获得多种输出格式，比如：`csv`, `json`等，方便二次开发。另一方面，你可以通过`target`参数将表达式来获取更为复杂的指标计算。

比如：

```
http://localhost/render/?format=json&target=stats.jc.airport.campaigns.1565ae2c79aee5e635e55d73354c7cd3
```

其中，format指定了`json`，而`target`指定了指标的名称，事实上，`target`可以更丰富：

```
http://localhost/render?format=raw&target=alias(sumSeries(stats.jc.airport.campaigns.*)%2C%27%27)&from=1529245830&until=1529245929
```

这里的`target`的值为`alias(sumSeries(stats.jc.airport.campaigns.*), '')`，表示要对所有的以`stats.jc.airport.campaigns`开头的指标的值求和。通过`from`和`until`指定起止时间，可以获取在该段时间中所有的数据，这样我们可以通过客户端轮询的方式，逐步的、实时的展现出一些指标的统计信息。

### [Cubism.js](http://square.github.io/cubism/) + graphite

`Cubism`是D3.js的一个插件，专门用来展现基于时间的实时报表。事实上，其背后有许多研究和论文支持，即`horizon`图。

```js
var context = cubism.context()
    .serverDelay(10 * 1000) // allow 10 seconds of collection lag
    .step(10 * 1000) // 10 seconds per value
    .size(1440); // fetch 1440 values (720p)

var graphite = context.graphite("http://localhost");

var api_metrics = [
  graphite.metric("sumSeries(stats.jc.airport.campaigns.*)").alias("Campaigns Freq")
];

var horizon = context
	.horizon()
	.colors(["#78FF00", "#CFFFA4", "#B3FF70", "#5BC200", "#469500"])
	.height(40);

d3.select("body").selectAll(".axis")
    .data(["top", "bottom"])
  .enter().append("div").attr("class", "fluid-row")
    .attr("class", function(d) { return d + " axis"; })
    .each(function(d) { d3.select(this).call(context.axis().ticks(12).orient(d)); });

d3.select("body").append("div")
    .attr("class", "rule")
    .call(context.rule());

d3.select("body").selectAll(".horizon")
    .data(api_metrics)
  .enter().insert("div", ".bottom")
    .attr("class", "horizon").call(horizon.extent([0, 50]));

context.on("focus", function(i) {
  d3.selectAll(".value")
  	.style("right", i == null ? null : context.size() - 1 - i + "px")
  	.text((d) => isNaN(d) ? 0 : d.toFixed(2)) ;
});
```

![](/images/2018/06/cubism-graphite-resized.png)

## 小结

本文介绍了实时数据可视化的一些典型场景，以及通用的数据准备及呈现方法。通过一些既有的工具或者简单的脚本，我们就可以将实时产生的数据feed到统计用的时序数据库，然后按照不同的需求方式呈现出来。通常来说，基于固定时间间隔的统计数据更有意义一些，比如单位时间内的请求数量，请求的平均时延等；另一方面，仅仅将数据实时的呈现出来在某些场景下也非常有意义，比如系统实时的在线人数，发生登陆异常的占比，某些节点高于90%的负载等信息。



