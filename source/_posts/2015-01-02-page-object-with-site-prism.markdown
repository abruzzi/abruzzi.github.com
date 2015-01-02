---
layout: post
title: "编写体面的UI测试"
date: 2015-01-02 13:58
comments: true
categories: 
- Ruby
- Test
---

### PageObject简介

`PageObject`是编写UI测试时的[一种模式](http://martinfowler.com/bliki/PageObject.html)。简而言之，你可以将所有知道页面细节的部分放入到这个对象上，对于编写测试的人来说，一个`PageObject`代表了一个页面，或者页面上的一个区域（比如搜索框，搜索结果，侧边栏等都可能是一个独立的`Object`）。这样做的好处分为两个方面：

1.  封装了所有的实现细节（内部的HTML是如何组织的）
2.  对外的接口非常清晰，从而代码更加语义化

我们这里列举一个简单的例子来说明：

我们要测试的场景是：我们在一个搜索应用中，用户输入了`ThoughtWorks`，我们来判断搜索结果的第一页有`10`条结果。如果使用原生的`capybara`，代码大致会如下：

```rb
visit '/search'

fill_in 'Search', :with => 'ThoughtWorks'
click_button '#search'

expect(find('#result').find('.tips')).to have_content("10")
```

首先我们进入`/search`页面，然后在`Search`中输入了`ThoughtWorks`关键字，然后点击`#search`按钮，最后判断`#result .tips`下有`10`的字样。

如果使用`PageObject`，代码则会变成（*这个是伪代码*）：

```rb
search = SearchBox.new
result = SearchResult.new

search.type "ThoughtWorks"
expect(result.count).to eq(10)
```

### site_prism 简介

[site_prism](https://github.com/natritmeyer/site_prism)是一个构建在[capybara](https://github.com/jnicklas/capybara)之上的用于建模`Page Object`的gem。使用`site_prism`可以很语义化的编写`Page Object`，可以使代码非常易读。

位于`顶层`的`Page`对象可以拥有多个`Section`对象，每个`Section`可以对应页面上的一些逻辑上的块，比如内容区域，边栏等。对于现在流行的`SPA`，我们只需要一个`Page`和若干个`Section`就足够了。

```rb
class MovingHome < SitePrism::Page
	set_url 'http://localhost:8100/bundles/moving-home'

	element :container, "#tmsCheckout"

	section :personal, PersonalSection, "#acc-personal"
	section :contact, ContactSection, "#acc-contact"
end
```

`set_url`方法制定了如何到达当前页，也是`webdriver`会实际发送请求的`URL`。页面本身上可以用`element`方法来声明一个元素，以及该元素对应的CSS选择器，这样就可以通过元素的名称来访问该选择器对应的HTML元素了。

比如上例中的`container`，我们在测试中就可以这样来访问它：

```rb
@moving = MovingHome.new
@moving.load

@moving.container.should be_visible
```

而对应的`section`元素，则声明了一个块的名称，块的类和块的选择器。这样我们就可以通过名称来应用该块了：

```rb
@moving.personal.name.set "Juntao"

expect(@moving).to have_personal
expect(@moving).to have_contact

```

`have_`前缀加块的名称，用来判断该块是否可见（比如display: block）。

### 一个项目上的实例

目前项目上有一个页面需要添加一些新的特性，对应的需要添加一些UI测试。之前的所有代码都是面向过程的，代码非常多，重复代码都通过抽成一个函数来组织，无法和实际的页面模块对应起来。因此我使用`site_prism`做了一些尝试。

业务场景是这样的：用户想要办理移机业务（比如搬家了，相应的宽带/有线电视要办理移机），这时候用户需要填写一些个人信息，联系方式，老地址，新地址等，这样我们就可以联系到他并帮他完成移机。而目前的页面也已经按照这些信息的关联度组织成了这样的形式：

![moving home](/images/2015/01/moving-home-resized.png)

可以看到，页面本身的组织已经比较清晰了，这非常方便我们抽取`PageObject`：每一个`块`都可以抽取为一个`Section`类的子类。

#### 第一次尝试

比如对于个人信息这一个块：

![personal](/images/2015/01/personal-resized.png)

这个块包含称呼，姓名，出生日期等几部分，我们可以很容易找到对应的页面元素，并抽取为：

```rb
class PersonalSection < SitePrism::Section
	element :myservice, "#personal-my-services"

	element :title, "#personal\\.title"
	element :first, "#personal\\.firstName"
	element :last, "#personal\\.lastName"

	element :dob_day, "#personal\\.dobDay"
	element :dob_month, "#personal\\.dobMonth"
	element :dob_year, "#personal\\.dobYear"

	element :summary, ".tms-accordion-summary-content"
	element :next, ".tms-btn-next"
end
```

最直接的使用方法就是直接调用`set`方法：

```rb
def fulfill_personal
	@moving.personal.myservice.set "MINE"
	@moving.personal.title.select "Mr"
	@moving.personal.first.set "Juntao"
	@moving.personal.last.set "Qiu"

	@moving.personal.dob_day.select "21"
	@moving.personal.dob_month.select "Jan"
	@moving.personal.dob_year.select "1985"

	@moving.personal.next.click
end
```

这样在`Cucumber`测试中就可以写成：

```rb
Given /I am on moving home page/ do 
	@moving = MovingHome.new
  	@moving.load
end

When /I fulfill my personal information/ do
	fulfill_personal
end
```

#### 面向对象

这样的代码事实上已经沦为了面向过程的方式了，更好的做法是讲fulfill_personal放入`Personal`本身中：

```rb
def fulfill(personal)
	myservice.set personal["myservice"]
	title.select personal["title"]
	first.set personal["first"]
	last.set personal["last"]
	dob_day.select personal["dob_day"]
	dob_month.select personal["dob_month"]
	dob_year.select personal["dob_year"]

	next_button.click
end
```

这样，外部的使用者只需要调用即可：

```rb
fixture = YAML::load_file('fixtures/moving.yml')
@moving.personal.fulfill(fixture["personal"])
```

对应的`moving.yml`文件定义如下：

```yml
personal:
    myservice: "MINE"
    title: "Mr"
    first: "Juntao"
    last: "Qiu"
    dob_day: "1"
    dob_month: "Jan"
    dob_year: "1985"
```

#### Misc

为了达到视觉效果，UI上通常会有一些延迟的效果。比如点击一个按钮，在100ms之后弹出一个对话框，但是这种效果会导致测试的`随机`失败。

为了解决这个问题，我们可以通过给元素添加`wait_until_`前缀来等待。比如我们的测试中，在点击了下一步的按钮之后，预期有一个`查看收费详情`的对话框出现。根据一般的实现方式，这个对话框是预先写在页面上的，然后在合适的实际通过`JavaScript`将其显示在页面上（这样我们就不能通过查看该元素*是否存在*在页面上来编写断言了）。

![lightbox](/images/2015/01/lightbox-resized.png)

```rb
element :lightbox_view_fees, "#tmsLBViewFees"
```

```rb
Then /I can see the lightbox View Fees shows up/ do
	@moving.wait_until_lightbox_view_fees_visible
end
```

### 最后的结论

通常，我们的UI测试会和`特性描述`写在一起，以`Cucumber`为例，在`feature`文件中，我们会编写诸如这样的描述：

```rb
Feature: Platinum Move
	Scenario: Platinum Move
		Given I am on moving home page
		When I select to move my service "Foxtel from Telstra"
		And I select a "Telstra technician install"
		Then I can see the lightbox "View Fees" shows up
```

而一个良好的`实现`，我是说，像`feature`描述一样清晰的实现，可能是这样的：

```rb
Given /I am on moving home page/ do 
	@moving = MovingHome.new
  	@moving.load
end

When /I select to move my telstra service "([^"]*)"/ do |selected|
	setup_data
	@moving.service.fulfill selected
end

Then /I can see the installation form/ do
	expect(@moving).to have_move_service
end

Then /I cannot see the installation form/ do
	@moving.move_service.should_not be_visible
end

And /I select a "([^"]*)"/ do |install|
	@moving.move_service.select_install install
end

Then /I can see the lightbox "([^"]*)" shows up/ do |name|
	@moving.lightbox(name).should be_visible
end
```

基本上，每个`step`仅仅对应1行（或者很少的几行）代码，而这些代码背后有一组组织良好的`PageObject`。


