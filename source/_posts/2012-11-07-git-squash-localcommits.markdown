---
layout: post
title: "Git squash localcommits"
date: 2012-11-07 10:54
comments: true
categories: 
---

There is a common scenario: we have lots of local commits related with a certain feature or a big
bug, after all the works done, we want to combine them together. The git provides a handy way to do
this job: *git rebase*

I'll take the following case as an example, say, I've got 3 commits locally and they are all about
a restyling of some page.

`$ git st`

    # On branch master
    # Your branch is ahead of 'origin/master' by 3 commits.
    #
    nothing to commit (working directory clean)

Details:

`$ git log`

    commit 4e7e1ac7e7e77ae4404843ed96b9f881f969b836
    Author: Qiu Juntao <juntao.qiu@gmail.com>
    Date:   Tue Nov 6 16:49:59 2012 +0800

        RCA-410 new search form style only apply to search result page.

    commit 385cec1f22f432c03ea96b5c927f89b3747e82fb
    Author: Qiu Juntao <juntao.qiu@gmail.com>
    Date:   Tue Nov 6 14:21:50 2012 +0800

        RCA-410 re-style search form area.

    commit b9694db0b0fb100bfa5f967480188bf05ad538b4
    Author: Qiu Juntao <juntao.qiu@gmail.com>
    Date:   Tue Nov 6 10:33:07 2012 +0800

        RCA-410 restyling search form.

    commit 866375c7d805e19f963319fb558f1b16f7daf15b
    Author: John abruzzi <juntao.qiu@gmail.com>
    Date:   Mon Nov 5 14:06:16 2012 +0800

        RCA-625. Add the embeded video feature toggle into casa feature-config file.


I have 3 commits after the very commit *866375c7d805e19f963319fb558f1b16f7daf15b*, and then I'll use
rebase in interactive mode, by the option *-i* appended.

`$ git rebase -i HEAD~3`

    pick b9694db0b RCA-410 restyling search form. Pair: Yameng & Juntao
    pick 385cec1f2 RCA-410 re-style search form area. pair:juntao
    pick 4e7e1ac7e RCA-410 new search form style only apply to search result page. pair:Juntao


There are a few command provided, I'll use *squash* by now, since I want to squash the following 2 commits 
into the first one, so simply change the *pick* into *squash*


    pick b9694db0b RCA-410 restyling search form. Pair: Yameng & Juntao
    squash 385cec1f2 RCA-410 re-style search form area. pair:juntao
    squash 4e7e1ac7e RCA-410 new search form style only apply to search result page. pair:Juntao


After that, save the popuped editor(vi in my local machinel), and change the generated comments message into
    
    RCA-410 restyling search form, applied to search results and pdp. Pair: Yameng & Juntao


and then save and quit the editor, we'll see the following message:

`$ git st`
    
    # On branch master
    # Your branch is ahead of 'origin/master' by 1 commit.
    #
    nothing to commit (working directory clean)
    

And the history is more clear like this:
`$ git log`

    commit 8ff8a0e015b6ebe7bcd5434f25ed789dee2d5f1e
    Author: Qiu Juntao <juntao.qiu@gmail.com>
    Date:   Tue Nov 6 10:33:07 2012 +0800

        RCA-410 restyling search form, applied to search results and pdp.

    commit 866375c7d805e19f963319fb558f1b16f7daf15b
    Author: John abruzzi <juntao.qiu@gmail.com>
    Date:   Mon Nov 5 14:06:16 2012 +0800
        RCA-625. Add the embeded video feature toggle into casa feature-config file.

