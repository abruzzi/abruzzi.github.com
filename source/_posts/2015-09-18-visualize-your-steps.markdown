---
layout: post
title: "可视化你的足迹"
date: 2015-09-18 13:36
comments: true
categories: 
- GIS
- Data
- Visualization
---

### 可视化你的足迹

数据可视化可以让读者以一种轻松的方式来消费数据，人类大脑在处理图形的速度是处理文本的`66,000`倍，这也是人们常常说的`一图胜千言`。在本文中，我们通过将日常中很容易收集到的数据，通过一系列的处理，并最终展现在地图上。这仅仅是GIS的一个很简单场景，但是我们可以看到，当空间数据和地图结合在一起时，可以在可视化上得到很好的效果，读者可以很容易从中获取信息。

![steps](/images/2015/09/viz-steps-resized.png)

我们在本文中会制作一个这样的地图，图中灰色的线是城市中的道路，小六边形表示照片拍摄地。颜色表示当时当地拍摄照片的密度，红色表示密集，黄色为稀疏。可以看到，我的活动区域主要集中在左下角，那是公司所在地和我的住处，:)

要展现数据，首先需要采集数据，不过这些已经在日常生活中被不自觉的被记录下来了：

#### 数据来源

如果你开启了iPhone相机中的定位功能，拍照的时候，iPhone会自动把当前的地理信息写入到图片的元数据中，这样我们就可以使用这些数据来做进一步的分析了。

我在去年学习OpenLayers的时候已经玩过一些简单的[足迹可视化](http://icodeit.org/placesihavebeen)，另外还有一篇[全球地震信息的可视化](http://www.infoq.com/cn/articles/visualization-of-the-global-seismic-system)，但是仅仅是展示矢量信息，并没有深入，而且都是一些前端的JavaScript的代码。最近又在重新整理之前的GIS知识，重新把这个作为例子来练手。当然，这次会涉及一些**地图编辑**，**空间计算**的内容。

我的照片一般都通过Mac自带的Photos管理（前身iPhoto），手机里照片会定期同步上去。老版本的iPhoto用的是XML文件来存储照片的[EXIF数据](https://en.wikipedia.org/wiki/Exchangeable_image_file_format)，新的Photos的实现里，数据被存储在了好几个SQLite数据库文件中，不过问题不大，我们只需要写一点Ruby代码就可以将数据转化为标准格式，这里使用GeoJSON，GeoJSON既可以方便人类阅读，也可以很方便的导入到PostGIS或者直接在客户端展现。

### 实现步骤

我们现在要绘制照片拍摄的密度图，大概需要这样一些步骤：

1.  抽取照片的EXIF信息（经度，纬度，创建时间等）
2.  编写脚本将抽取出来的信息转换成通用格式（GeoJSON）
3.  使用QGIS将这些点的集合导入为图层
4.  插入一些由六边形组成的图层（设置合适的大小）
5.  计算落在各个多边形中的点的个数，并生成新的图层heatmap
6.  使用MapServer来渲染基本地图

#### 数据抽取

Mac上的Photos会将照片的元数据存储在一个SQLite3格式的数据库中，文件名为`Library.apdb`，通常位于这个位置`~/Pictures/Photos\ Library.photoslibrary/Database/apdb/Library.apdb`。这个文件可以通过`SQLite3`的客户端直接打开，不过由于可能有其他进程（Mac自己的）打开了该文件，所以会有锁文件，你可能需要先将这个文件拷贝到另外一个位置。

然后将表`RKVersion`中的部分信息导出即可，SQLite内置了很方便的导出功能，通过它提供的shell客户端`sqlite3`，将信息导出到csv文件中：

```sh
sqlite> .mode csv
sqlite> .headers on
sqlite> .output places-ive-been.csv 
sqlite> select datetime(imageDate+978307200, 'unixepoch', 'localtime') as imageDate, exifLatitude, exifLongitude from RKVersion where exifLatitude and exiflongitude;
sqlite> .output stdout
```

注意这里的日期，苹果的日期偏移和其他公司不同，始于2001年1月1日，所以要在`imageDate`之后加上这个`base`值，然后将文件以`.csv`的格式导出到`places-ive-been.csv`中，该文件包含3列：时间，纬度，精度。

```sh
imageDate,exifLatitude,exifLongitude
"2012-10-25 16:34:01",34.19216667,108.87316667
"2012-10-28 14:45:53",35.1795,109.9275
"2012-10-28 14:45:45",35.1795,109.9275
"2012-10-25 16:34:04",34.19216667,108.87316667
"2012-10-19 23:01:05",34.19833333,108.86733333
...
```

#### 转换为GeoJSON

方便以后的转换起见，我们将这个文件转换成`GeoJSON`（其实很多客户端工具可以支持CSV的导入，不过`GeoJSON`更为标准一些）。

```ruby
require 'csv'
require 'json'

lines = CSV.open("places-ive-been.csv").readlines
keys = lines.delete lines.first

File.open("places-ive-been.json", 'w') do |f|
    data = lines.map do |row|
        {
            :type => "Feature",
            :geometry => {
              :type => "Point",
              :coordinates => [row[2].to_f, row[1].to_f]
            },
            :properties => {
              :created_at => row[0]
            }
        }
    end

    f.puts JSON.pretty_generate({
        :type => "FeatureCollection",
        :crs => {
          :type => "name",
          :properties => {
            :name => "EPSG:4326"
          }
        },
        :features => data
    })
end
```

这段脚本可以将我们的`.csv`转换成标准的`geojson`格式，注意此处的空间投影使用的是`EPSG:4326`。

#### 导入为QGIS图层

[QGIS](http://www.qgis.org/en/site/)是一个开源的GIS套件，包括桌面端的编辑器和服务器端，这里我们只是用器桌面端来进行图层的编辑。

将我们的`GeoJSON`导入之后，会看到这样的一个可视化的效果！

![points](/images/2015/09/points-resized.png)

我们还可以导入其他的地图图层，这样可以清楚的看到点所在的区域（国家地图图层可以在[此处下载](http://www.naturalearthdata.com/)）：

![points with countries](/images/2015/09/points-countries-resized.png)

好了，有了基础数据之后，我们来作进一步的数据分析 -- 即生成密度图。首先使用QGIS的插件`MMQGIS`的**生成多边形图层**功能(Create -> Create Grid Layer)，为了处理速度，我们可以将地图放大到一定范围（我选择西安市，我在这里活动比较密集）。

选择六边形`hexagon`，并设置合适的大小（如果是`3857`参考系，即按照公里数来设置，会比较容易一些，如果是4326，则需要自己计算）。简而言之，需要保证每个格子都包含一些点，不至于太密，也不至于太稀疏。

![hexagon](/images/2015/09/hexagon-resized.png)

#### 计算密度

QGIS提供了很多的数据分析功能，我们在这个例子中使用（Vector -> Analysis Tools -> Points in Polygon）工具，这个工具需要两个图层，一个是点集图层，一个是多边形图层。然后会将结果生成到一个新的图层中，我们可以将其命名为`places-ive-been-density.shp`，同时需要指定一个字段来存储统计出来的值（density）。

这个过程可能会花费一点时间，根据需要计算的点集合多边形的格式（也就是地图上的区域）。

完成之后会得到一个`Shapefile`（其实是一组，具体可以[参看这里](https://en.wikipedia.org/wiki/Shapefile)）。其实在这个过程中，绝大多数多边形是不包含任何数据的，我们需要过滤掉这些多余的多边形，这样可以缩减绘制地图的时间。

我们可以将这个文件导入到PostGIS中进行简化：

```sh
shp2pgsql -I -s 4326 data/places-ive-been/places-ive-been-3857-density.shp places_density |\
PGUSER=gis PGPASSWORD=gis  psql -h localhost -d playground
```

这里的`shp2pgsql`命令是[GDAL工具包](http://)提供的命令，用以将`Shapefile`导入到`PostGIS`中，你可以通过

```sh
$ brew install gdal --with-postgresql
```

来安装。

GDAL会提供很多的工具，比如用来转换各种数据格式，投影，查看信息等等。

导入之后，我们可以在PostGIS的客户端查看，编辑这些数据等。比如在过滤之前，

```sql
select count(*) from places_density;
```

我们导入的数据中有`103166`条记录：

```sql
select count(*) from places_density where density IS NOT NULL;
```

而过滤之后，我们仅剩下`749`条数据。

通过GDAL提供的另一个工具`ogr2ogr`可以方便的执行过滤，并生成新的`Shapefile`:

```sh
$ ogr2ogr -f "ESRI Shapefile" data/places-ive-been/places_heatmap.shp \
PG:"host=localhost user=gis dbname=playground pass
word=gis" \
-sql "SELECT density, geom FROM places_density WHERE density IS NOT NULL;"
```

这条命令可以得到一个新的文件，这个就是最终的用来绘制地图的文件了。


#### 绘制地图

开源世界中有很多的工具可以完成地图的绘制，比如[MapServer](http://mapserver.org/)，[GeoServer](http://geoserver.org/)，[Mapnik](http://mapnik.org/)等等。我们在这篇文章中使用MapServer来完成地图的绘制，MapServer的安装和配置虽然比较容易，但是也需要花费一些时间，所以我将其放到了[这个repo中](https://github.com/abruzzi/mapserver-box)，你可以直接clone下来使用。（需要你在虚拟机中安装ansible来完成provision）。

MapServer的配置很简单，类似于一个XML，不过是自定义的格式：

```
MAP
  IMAGETYPE      PNG
  EXTENT         11859978.732852 3994742.227345 12753503.595559 4580388.268737
  SIZE           8000 6000
  SHAPEPATH      "/data/heatmap"
  IMAGECOLOR     255 255 255

  PROJECTION
    "init=epsg:3857"   ##required
  END

  LAYER # States polygon layer begins here
    NAME         heatmap
    DATA         heatmap_3857
    STATUS       default
    TYPE         POLYGON

    CLASS
      NAME "basic"
      STYLE
        COLOR        255 255 178
        OUTLINECOLOR 255 255 178
      END
    END
  END

END
```

这些配置基本上都比较自解释，比如设置图片格式，图片大小，Shapefile的路径，图层的名称等，**MapServer的文档在开源软件中来说，都算比较烂的**，但是对于这些基本概念的解释还比较详尽，大家可以[去这里参考](http://mapserver.org/documentation.html#documentation)。

这里我们定义了一个图层，每个Map中可以定义多个图层（我们完成的最终效果图就是西安市的道路图和照片拍摄密度图两个图层的叠加）。

这个配置绘制出来的地图是没有颜色差异的，全部都是`255 255 178`。不过MapServer的配置提供了很好的样式定义，比如我们可以定义这样的一些规则：

1.  如果密度为1，则设置颜色为淡黄
2.  如果密度在1-2,则设置为比淡黄红一点的颜色
3.  以此类推

```
  LAYER
    NAME         heatmap
    DATA         heatmap_3857
    STATUS       default
    TYPE         POLYGON
    #CLASSITEM density

    CLASS
      EXPRESSION ([density] = 1)
      STYLE
        COLOR        255 255 178
        OUTLINECOLOR 255 255 178
      END
    END

    CLASS
      EXPRESSION ([density] > 1 AND [density] <= 2)
      STYLE
        COLOR        254 204 92
        OUTLINECOLOR 254 204 92
      END
    END

    CLASS
      EXPRESSION ([density] > 2 AND [density] <= 3)
      STYLE
        COLOR        253 141 60
        OUTLINECOLOR 253 141 60
      END
    END

    CLASS
      EXPRESSION ([density] > 3 AND [density] <= 10)
      STYLE
        COLOR        240 59 32
        OUTLINECOLOR 240 59 32
      END
    END

    CLASS
      EXPRESSION ([density] > 10 AND [density] < 3438)
      STYLE
        COLOR        189 0 38
        OUTLINECOLOR 189 0 38
      END
    END

  END
```

这样我们的地图展现出来就会比较有层次感，而且通过颜色的加深，也能体现`热图`本身的含义。

如果

### 总结

我们通过使用一些开源工具（MapServer，QGis，PostGIS，GDAL等），构建出一个基于GIS的数据可视化框架。在这个stack上，我们可以很容易的将一些其他数据也通过可视化的方式展现出来（公用自行车站点分布，出租车分布等等）。MapServer可以发布标准的WMS服务，因此可以很好的和客户端框架集成，从而带来更加友好的用户体验。
