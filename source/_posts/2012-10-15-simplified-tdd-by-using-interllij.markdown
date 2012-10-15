---
layout: post
title: "Simplified TDD by Using Intellij"
date: 2012-10-15 20:42
comments: true
categories: 
---
In my last [post](), I mentioned to how to setup a intellij project by using gradle. and today we are going to talk about how to using intellij to write a demo java project from scratch(right after the *gradle idea* command).

To begin with TDD in java, we need some packages for that:
-   junit
-   hamcrest

Let's all of those dependencies in build.gradle:
``` groovy
    repositories {
        mavenCentral()
    }

    dependencies {
        testCompile 'junit:junit:4.8.2'
        testCompile 'org.hamcrest:hamcrest-core:1.2.1'
    }
```
and rerun the *gradle idea* command.

After intellij .ipr file generated, we can open it by intellij, and then create a project, let's say the basic structure of the project is like this:

    └── src
        ├── main
        │   ├── java
        │   │   └── org
        │   │       └── icodeit
        │   │           └── library
        │   │               ├── Book.java
        │   │               └── Library.java
        │   └── resources
        └── test
            ├── java
            │   └── org
            │       └── icodeit
            │           └── library
            │               ├── BookTest.java
            │               └── LibraryTest.java
            └── resources

Basically, we are going to build a simple library which allow user to add/borrow/return books to/from.

We simply devide it to the following tasks:

*   User can add book to library
*   User can get all books in a specific category
*   User can know how many books left in library
*   User can borrow book from library
*   User can return book when he/she finished 
*   User can be told whether there are books he/she want left in library

Let's do it step by step, by following the TDD way. Of course, we need to add tests at vert first:
``` java
    @Test
    public void shouldAddBookToLibrary(){
        Library library = new Library();
        Book book = new Book("The ruby programming language", "Development");
        library.addBook(book);

        assertThat(library.getTotalBookNumber(), is(1));
    }
```
This is a test used for test add book functionality, after the addition, we can tell by invoke *getTotalBookNumber* method (Of course, we need to make sure the project can be compiled, just add a new class Book.java and some fake methods in the Library.java). So, first we run the test (_Ctrl-Shift-F10_), and the test will fail.

Then we add the implementation of those functionalities:
``` java
    public class Library {
        private List<Book> books;

        public Library() {
            books = new LinkedList<Book>();
        }
        //...
    }

    public void addBook(Book book) {
        books.add(book);
    }

    public int getTotalBookNumber() {
        return books.size();
    }
```
Now we can get a green test. TDD is in a form of "Red-Green-Refactor", so far we've got nothing to refactor, let's add one more test:

``` java
    @Test
    public void shouldGetBooksByCategory(){
        Library library = new Library();
        Book book1 = new Book("The ruby programming language", "Development");
        Book book2 = new Book("The python programming language", "Development");
        Book book3 = new Book("The lean startup", "Business");

        library.addBook(book1);
        library.addBook(book2);
        library.addBook(book3);

        assertThat(library.getBookByCategory("Development").size(), is(2));
    }
```

Then the implementation:

``` java
    public List<Book> getBookByCategory(String category) {
        List<Book> grouped = new LinkedList<Book>();
        for(Book book : books){
            if(book.getCategory().equals(category)){
                grouped.add(book);
            }
        }
        return grouped;
    }
```

And what if the logic cames more complex, say:

``` java
    @Test
    public void shouldCanReturnBookToLibrary(){
        Library library = new Library();
        Book originBook = new Book("The ruby programming language", "Development");
        library.addBook(originBook);
        
        assertThat(library.getBookCount("The ruby programming language"), is(1));
        
        Book borrowed = library.borrowBook("The ruby programming language");
        
        assertThat(library.getBookCount("The ruby programming language"), is(0));
        
        library.returnBook(borrowed);

        assertThat(library.getBookCount("The ruby programming language"), is(1));
    }
```

When user borrowed a book from library, others can not borrow it any more of course, until the previous user return it back.

We can tell the specification by reading the test itself, and we don't care about the code in this prespective. On the other hand, when we try to implement the logic, we can focus on the small piece of code and get it done:

``` java
    public int getBookCount(String name) {
        int bookCount = 0;
        for(Book book : books){
            if(book.getName().equals(name)){
                bookCount++;
            }
        }
        return bookCount;
    }

    public Book borrowBook(String name) {
        Book book = null;

        if (getBookCount(name) == 0) {
            return null;
        }

        for (int i = 0; i < books.size(); i++) {
            if (books.get(i).getName().equals(name)) {
                book = books.remove(i);
                break;
            }
        }

        return book;
    }

    public void returnBook(Book book) {
        books.add(book);
    }
```

As you can see, the princple is really easy to follow:
-   Tasking (spearate the goal to some smaller parts)
-   Testing
-   Coding
-   Refactoring

The benefit is obverisly: there is no isolated code any more. Actually, the shorter of the code, the cleaner it will be.
