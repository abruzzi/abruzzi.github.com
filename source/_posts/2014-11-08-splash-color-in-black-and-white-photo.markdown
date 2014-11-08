---
layout: post
title: "命令行制作黑白+单色照片"
date: 2014-11-08 12:59
comments: true
categories: 
- fun
- photograph

---

### 黑白+单色照片

有很多摄影师通过后期制作出了非常独特的`黑白+单色`照片，并由此来强调被拍摄主题，绿叶中的红花，紫色花朵的黄色花蕊等；的另一方面，这种照片可以强调背景的灰色，比如雾霾中的交通灯。

比如原图是这样的：

![image](/images/2014/11/flower-resized.jpg)

经过处理之后，最终的效果是这样的：

![image](/images/2014/11/flower-final-resized.jpg)

网络上已经有很多的教程来做到这一点，不过都需要使用`photoshop`来完成颜色的抽取，反色，灰化等。当然，作为程序员，特别是命令行控，自然会想到的是使用[图片编辑神器ImageMagick](http://www.imagemagick.org/)来处理。

#### 基本原理

我们都知道，彩色图片都是由3个通道（红，绿，蓝三个）叠加在一起的（如果图片带有透明通道的话，会有4个通道，我们这里略过）形成的。每个通道都是一张灰度图，并且会根据图片实际的色彩，在不同程度上有明暗差异。

比如上图的花朵，如果我们将jpg本身的RGB分离开，就会得到3张不同的灰度图：

红色通道灰度图：

![red](/images/2014/11/flower-red-resized.jpg)

绿色通道灰度图：

![green](/images/2014/11/flower-green-resized.jpg)

蓝色通道灰度图：

![blue](/images/2014/11/flower-blue-resized.jpg)

由于原图绿色和紫红色为主要色彩，所以在红色通道中，花朵比较偏向白色，蓝色通道中花朵也会偏向白色，因为紫红色包含红色和蓝色的亮度都比较高，而在绿色通道中，叶子的颜色则更偏向白色一些。

#### 图片的加减

有了灰度图，我们就可以通过不同通道的加减来加强某些色彩，比如蓝色通道和红色通道相减之后，绿色就会被过滤掉，因为绿色在红色和蓝色通道中都表现为灰色：

![minus](/images/2014/11/flower-minus-resized.jpg)

这时候，我们已经有了花瓣的轮廓，但是还是有些模糊，我们还需要将其二值化。这样做出来的图片被称为`mask`，这个`mask`和最终的图片叠加之后，才会将我们关注的部位凸现出来。

![mask](/images/2014/11/flower-mask-resized.jpg)

### 实现

ImageMagick提供的命令行工具`convert`非常强大，我们这里只是用其中很简单的几个：

	1.	图片通道的分离
    2.	图片相加减
    3.	叠加多个图片为一个

要分离一张RGB的图片，只需要指定：

```sh
$ convert flower.jpg -separate flower_rgb_%d.jpg
```

这条命令会把图片flower.jpg分离成三张图片，命令中的`%d`占位符会自动被展开为`1,2,3`这样的数字，这样这条命令会生成3章图片：flower_rgb_0.jpg,flower_rgb_1.jpg,flower_rgb_2.jpg。

图片的相减也很方便，使用命令：

```sh
$ convert flower_rgb_2.jpg flower_rgb_0.jpg -compose minus \
-composite flower_minus.jpg
```

来完成。得到差值文件之后（已经具备了基本轮廓，如果不理想，可以换一个通道试试），就可以进一步二值化了。

命令

```sh
$ convert flower_minus.jpg -level 10%,30% flower_mask.jpg
```

用来生成`mask`文件，其中10%表示亮度低于10%的点会被认为是黑色，而30%则表示亮度高于30%的点会被认为是白色，这样的出来的图片就是只有黑白两种颜色了。

最后，我们需要将不同的图片合并在一起，形成最终的结果：

```sh
$ convert flower_rgb_2.jpg flower.jpg flower_mask.jpg -composite flower_final.jpg
```

注意这里的次序，先是蓝色通道，然后是原图，最后是`mask`。这样`composite`的结果就是我们最开始看到的了：

![image](/images/2014/11/flower-final-resized.jpg)

再来看另外一张用同样方式生成的图片：

![image](/images/2014/11/bird-final-resized.jpg)

