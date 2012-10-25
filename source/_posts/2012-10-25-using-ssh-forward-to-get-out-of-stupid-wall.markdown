---
layout: post
title: "Using ssh forward to get out of stupid wall"
date: 2012-10-25 22:59
comments: true
categories: 
---

## Generate the public and private key pair
This step is quite strightforward, just generate the keys by using ssh-keygen:
    $ ssh-keygen #specify the key file name (I use the id_ plus remote site hostname)
then you'll get 2 keys locally, you can do this step in any place, but people do it
on their home-dir/.ssh, after the creation, you need to change the mask of the key file:
    $ chmod 600 id_site

## Put the public key remotely
Okay, once the key is generated, we can simply put the publick key to remote site, and we
don't need to type password any more:
    $ scp id_site.pub user@remote:
Note the colon at the end of the command above, login to remote server
    # cat id_site.pub >> .ssh/authorized_keys
    # rm id_site.pub
Then go back local machine, and we're done

## SSH forward
Now we can simply login the remote server by using the private key just generated:
    $ ssh -i id_site user@remote

You then probably be noticed to add the key to system key chain, it is on Mac. And we now don't
need to type the password manually. So let's go a little bit further:
    $ ssh -N -i id_site -l 15100:localhost:15100 user@remote

Then you can access the localhost:1500 port on remote machine BY using the local port, that's why it
called ssh forward I think.

You may note that I'm using the port 15100, that's the mailcatcher web mananger port, I cannot access
the mailcatcher running on another machine, but somehow, I can ssh it through ssh port(22), so I asked
one of my _smart_ colleagues, and got this solution.
