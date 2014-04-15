---
layout: post
title: "全球地震信息的可视化（使用OpenLayers）"
date: 2014-04-15 21:33
comments: true
categories: 
- gis
- JavaScript

---

#### OpenLayers

使用[OpenLayers](http://openlayers.org/)可以很容易的搭建基于Web的GIS系统，OpenLayers支持不同的数据源(符合WMS协议的服务器，Google Maps API, Bing Maps，KML以及[GeoJSON](http://geojson.org/)等等)。通过将不同的数据源的数据整合，我们可以开发出丰富而用户友好的GIS系统。

OpenLayers可以轻松的处理GeoJSON数据，并将其生成矢量层，我们可以将这个层叠加在其他数据源（比如OSM）提供的地图上，以得到一个完整的小应用。

最后的运行结果是这样的：

![image](/images/2014/04/openlayers-earthquake-resized.png)

#### GeoJSON

[美国地理信息调查局](http://www.usgs.gov/aboutusgs/)是一个科学组织，他公开了很多地球上的灾难信息，比如对地震的统计，并提供编程接口。它公开的地震统计信息，包含全世界各地报告过的地震，以及全美所有检测到的地震，并以多种周期（小时，天，周，月等），多种格式（GeoJSON，KML，Atom等），以便应用程序的开发者只用这些数据。

#### 实现

##### 设置基本环境

我们将借助bower来安装所有的代码依赖。首先，我们需要bower将所有的包都安装在`components`目录下，这个可以通过在当前目录的`.bowerrc`文件中制定`directory`：

```json
{
    "directory": "components"
}
```

然后运行bower安装jquery以及openlayers：

```sh
$ bower install jquery
$ bower install openlayers
```

通过bower安装OpenLayers之后，可以通过OpenLayers自带的build工具将所有的源码合并压缩为一个文件：

```sh
$ cd components/openlayers/build
$ ./build.py #将会在当前目录下生成一个OpenLayers.js的文件
$ mv OpenLayers.js ../
```

然后，创建一个简单的HTML文件，引用jquery.js和OpenLayers.js，以及我们的入口脚本app.js，本文所有的代码都只是修改这个文件。

```html
<!DOCTYPE HTML>
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <title>Earthquake distribution</title>
        <link rel="stylesheet" href="style.css" />
    </head>
    <body>
        <div id="container">
            <div id="map">
            </div>
        </div>
        <script src="components/jquery/jquery.js" type="text/javascript"></script>        
        <script src="components/openlayers/OpenLayers.js" type="text/javascript"></script>        
        <script src="app.js" type="text/javascript"></script>        
    </body>
</html>
```

还可以运行`bower init`来将生成`bower.json`，以方便别人使用我们的应用：

```js
$ bower init
```

##### 基本代码

一个最简单的OpenLayers应用，只需要7行代码：

```js
$(function() {
    var map = new OpenLayers.Map("map");
    var osm = new OpenLayers.Layer.OSM();

    map.addLayers([osm]);
    map.zoomToMaxExtent();
});
```

这段代码在id为`map`的HTML元素创建了一个地图，这个地图上有一个叫OSM的层（即[OpenStreetMap](http://www.openstreetmap.org/)，一个开源，开放的地图平台），并将地图缩小到边界范围（以获得最大的视野）:

![image](/images/2014/04/openlayers-osm-resized.png)

##### 生成矢量层

通过GeoJSON生成矢量图非常容易：

```js
var geo = new OpenLayers.Layer.Vector("EarthQuake", {
    strategies: [new OpenLayers.Strategy.Fixed()],
    protocol: new OpenLayers.Protocol.HTTP({
        url: '/all_day.geojson',
        format: new OpenLayers.Format.GeoJSON({ignoreExtraDims: true})
    })
});
```

注意此处的[all_day.geojson](http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson)是从USGS网站上下载的，过去一天中世界各地的所有地震统计。

上边的代码创建了一个名称为`EarthQuake`的矢量层，`strategies`中的Fixed策略表示仅请求一次资源，然后缓存在前端，不再请求。`protocol`表明数据来源为`all_day.geojson`，格式为`OpenLayers.Format.GeoJSON`。由于USGS返回的地理信息除了经纬度还包含深度，而OpenLayers默认只处理经纬度的，因此需要此处的`ignoreExtraDims`来忽略那个额外的深度信息。

![image](/images/2014/04/openlayers-geojson-resized.png)

##### 定制样式

虽然我们已经加上了新的层，也可以看到很多表示地震的点信息，但是并不能看出哪些地震是严重的，比如里氏3级以下的地震，几乎没有危害，可以标注成一种颜色；而更高震级的可以标记成另外一种颜色。

OpenLayers可以很容易的做到这个定制化:

```js
    var style = new OpenLayers.Style();

    var ruleLow = new OpenLayers.Rule({
      filter: new OpenLayers.Filter.Function({
            evaluate: function(properties) {
                return properties.mag < 3.0;
            }
        }),
      symbolizer: {pointRadius: 3, fillColor: "green",
                   fillOpacity: 0.5, strokeColor: "black"}
    });

    var ruleHigh = new OpenLayers.Rule({
      filter: new OpenLayers.Filter.Function({
            evaluate: function(properties) {
                return properties.mag >= 3.0;
            }
        }),
        symbolizer: {pointRadius: 5, fillColor: "red",
                   fillOpacity: 0.7, strokeColor: "black"}
    });

    style.addRules([ruleLow, ruleHigh]);

    geo.styleMap = new OpenLayers.StyleMap(style);
```

首先创建一个Style对象，为Style添加两条规则Rule，然后将Style对象包装成StyleMap并赋值给表示地震的矢量层`earthquake`。

对于规则ruleLow，我们定义了，当一个feature的属性值mag(震级)小于三的时候后，使用绿色的，半径为3px的小圆圈来表示。而ruleHigh则定义了当震级大于等于三的时候，用红色，半径为5px的圆圈来表示。

![image](/images/2014/04/openlayers-geojson-styling-resized.png)

##### 加上事件处理

虽然我们已经可以直观的根据震级不同而看到不同颜色的点，但是整个应用仍然没有多少意义：它不具备于用户的交互能力。我们需要添加上事件处理，当用户点击地图上的一个圆点的时候，应该看到一个更详细的窗口。

```js
var selectControl = new OpenLayers.Control.SelectFeature(geo, {
    onSelect: onFeatureSelect,
    onUnselect: onFeatureUnselect 
});

map.addControl(selectControl);
selectControl.activate();

function onFeatureSelect(feature) {
    var html = "<span>"+feature.attributes.title+"</span>";

    var popup = new OpenLayers.Popup.FramedCloud("popup",
            feature.geometry.getBounds().getCenterLonLat(),
            null,
            html,
            null,
            true
        );

    popup.panMapIfOutOfView = true;
    popup.autoSize = true;

    feature.popup = popup;

    map.addPopup(popup);
}

function onFeatureUnselect(feature) {
    map.removePopup(feature.popup);
    feature.popup.destroy();
    feature.popup = null;
}
```

我们在地图上添加了一个`SelectFeature`元素，并注册了回调函数：当矢量层中的矢量被选中之后，函数`onFeatureSelect`将被执行，我们可以在这个函数中添加对弹出窗口的控制。当`onFeatureSelect`执行时，OpenLayers会将当前的Feature传递进来，我们可以动态的取得震级，标题，链接等信息，并展现给最终用户。

![[image]](/images/2014/04/openlayers-geojson-popup-resized.png)


如果将数据源扩大到本周的所有地震：

```js
var geo = new OpenLayers.Layer.Vector("EarthQuake", {
    strategies: [new OpenLayers.Strategy.Fixed()],
    protocol: new OpenLayers.Protocol.HTTP({
        url: '/all_week.geojson',
        format: new OpenLayers.Format.GeoJSON({ignoreExtraDims: true})
    })
});
```

![image](/images/2014/04/openlayers-geojson-weekly-resized.png)

完整的代码示例[可以看这里](https://github.com/abruzzi/earthquake-viz)。