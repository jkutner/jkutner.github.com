---
layout: post
title:  "Testing JDK 9 EA with Heroku"
date:   2015-07-16 22:18:00
---

You can test JDK 9 in just a couple of minutes by deploying any JVM-based app to
Heroku.

Why should you test JDK 9? Because it's a great way to help the community! The
[Adopt OpenJDK project](https://java.net/projects/adoptopenjdk)
is eagerly requesting feedback, bug reports, and
contributions that help get everyone's frameworks and applications prepared for
the new release.

You can test your own app, or use one of
[Heroku's samples](https://github.com/heroku/java-getting-started).
If you're not familiar with Heroku, you might want to follow the
[Getting Started with Java on Heroku guide](https://devcenter.heroku.com/articles/getting-started-with-java#introduction).

When you have an app ready,
add a `system.properties` file in the root directory of your project, and
put this code in it:

{% highlight text %}
java.runtime.version=1.9
{% endhighlight %}

Add that file to your Git repository by running these commands:

{% highlight text %}
$ git add system.properties
$ git commit -m "Testing JDK 9"
{% endhighlight %}

Then, deploy to Heroku by running `git push heroku master`:

{% highlight text %}
$ git push heroku master
Counting objects: 3, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 313 bytes | 0 bytes/s, done.
Total 3 (delta 2), reused 0 (delta 0)
remote: Compressing source files... done.
remote: Building source:
remote:
remote: -----> Java app detected
remote: -----> Installing OpenJDK 1.9... done
...
{% endhighlight %}

You'll see Heroku install JDK 9 for your app, and once the deploy is finished
you can check things out by running:

{% highlight text %}
$ heroku open
$ heroku logs -t
{% endhighlight %}

And you can start a shell for your app and test the new JDK 9 by running:

{% highlight text %}
$ heroku run bash
Running `bash` attached to terminal... up, run.1713
~ $ java -version
openjdk version "1.9.0_ea-cedar14_2015-07-16"
OpenJDK Runtime Environment (build 1.9.0_ea-cedar14_2015-07-16-b72)
OpenJDK 64-Bit Server VM (build 1.9.0_ea-cedar14_2015-07-16-b72, mixed mode)
{% endhighlight %}

If you find any problems, feel free to reach out
to [me](https://twitter.com/codefinger).

If you don't find any problems, and still want to contribute, try collecting
some data points for the G1GC (the new default garbage collector) as describe in
[this post on hotspot-dev](http://mail.openjdk.java.net/pipermail/hotspot-dev/2015-June/019221.html).

If you'd like to play around with some new features, check out this great post
on [what's new in JDK 9](http://blog.takipi.com/java-9-the-ultimate-feature-list/) from Takipi.
