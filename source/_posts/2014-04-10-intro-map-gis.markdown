---
layout: post
title: "GIS系统如何工作"
date: 2014-04-10 23:45
comments: true
categories:
- python
- gis

---

#### GIS系统如何工作

去年十二月中旬从RCA项目上下来之后，就一直在一个[GIS](http://en.wikipedia.org/wiki/Geographic_information_system)项目上做咨询。在新的项目上，日常工作的重点主要是放在前端开发上（比如AngularJS，Grunt，Jamsine之类），对于业务（与GIS相关）方面，则完全没有涉及。

虽说之前也接触过[一点GIS相关的开发](http://icodeit.org/2013/03/guan-yu-hack-day/)，比如Google Maps API，[OpenLayers](http://openlayers.org/)之类，但是仅仅停留在使用别人的API搭建个小应用的层次。

![image](/images/2014/04/roads-resized.png)

直到最近，在GIS专家芦康平的指导下，才真正开始接触GIS，很快我就发现这是另一个十分好玩的新天地。简而言之，这个新的天地里，所有的东西都有一种似曾相识的感觉，但是又非常新鲜。比如地图服务器，渲染引擎，缓存，地理信息数据库等，都可以在其他的系统中找到对应。这种感觉好比收集硬币，或者收集邮票一样，当你看到新的有着不同花纹，大小，材质，年代的硬币时，那种既在意料之中又在意料之外的感觉简直太有意思了。

GIS系统，毋庸置疑可以帮助人们更加直观的分析数据，当数据与地理信息有所关联的时候，GIS系统会变得十分友好，也可以更充分的提供信息。

鉴于GIS对我来说是一个完全崭新的领域，那么学习之前，自然有很多的问题出现：

1.  地图的信息（建筑物，河流，街道）从何而来？
2.  数据在服务器端以何种方式存储？
3.  地图数据到底如何被渲染出来？
4.  一个GIS系统的部署结构是什么样的？需要哪些组件？
5.  业界的标准是什么，有哪些开源的项目和工具可供参考？

等等。

##### 地图是如何被渲染的？

通常来讲，我们看到的地图是由一个底图和若干个层的叠加来达到的最终结果。其中每个层次都会保存不同类型的地理信息，比如将所有的河流信息放在一个层，将建筑物放在另外一个层。

![image](/images/2014/04/elevation-map.jpg)

这些信息存储在数据文件中（[shapefiles](http://en.wikipedia.org/wiki/Shapefiles)）或者数据库中，通过使用专门的工具来将这些地理信息转换成图片。由于每张图片都是透明的，这样叠加起来的最后效果就是如Google Maps之类应用的结果了。当然，叠加过程一般都发生在服务器端（有些简单应用则是在客户端完成某些层次的绘制，比如我之前发过的[我去过的地方](http://icodeit.org/placesihavebeen)，这些热力图就是在客户端通过JavaScript加上去的。）。

地图在服务器端被渲染出来之后，尺寸一般会非常大。需要有工具将这些大图切分成很多组的小图，这些小图被称之为瓦片（tile）。为了给不同缩放级别的客户端提供不同的图片，这些瓦片被精心的分成了多个组，每个组都有编号。如果地图支持18级的缩放，就会现有18个分组。当然分组好越靠后，分组中的瓦片越多。

![image](/images/2014/04/tiles-resized.png)

比如当客户端请求缩放级别为10的地图时，客户端（比如OpenLayers）会根据经纬度计算好图片的边界，然后请求第10级的一些瓦片，并将这些瓦片排列在画布上。一般而言，这些瓦片都是正方形（256x256或者512x512）。


##### WMS服务

[WMS(Web Map Service)](http://en.wikipedia.org/wiki/Web_Map_Service)是一个基于HTTP的简单协议，客户端发送的请求中包含请求类型，地图的层次，边界等信息，服务器根据这个信息生成图片，并返回该图片：

![image](/images/2014/04/wms-request.png)

当然，WMS本身支持多种请求，最常见的就是`GetMap`，细节可以参考OGC规范及具体服务器的实现。而对于后端的服务器来说，从请求中获取这些信息之后，会首先从数据库/数据文件中得到数据，并使用渲染引擎绘制图片，并最后将图片返回客户端。

##### 图片类型

图片分为栅格类型和矢量类型两种。栅格图片一般的原始来源是航拍，遥感等，本质上来说是照片，照片必然会有大小，如果放大到某一个范围之外，就会模糊。而矢量图是数学上的抽象，比如在某个坐标系统中，在某处有一个点A，另一处有一个点B，两点之间有一条线连接。矢量图的特点是与缩放程度无关。

![栅格图](/images/2014/04/bangor_oli_2014040_red_swir_tir_720.jpg)

栅格图的特点是真实，矢量图的特点是抽象（存储方便，占用空间更少，也更容易修改）。但是为了绘制正确，完整的地图，两种类型的图片信息都是必要的：

![矢量图](/images/2014/04/polygon-resized.png)

##### 常用文件格式

Shapefiles是Esri公司开发出来的用于存储地理信息的文件格式。说是文件，其实是一个文件族，Shapefile包含了数种文件，其中有三种必须的(.shp，.shx，.dbf)。其他有一些可选的(.prj，.sbn/.sbx等等)。

OSM格式是由OpenStreetMap采用的文件格式，其实是一个XML。

```xml
<osm version="0.6" generator="Osmosis 0.43.1">
  <bounds minlon="144.26600" minlat="-38.55200" maxlon="145.81000" maxlat="-37.36500" origin="http://www.openstreetmap.org/api/0.6"/>
  <node id="579259" version="3" timestamp="2008-12-17T02:28:22Z" uid="57437" user="Canley" changeset="431325" lat="-37.9309048" lon="145.1282066"/>
  <node id="579260" version="5" timestamp="2009-12-03T21:42:45Z" uid="1679" user="andrewpmk" changeset="3284133" lat="-37.9388304" lon="145.1266866"/>
  <node id="579261" version="4" timestamp="2013-02-15T20:00:37Z" uid="79475" user="AlexOnTheBus" changeset="15043978" lat="-37.9404366" lon="145.1395848"/>
  <node id="579262" version="18" timestamp="2013-01-31T21:37:02Z" uid="79475" user="AlexOnTheBus" changeset="14864580" lat="-37.9295116" lon="145.1266366">
    <tag k="highway" v="traffic_signals"/>
  </node>
  <node id="579265" version="2" timestamp="2010-06-24T12:05:34Z" uid="57437" user="Canley" changeset="5065613" lat="-37.9369707" lon="145.140732"/>
  ...
</osm>  
```

#### 技术栈

和传统的三层架构一样，一个典型的GIS系统也是由三部分组成：客户端，服务器，存储。在实际的场景中，可能又会引入缓存服务器，负载均衡服务器等。

![image](/images/2014/04/gis-stack-resized.png)

1.  [OpenLayers](http://openlayers.org/) / Leaflet
2.  [Mapnik](http://mapnik.org/) / Mapnik::OGCServer
3.  [Postgres](http://www.postgresql.org/) + [PostGIS](http://postgis.net/) / OSM Data / Shapefiles

[OpenLayers](http://openlayers.org/)是一个前端的JavaScript库，几乎可以算是前端的必选了，它提供众多的特性：与任意的后端地图服务集成（Google Maps，Bing Maps，OSM等等），对向量层的支持使得其非常方便的展示用户自定义的元素（多边形，点，InfoWindow等）。OpenLayers的API也非常清晰易用：


```js
$(function() {
    var map = new OpenLayers.Map('map', {});

    var layer = new OpenLayers.Layer.WMS('Tile Cache', 
        'tilecache?', {
            layers: 'basic',
            format: 'image/png'
        });
    
    map.addLayer(layer);
});
```

1.	创建Map对象
2.	创建Layer对象
3.	将Layer添加到Map上

即可完成基本的设置，并将地图展现在页面上。

[OSM](http://www.openstreetmap.org/)是Open Street Map的缩写，它本身是一个开源项目，全世界各地的贡献者可以很方便的编辑地图信息，并与其他人分享，整个运作方式非常像Wikipedia，任何人都可以对地图进行编辑。基于这个原因，OSM数据文件是基于XML的。

有很多组织都将OSM的数据下载下来，搭建自己的地图服务器，然后向外部提供[WMS(Web Map Service)](http://en.wikipedia.org/wiki/Web_Map_Service)服务。

Mapnik是一个渲染引擎，它可以将地理数据渲染成图片。Mapnik支持来自多种数据源的数据，比如Shapefile，PostGIS中的数据等。而对于OSM数据（一种XML文件），可以使用[osm2postgis](https://github.com/openstreetmap/osm2pgsql)工具将其导入到PostGIS数据库，然后使用。

Mapnik本身只是一个C++编写的渲染引擎，并提供很多编程语言的bind，最常用的时python版本的bind，接口非常清晰明了。使用Mapnik可以很容易的定制对地图层次的样式，比如地图中所有土地的颜色，河流的颜色，道路的颜色，标签的字体，属性等等都可以很方便的定制。

实际使用Mapnik+OpenLayers搭建自己的服务器将在下一篇文章中详细描述。

##### 一些数据源

1.	[Natural Earth](http://www.naturalearthdata.com/)
2.	[GEO Fabrik](http://download.geofabrik.de/osm/)