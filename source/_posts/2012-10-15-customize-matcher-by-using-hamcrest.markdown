---
layout: post
title: "Customize matcher by using hamcrest"
date: 2012-10-15 22:24
comments: true
categories: 
---
Although we can write tests all by the default matchers that hamcrest provided, but somehow we need the code to be more readable, and maintainable, so it's a good way to try customize our own matchers.

We discussed how to TDD in last post, and in the book class we talked:
``` java
    @Test
    public void shouldGetBookInfo(){
        Book book = new Book("The Ruby programming language", "Development");

        assertThat(book.getName(), is("The Ruby programming language"));
        assertThat(book.getCategory(), is("Development"));
    } 
```
The default *is* matcher can get the job done, but not that readable, we can simply provide a customized matcher for this case:
``` java
    @Test
    public void shouldGetBookInfoByMatcher(){
        Book book = new Book("The Ruby programming language", "Development");

        assertThat(book, BookMatcher.isCorrect("The Ruby programming language", "Development"));
    }
```

Thanks for the flexibility of hamcrest, just extends the *BaseMatcher<T>* like this:
``` java
    class BookMatcher extends BaseMatcher<Book> {
        private String name;
        private String category;

        private BookMatcher(String name, String category) {
            this.name = name;
            this.category = category;
        }

        @Override
        public boolean matches(Object item) {
            Book book = (Book)item;
            return book.getName().equals(name) && book.getCategory().equals(category);
        }

        @Override
        public void describeTo(Description description) {
        }


        public static BookMatcher isCorrect(String name, String category) {
            return new BookMatcher(name, category);
        }
    }
```

