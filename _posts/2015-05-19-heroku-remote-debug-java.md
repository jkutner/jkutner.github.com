---
layout: post
title:  "Remote Debugging a Java Process on Heroku"
date:   2015-05-19 11:43:00
---

Java processes on Heroku run inside of a [dyno](https://devcenter.heroku.com/articles/dynos),
which has a few
restrictions that make it difficult to attach debuggers and management consoles.
But it's not impossible.

My [Java Debug Wire Protocol (JDWP) Buildpack](https://github.com/jkutner/heroku-buildpack-jdwp)
can be added to your Heroku application with just a few simple commands. It will
use [ngrok](https://ngrok.com/) to proxy the debug session on Heroku,
making it externally accessible.
Or you can run ngrok locally to have your Java process connect to you.
I'll begin with the former.

## Connect from your local debugger

First, create a free [ngrok account](https://dashboard.ngrok.com/user/signup). This is necessary to use TCP with their service. Then capture your API key, and set it as a config var on your Heroku app like this:

{% highlight text %}
$ heroku config:set NGROK_API_TOKEN=xxxxxx
{% endhighlight %}

Next, add the JDWP buildpack to your app:

{% highlight text %}
$ heroku buildpacks:add https://github.com/jkutner/heroku-buildpack-jdwp.git
{% endhighlight %}

Then add your primary buildpack. For example, if you are using Java:

{% highlight text %}
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-java.git
{% endhighlight %}

Now modify your `Procfile` by prefixing your `web` process with the `with_jdwp` command. For example:

{% highlight text %}
web: with_jdwp java $JAVA_OPTS -cp target/classes:target/dependency/* Main
{% endhighlight %}

Finally, commit your changes, and redeploy the app:

{% highlight text %}
$ git add Procfile
$ git commit -m "Added with_jdwp"
$ git push heroku master
{% endhighlight %}

Once your app is running with the JDWP buildpack and the `with_jdwp` command, you'll see something like this in your logs:

{% highlight text %}
2015-05-19T16:06:36.530988+00:00 app[web.1]: Listening for transport dt_socket at address: 8998
...
2015-05-19T16:06:37.052977+00:00 app[web.1]: [05/19/15 16:06:37] [INFO] [client] Tunnel established at tcp://ngrok.com:39678
{% endhighlight %}

Then, from your local machine, you can connect to the process using the ngrok URL from the logs.
For example:

{% highlight text %}
$ jdb -attach ngrok.com:39678
Set uncaught java.lang.Throwable
Set deferred uncaught java.lang.Throwable
Initializing jdb ...
>
{% endhighlight %}

Now you can use it:

{% highlight text %}
> methods my.company.MainServlet
...
javax.servlet.Servlet service(javax.servlet.ServletRequest, javax.servlet.ServletResponse)
javax.servlet.Servlet getServletInfo()
javax.servlet.Servlet destroy()
javax.servlet.ServletConfig getServletName()
javax.servlet.ServletConfig getServletContext()
javax.servlet.ServletConfig getInitParameter(java.lang.String)
javax.servlet.ServletConfig getInitParameterNames()
{% endhighlight %}

Or just [use your favorite IDE](https://www.jetbrains.com/idea/help/run-debug-configuration-remote.html).
Your favorite is IntelliJ IDEA right?

## Connect to your local debugger

If you'd like to have your process connect to your local machine
(going the opposite direction) you can [install ngrok locally](https://ngrok.com/).
Then run it

{% highlight text %}
./ngrok -proto=tcp 9999
{% endhighlight %}

This will display the ngrok URL.
Use it to set the following config vars on your Heroku app:

{% highlight text %}
$ heroku config:set JDWP_PORT="ngrok.com:39678"
$ heroku config:set JDWP_OPTS="server=n,suspend=y"
{% endhighlight %}

Finally, start your debugger locally:

```
jdp -listen 9999
```

And redeploy your app with `git push`.
