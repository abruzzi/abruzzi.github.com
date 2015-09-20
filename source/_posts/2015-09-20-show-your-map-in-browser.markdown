---
layout: post
title: "可视化你的足迹 - Web端"
date: 2015-09-20 22:44
comments: true
categories: 
- GIS
- Data
- Visualization
---

### 可视化你的足迹

[上一篇文章](http://icodeit.org/2015/09/visualize-your-steps/)讲述了如何在服务器端通过MapServer来生成地图。虽然MapServer发布出来的地图是标准的[WMS](https://en.wikipedia.org/wiki/Web_Map_Service)服务，但是我们还需要一个客户端程序来展现。我们在上一篇中，通过一些小脚本将照片中的地理信息抽取到了一个`GeoJSON`文件中。`GeoJSON`是一种向量图层格式，向量数据可以在服务器端绘制成栅格图，也可以直接在客户端canvas上直接绘制出来。当数据量比较大的时候，我们更倾向于在服务器端绘制，这样只需要在网络上传输一张图片（而且可以做缓存）。大数据量的客户端绘制在性能上会比较差（当然现在已经有了一些新的解决方案，我们后续再细谈），特别是有用户交互时，会出现明显的卡顿。

在本文中，我将分别使用客户端和服务端绘制的两种方式来展现两种不同的地图：使用[OpenLayers](http://openlayers.org/)直接在客户端绘制矢量图，以及使用[Leaflet](http://leafletjs.com/)来展示在服务器端绘制好的栅格图层。

#### 使用OpenLayers3展示GeoJSON

展示GeoJSON非常容易，也是一种比较直接的方式，只需要将GeoJSON文件发送到前端，然后直接通过客户端渲染即可。使用`OpenLayers3`的API，代码会是这样：

```js
  $.getJSON('data/places-ive-been-3857.json').done(function(geojson) {

    var vectorSource = new ol.source.Vector({
      features: (new ol.format.GeoJSON()).readFeatures(geojson)
    });

  });
```

客户端发送一个`ajax`请求，得到`GeoJSON`数据之后，将其转换成一个`向量`类型。`OpenLayers`定义了很多中格式读取器，比如KML的，GML的，GeoJSON的等等。然后我们可以定义一个样式函数：

```js
  var image = new ol.style.Circle({
    radius: 5,
    fill: null,
    stroke: new ol.style.Stroke({color: '#f04e98', width: 1})
  });

  var styles = {
    'Point': [new ol.style.Style({
      image: image
    })]
  };

  var styleFunction = function(feature, resolution) {
    return styles[feature.getGeometry().getType()];
  };
```

这个函数会应用到向量集的`Point`类型，将其绘制为一个红色，半径为5像素的圆圈。有了数据和样式，我们再来创建一个新的向量，然后生成一个新的图层：

```js
    var vectorLayer = new ol.layer.Vector({
      source: vectorSource,
      style: styleFunction
    });
```

创建地图，为了方便对照，我们加入了另外一个`ol.source.Stamen`图层作为参照。这样当缩放到较小的区域时，我们可以清楚的知道当前的点和地物的对照，比如道路名称，建筑名称等，从而确定目前的位置。这是一种非常常见的GIS应用的场景，但是需要注意的是，不同的图层需要有相同的空间映射方式，OpenLayers默认才用EPSG:3857，所以需要两者都采用该投影：

```js
    var map = new ol.Map({
      layers: [
        new ol.layer.Tile({
          source: new ol.source.Stamen({
            layer: 'toner'
          })
        }),
        vectorLayer
      ],
      target: 'map',
      controls: ol.control.defaults({
        attributionOptions: /** @type {olx.control.AttributionOptions} */ ({
          collapsible: false
        })
      }),
      view: new ol.View({
        center: ol.proj.transform([108.87316667, 34.19216667], 'EPSG:4326', 'EPSG:3857'),
        zoom: 2
      })
    });
```

创建地图时，我们可以通过`layers`来指定多个图层。在OpenLayers中，有很多类型的`Tile`，`Stamen`是一个专注于做[非常漂亮的地图的组织](http://maps.stamen.com/#watercolor/12/37.7706/-122.3782)。

在view中，我们需要将经纬度（EPSG:4326）转换为墨卡托投影（EPSG:3857）。这样我们就可以得到一个很漂亮的地图了：

![geojson toner](/images/2015/09/toner-resized.png)

#### 使用Leaflet展示栅格数据

我们在上一篇中已经生成了MapServer的WMS地图，这里可以用[Leaflet](http://leafletjs.com/)来消费该地图（使用OpenLayers也可以消费，不过V3似乎在和WMS集成时有些问题，我此处使用了[Leaflet](http://leafletjs.com/)）。

首先创建一个地图：

```js
var map = L.map('map').setView([34, 108], 10);
```

然后就可以直接接入我们在上一篇中生成的地图：

```js
  L.tileLayer.wms("http://localhost:9999/cgi-bin/mapserv?map=/data/xian.map", {
            layers: 'places',
            format: 'image/png',
            transparent: true,
            maxZoom: 16,
            minZoom: 2,
        }).addTo(map);
```

便于对照，我们先添加一个底图：

```js
L.tileLayer( 'http://{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="http://osm.org/copyright" title="OpenStreetMap" target="_blank">OpenStreetMap</a> contributors | Tiles Courtesy of <a href="http://www.mapquest.com/" title="MapQuest" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png" width="16" height="16">',
      subdomains: ['otile1','otile2','otile3','otile4'],
      detectRetina: true
  }).addTo( map );
```

这样就可以看到最终的地图：

![xian leaflet](/images/2015/09/xian-leaflet-resized.png)

使用Web界面，我们可以自由的拖拽，移动，并且方便的放大缩小。如果观察浏览器的网络标签，在放大地图时，可以看到很多的WMS请求：

![xian leaflet](/images/2015/09/wms-requests-resized.png)

#### 其他

如果你对代码感兴趣，可以参看[这个repo](https://github.com/abruzzi/places-ive-been)。