---
layout: post
title: "ThoughtWorks洞见讲什么？"
date: 2017-03-12 22:03
comments: true
categories: 
- ThoughtWorks
- visualization
- data
- infovis
---

## ThoughtWorks洞见

[ThoughtWorks洞见](http://insights.thoughtworkers.org/)是ThoughtWorks的一个媒体渠道，汇集了来自ThoughtWorks最优秀的经验和思考，并分享给真正对软件有意愿思考和不断改进的人（修改自官方版本）。

截至目前为止，ThoughtWorks洞见已经汇集了50余位作者的300+篇文章（就在刚才，又有一篇更新）。那么这些文章中都在讨论什么样的话题呢？这篇文章将通过一些技术手段，提取出洞见中的关键字，然后采用可视化的方式呈现出来。

### 数据获取

本来我打算从`RSS`上读feed，解析出文章的`link`，再将所有文章爬一遍，最后保存到本地。不过写了几行代码后发现`Wordpress`(ThoughtWorks洞见目前托管在一个Wordpress上)默认地只输出最新的`feed`，这对于关键字提取来说数量远远不够。众所周知，语料库越大，效果越好。

既然是洞见本质上来说就是一个静态站点，那么最简单、最暴力的方式就是直接把站点克隆到本地。这一步通过使用`wget`可以很容易做到：

```sh
wget --mirror -p --html-extension --convert-links -e robots=off -P . \
http://insights.thoughtworkers.org/
```

默认地，`wget`会以站点的完整域名为目录名，然后保存整个站点到本地。我大概看了一下，其实不需要所有的目录，只需要一个层次即可，所以这里用`find`来做一个过滤，然后将文件名写到一个本地文件`filepaths`中。

```sh
find insights.thoughtworkers.org/ -name index.html -depth 2 > filepaths
```

这个文件的内容是这样的：

```
insights.thoughtworkers.org/10-common-questions-of-ba/index.html
insights.thoughtworkers.org/10-tips-for-good-offshore-ba/index.html
insights.thoughtworkers.org/10-ways-improve-your-pairing-experience/index.html
insights.thoughtworkers.org/100-years-computer-science/index.html
insights.thoughtworkers.org/1000-cars-improve-beijing-transportation/index.html
insights.thoughtworkers.org/3d-printing/index.html
insights.thoughtworkers.org/4-advices-for-aid/index.html
insights.thoughtworkers.org/5-appointments-with-agile-team/index.html
insights.thoughtworkers.org/5-ways-exercise-visual-design/index.html
insights.thoughtworkers.org/7-step-agenda-effective-retrospective/index.html
insights.thoughtworkers.org/a-decade/index.html
insights.thoughtworkers.org/about-team-culture/index.html
insights.thoughtworkers.org/about-tw-insights/index.html
insights.thoughtworkers.org/agile-coach/index.html
insights.thoughtworkers.org/agile-communication/index.html
insights.thoughtworkers.org/agile-craftman/index.html
...
```

### 数据处理

这样我就可以很容易在python脚本中读取各个文件并做处理了。有了文件之后，需要做这样一些事情：

1.  抽取HTML中的文本信息
1.  将文本分词成列表
1.  <del>计算列表中所有词的[TFIDF](https://zh.wikipedia.org/wiki/Tf-idf)值</del>
1.  计算每个词出现的频率
1.  将结果持久化到本地

这里需要用到这样一些pyhton库：

1.  BeautifulSoap 解析HTML文档并抽取文本
1.  jieba 分词
1.  sk-learn 计算单词出现频率
1.  pandas 其他数据处理


```py
def extract_post_content(file):
    soup = BeautifulSoup(open(file).read(), "html.parser")
    return soup.find('div', attrs={'class': 'entry-content'}).text

def extract_all_text():
    with open('filepaths') as f:
        content = f.readlines()

    file_list = [x.strip() for x in content]
    return map(extract_post_content, file_list)

def extract_segments(data):
    seg_list = jieba.cut(data, cut_all=False)
    return [seg.strip() for seg in seg_list if len(seg) > 1]


def keywords_calc():        
    corpus = [" ".join(item) for item in map(extract_segments, extract_all_text())]

keywords_calc()
```

`extract_post_content`函数用来打开一篇博客的HTML文件，并提取其中的`div.entry-content`中的文本内容。`extract_all_text`函数用来对文件`filepaths`中的每一行（一篇洞见文章的本地文件路径）都调用一次`extract_post_content`。而函数`extract_segments`会使用`jieba`来对每篇文章进行分词，并生成一个单词组成给的列表。最后，在函数`keywords_calc`中，通过一个列表推导式来生成语料库。

有了语料库之后，很容易使用`sk-learn`来进行计算：

```py
def keywords_calc():        
    corpus = [" ".join(item) for item in map(extract_segments, extract_all_text())]
    
    with open('stopwords-utf8.txt') as f:
        content = f.readlines()

    content.extend(['来说', '事情', '提供', '带来', '发现'])
    stopwords = [x.strip().decode('utf-8') for x in content]

    vectorizer = CountVectorizer(stop_words=stopwords)
    fit = vectorizer.fit_transform(corpus)
```

当然，由于处理的是中文，我们需要提供`停止词`来避免对无意义的词的统计（`这个`，`那个`，`然后`等等基本上每篇都会出现多次的词）。在经过`transform`之后，我们就得到了一个稀疏矩阵和词汇表，以及对应的tdidf的值，我们使用`pandas`提供的DataFrame来进行排序和存储即可：

```py
def keywords_calc(): 
	
	#...   
    data = dict(zip(vectorizer.get_feature_names(), fit.toarray().sum(axis=0)))
    top_100 = DataFrame(data.items(), columns=['word', 'freq'])
        .sort_values('freq', ascending=False).head(100)
    top_100.to_csv('top-100-words-most-used-in-tw-insights.csv')
```

运行结果如下：

```
index,word,freq
18761,团队,1922
12479,测试,1851
4226,开发,1291
1910,服务,1288
10531,技术,1248
7081,用户,1145
17517,代码,1078
12712,项目,1062
4957,需求,1049
...
```

### 可视化

#### 单词云

```js
d3.csv('top-20-words-in-tw-insight.csv', function(err, data) {
    data.forEach(function(d) {
        d.freq = +d.freq
    });

    d3.layout.cloud().size([1600, 900])
        .words(data)
        .rotate(0)
        .fontSize(function(d) { return Math.round(d.freq/10); })
        .on("end", draw)
        .start();

});
```

这里我直接使用了一个第三方的单词云插件`d3.layout.cloud`，提供一个callback函数`draw`，当布局结束之后，插件会调用这个回调：

```js
function draw(words) {
    d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("class", "wordcloud")
        .append("g")
        .attr("transform", "translate(" + width/2 + "," + height/2 +")")
        .selectAll("text")
        .data(words)
        .enter().append("text")
        .style("font-size", function(d) { return Math.round(d.freq/10) + "px"; })
        .style("fill", function(d, i) { return color(i); })
        .attr("transform", function(d) {
            return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
        })
        .text(function(d) { return d.word; });
}
```

![](/images/2017/03/tw-insights-color-18-resized.png)

#### 背景图制作

```sh
mkdir -p authors/ && cp wp-content/authors/* authors/
cd authors
mogrify -format png *.jpg 
rm *.jpg
```

将作者的头像制作成一张9x6的大`蒙太奇`图：

```sh
montage *.png  -geometry +0+0 -resize 128x128^ -gravity center -crop 128x128+0+0 -tile 9x6 \
	tw-insight-authors.png
```

![](/images/2017/03/tw-insight-authors-resized.png)

#### 后期处理

![](/images/2017/03/tw-insights-12-resized.png)

可以看出，ThoughtWorks洞见中最为关键（Top 10）的信息依次是：

```
团队
测试
开发
服务
技术
用户
代码
项目
需求
工作
```

这个和ThoughtWorks的专业服务公司的属性基本吻合。不过前20里竟然没有诸如`敏捷`，`精益`这些原本以为会入围的词。

#### 完善

基本的图形设计完成之后，再加入一些视觉元素，比如ThoughtWorks的标志性图案（代表开发文化和多样性），以及对应的说明性文字（文字的大小也错落开，和文字云遥相呼应）：

![](/images/2017/03/tw-insights-16-resized.png)

### 资料

文中使用了比较简单的`CountVectorizer`做统计，`sk-learn`还提供了其他的向量化机制。我使用`TdidfVectorizer`做了一些计算，不过可能由于语料库的尺寸原因，效果比较奇怪，就暂时没有采用这种方式。

不过，使用`TDIDF`来做关键词抽取在文本处理上也算是必备的技能，这里列一些参考资料，有兴趣的可以进行进一步的探索。

1.  [完整的代码](https://github.com/abruzzi/tw-insights-viz)在此。
1.  阮一峰老师对[TFIDF的解释文章](http://www.ruanyifeng.com/blog/2013/03/tf-idf.html)
1.  陈皓（左耳朵耗子）对[TFIDF的解释文章](http://coolshell.cn/articles/8422.html)
