---
layout: post
title: "从一个小例子学习TDD"
date: 2014-11-09 15:07
comments: true
categories: 
- TDD
- ThoughtWorks

---
### 示例的需求描述

今天我们需要完成的需求是这样的：

对于一个给定的字符串，如果其中`元音`字母数目在整个字符串中的比例超过了30%，则将该`元音`字母替换成字符串`mommy`，额外的，在替换时，如果有连续的元音出现，则仅替换一次。

如果用`实例化需求`([Specification by Example](http://specificationbyexample.com/))的方式来描述的话，需求可以转换成这样几条实例：

1.	`hmm`经过处理之后，应该保持原状
2.	`she`经过处理之后，应该被替换为`shmommy`
3.	`hear`经过处理之后，应该被替换为`hmommyr`

当然，也可以加入一些边界值的检测，比如包含数字，大小写混杂的场景来验证，不过我们暂时可以将这些场景抛开，而仅仅关注与TDD本身。

#### 为什么选择这个`奇怪的`例子

我记得在学校的时候，最害怕看到的就是书上举的各种离`生活`很远的例子，比如国外的书籍经常举汽车的例子，有引擎，有面板，但是作为一个只是能看到街上跑的车的穷学生，实际无法理解其中的关联关系。

其实，另外一种令人不那么舒服的例子是那种纯粹为了示例而编写的例子，现实世界中可能永远都不可能见到这样的代码，比如我们今天用到的例子。

当然，这种纯粹的例子也有其存在的价值：在脱离开复杂的细节之后，尽量的让读者专注于某个方面，从而达到对某方面练习的目的。因为跟现实完全相关的例子往往会变得复杂，很容易让读者转而去考虑复杂性本身，而忽略了对实践/练习的思考。

#### TDD步骤

通常的描述中，`TDD`有三个步骤：

1.	先编写一个测试，由于此时没有任何实现，因此测试会失败
2.	编写实现，以最快，最简单的方式，此时测试会通过
3.	查看实现/测试，有没有改进的余地，如果有的话就用重构的方式来优化，并在重构之后保证测试通过

![tdd](/images/2014/11/tdd.png)

它的好处显而易见：

1.	时时关注于实现功能，这样不会跑偏
2.	每个功能都有测试覆盖，一旦改错，就会有测试失败
3.	重构时更有信心，不用怕破坏掉已有的功能
4.	测试即文档，而且是不会过期的文档，因为一旦实现变化，相关测试就会失败

使用`TDD`，一个重要的实践是`测试先行`。其实在编写任何测试之前，更重要的一个步骤是`任务分解`(Tasking)。只有当任务分解到恰当的粒度，整个过程才可能变得比较顺畅。

回到我们的例子，我们在知道整个需求的前提下，如何进行任务分解呢？作为`实现优先`的程序员，很可能会考虑诸如空字符串，元音比例是否到达30%等功能。这当然没有孰是孰非的问题，不过当需求本身就很复杂的情况下，这种直接面向实现的方式可能会导致越走越偏，考虑的越来越复杂，而耗费了几个小时的设计之后发现没有任何的实际进度。

如果是采用`TDD`的方式，下面的方式是一种可能的任务分解：

1.	输入一个非元音字符，并预期返回字符本身
2.	输入一个元音，并预期返回`mommy`
3.	输入一个元音超过30%的字符串，并预期元音被替换
4.	输入一个元音超过30%，并且存在连续元音的字符串，并预期只被替换一次

当然，这个任务分解可能并不是`最好的`，但是是一个比较清晰的分解。

### 实践

#### 第一个任务

在本文中，我们将使用JavaScript来完成该功能的编写，测试框架采用了[Jasmine](http://jasmine.github.io/2.0/introduction.html)，这里有一个[模板项目](https://github.com/abruzzi/tdd-boilerplate)，使用它你可以快速的启动，并跟着本教程一起实践。

根据任务分解，我们编写的第一个测试是：

```js
describe("mommify", function() {
	it("should return h when given h", function() {
		var expected = "h";

		var result = mommify("h");

		expect(result).toEqual(expected);
	});
});
```

这个测试中有三行代码，这也是一般测试的标准写法，简称`3A`：

1.	组织数据（Arrange）
2.	执行需要被测的函数（Action）
3.	验证结果（Assertion）

运行这个测试，此时由于还没有实现代码，因此Jasmine会报告失败。接下来我们用最快速的方法来编写实现，就目前来看，最简单的方式就是：

```js
function mommify() {
	return "h";
}
```

可能有人觉得这种实现太过狡猾，但是从`TDD`的角度来说，它确实能够令测试通过。这时候，我们需要编写另外一个测试来`驱动`出正确的行为：

```js
it("should return m when given m", function() {
    var expected = "m";

    var result = mommify("m");

    expect(result).toEqual(expected);
});
```

这样，我们的实现就不能仅仅返回一个"h"了，就现在来看，最简单的方式是输入什么就返回什么：

```js
function mommify(word) {
	return word;
}
```

很好，这样我们的第一个`任务`已经完成了！我们已经经历了`失败-成功`的循环，这时候需要`review`一下代码，以保证代码是干净的：实现上来说，并没有可以优化的地方，但是我们发现两个测试用例其实测试的是同一件事情，因此可以删掉一个。

是的，测试代码也是代码，我们需要小心的维护它，以保证所有的代码都是干净的。

#### 第二个任务

我们可以开始元音字母的子任务了，很容易想到的一个测试用例为：

```js
it("should return mommy when given a", function() {
    var expected = "mommy";

    var result = mommify("a");

    expect(result).toEqual(expected);
});
```

测试失败之后，能想到的最快速的方式是做一个简单的判断：

```js
function mommify(word) {
	if(word == "a") {
    	return "mommy";
    }
	return word;
}
```

这样测试又会通过，接下来就是重复5个元音的场景，不过使用JavaScript可以很容易的将这5个场景归为一组：

```js
it("should return mommy when given a vowel", function() {
    var expected = "mommy";

	["a", "e", "i", "o", "u"].forEach(function(word) {
	    var result = mommify(word);
    	expect(result).toEqual(expected);
    });
});
```

而实现则对一个的会变成（记住，用最简单的方式）：

```js
function mommify(word) {
	if(word == "a" || word == "e" || word == "i" || word == "o" || word == "u") {
    	return "mommy";
    }
	return word;
}
```

好了，测试通过了。又是进行重构的时间了，现在看看实现，简直不忍卒读，我们使用JavaScript的字符串的`indexOf`方法可以简化这段代码：

```js
function mommify(word) {
	if("aeiou".indedOf(word) >= 0) {
    	return "mommy";
    }
	return word;
}
```

好多了！我想你现在已经或多或少的体会到了`TDD`中`任务分解`的好处了：进度可以掌握，而且目标非常明确，每一步都有相应的产出。

#### 第三个任务

和之前一样，我们还是从测试开始：

```js
it("should mommify if the vowels greater than 30%", function() {
    var expected = "shmommy";
    var result = mommify("she");

    expect(result).toEqual(expected);
});
```

现在有一点点挑战了，因为我们的实现上一直都是单一的字符串，现在有多个了，不过没有关系，我们先按照最简单的方式来实现就对了：

```js
function mommify(word) {
	var count = 0;
	for(var i = 0; i < word.length; i++) {
		if("aeiou".indexOf(word[i]) >= 0) {
			count += 1;
		}
	}

	var str = "";

	if(count/word.length >= 0.30) {
		for(var i = 0; i < word.length; i++) {
			if("aeiou".indexOf(word[i]) >= 0) {
				str += "mommy";
			} else {
				str += word[i];
			}
		}
	} else {
		str = word;
	}

	return str;
}
```

无论如何，测试通过了，我们首先计算了`元音`所占的比重，如果超过30%，则替换对应的字符，否则直接返回传入的字符串。

从现在来看，函数`mommify`中已经有了较多的逻辑，而且有一些重复的判断出现了（`"aeuio".indedOf`），是时候做一些重构了。

首先将相对独立的计算元音比重的部分抽取成一个函数：

```js
function countVowels(word) {
	var count = 0;

	for(var i = 0; i < word.length; i++) {
		if("aeiou".indexOf(word[i]) >= 0) {
			count += 1;
		}
	}

	return count;
}
```

然后，将重复的`"aeiou".indexOf`部分抽取为一个独立函数：

```js
function isVowel(character) {
	return "aeiou".indexOf(character) >= 0;
}
```

这样本来的代码就被简化成了：

```js
function mommify(word) {
	var count = countVowels(word);
	var str = "";

	if(count/word.length >= 0.30) {
		for(var i = 0; i < word.length; i++) {
			if(isVowel(word[i])) {
				str += "mommy";
			} else {
				str += word[i];
			}
		}
	} else {
		str = word;
	}

	return str;
}
```

如果细细读下来，就会发现发现对于元音是否超过30%的判断比较突兀，这里确实了一个`业务概念`，就是说，此处的`if`判断并不表意，更好的写法是讲它抽取为一个函数：

```js
function shouldBeMommify(word) {
	var count = countVowels(word);
	return count/word.length >= 0.30;
}
```

并且，替换元音的部分，我们也可以从主函数中挪出来，得到一个小函数：

```js

function replace(word) {
	var str = "";

	for(var i = 0; i < word.length; i++) {
		if(isVowel(word[i])) {
			str += "mommy";
		} else {
			str += word[i];
		}
	}

	return str;
}
```

这样，主函数得到了进一步的简化：

```js
function mommify(word) {
	if(shouldBeMommify(word)) {
		return replace(word);
	} else {
		return word;
	}
}
```

太好了，现在`mommify`就更加清晰了，并且每个抽取出来的函数都有了更具意义的名字，更清晰的职责。

#### 第四个任务

经过了第三步，相信你已经对如何进行`TDD`有了很好的认识，而且也更有信心进行下一个任务了。同样，我们需要先编写测试用例：

```js
it("should not mommify if there are vowels sequences", function() {
    var expected = "shmommyr";
    var result = mommify("shear");

    expect(result).toEqual(expected);
});
```

现在的问题关键是需要判断一个字符串中的前一个是否元音，由于我们之前已经做了足够的重构，现在需要修改的函数就变成了`replace`子函数，而不是主入口`mommify`了：

```js
function replace(word) {
	var str = "";

	for(var i = 0; i < word.length; i++) {
		if(isVowel(word[i])) {
			if(!isVowel(word[i-1])) {
				str += "mommy";
			} else {
				str += "";
			}
		} else {
			str += word[i];
		}
	}

	return str;
}
```

测试通过之后，我们可以大胆的进行重构，抽取新的函数`next`：

```js
function next(current, previous) {
	var next = "";

	if(isVowel(current)) {
		if(!isVowel(previous)) {
			next = "mommy";
		}
	} else {
		next = current;
	}

	return next;
}

function replace(word) {
	var str = "";

	for(var i = 0; i < word.length; i++) {
		str += next(word[i], word[i-1]);
	}

	return str;
}
```

最后，如果你想看完整的/最新的代码，可以[在github上](https://github.com/abruzzi/mommifier)找到。

#### 结束（？）

重构是一个永无止境的实践，你可以不断的抽取，简化，重组。比如上例中对于常量的使用，对于JavaScript中的for的使用等，都可以更进一步。但是你需要权衡，适可而止，如果不小心做的太过，则可能引起过渡设计：引入太过的概念，过于简化的接口等。

`TDD`是一种容易付诸实践的开发方式，在小的，简单的例子上如此，在大的，复杂的场景下也是如此。它优美且高效的地方在于：不假设任何人可以一次就写出完善的应用，而是鼓励小步前进，快速反馈，快速迭代。而演化到最后，得到的往往就是孜孜以求的优美设计。


