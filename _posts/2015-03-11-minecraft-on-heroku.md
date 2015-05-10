---
layout: post
title:  "Running a Minecraft server on Heroku"
date:   2015-03-11 22:18:00
---

You only need one file with one line of text to run a Minecraft server on Heroku
with my [Minecraft buildpack](https://github.com/jkutner/heroku-buildpack-minecraft).
It solves all the problems associated with the use of TCP and Heroku's [ephemeral](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem) filesystem.

Create a new directory and add a `eula.txt` file with the following
contents:

{% highlight text %}
eula=true
{% endhighlight %}

Now initialize a Git repository and commit the file to it:

{% highlight text %}
$ git init
$ git add eula.txt
$ git commit -m "First commit"
{% endhighlight %}

Then install the [Heroku toolbelt](https://toolbelt.heroku.com/) and create
a new app using my Minecraft buildpack:

{% highlight text %}
$ heroku create --buildpack https://github.com/jkutner/heroku-buildpack-minecraft
{% endhighlight %}

In order to access the server, you'll need a [free ngrok account](https://ngrok.com/).
After creating an account, copy your auth token, and set it as a configuration
variable like this (replacing "xxx" with your token):

{% highlight text %}
$ heroku config:set NGROK_API_TOKEN="xxx"
{% endhighlight %}

Now deploy your project:

{% highlight text %}
$ git push heroku master
{% endhighlight %}

You will see a few dependencies install, and finally Minecraft it self being
installed. When the deployment process is complete, run the following command
to open a browser:

{% highlight text %}
$ heroku open
{% endhighlight %}

In the browser you'll see the logs of ngrok. Look for a line like this:

{% highlight text %}
[03/11/15 02:06:21] [INFO] [client] Tunnel established at tcp://ngrok.com:45010
{% endhighlight %}

The value similar to `ngrok.com:45010` is the server you'll connect to with your
local Minecraft client.

You can check the status of the Minecraft server by inspect it's logs with this
command:

{% highlight text %}
$ heroku logs
{% endhighlight %}

Once the server reports that up and running, like this:

{% highlight text %}
[19:32:21] [Server thread/INFO]: Preparing spawn area: 96%
[19:32:21] [Server thread/INFO]: Done (9.816s)! For help, type "help" or "?"
{% endhighlight %}

Then you can connect to it. Open your local Minecraft app,
and select "Mutliplayer". Then select "Direct Connect", and in the text box
for server name enter the `ngrok.com` address you saw in your browser.

<img src="/assets/images/minecraft-3.jpg" style="width: 100%; margin-left: 0; margin-right: 0" alt="Join Server">

Click "Join Server" and you're ready to play.

You can read more about how to configure and sync the Minecraft server's data
on the project's [Readme page](https://github.com/jkutner/heroku-buildpack-minecraft/blob/master/README.md).
