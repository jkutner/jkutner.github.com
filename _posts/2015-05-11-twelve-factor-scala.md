---
layout: post
title:  "The Twelve Factor Scala App"
date:   2015-05-11 22:18:00
---

At [Heroku](http://heroku.com), we host thousands of Scala applications -- many of which are deployed on a daily basis. As a result, we've identified many characteristics that make deployments more scalable, repeatable, and maintainable. We've compiled these principles and best practices into a philosophy called the [12-factor app](http://12factor.net).

The 12-factor app is a language agnostic paradigm. But in this article, I'll outline how it applies specifically to Scala applications. You'll learn how to make your deployments more structured, reliable, and safe -- characteristics that Scala programmer embrace in their code, but often neglect in deployment. I'll start with the first five factors and discuss the others in future posts.

## Factor 1: Codebase

Use version control. That part goes without saying I hope. But more specifically, you should have a single version control repository per application. Don't manually fork your code for deployment, and don't use a single repository to version different applications.

<img src="http://12factor.net/images/codebase-deploys.png" style="float:right; margin:0 0 10px 10px;cursor:pointer; cursor:hand;" border="0" alt="" />

I see this principle often violated with the use of [sbt sub-projects](http://www.scala-sbt.org/release/tutorial/Multi-Project.html). Sub-projects are great for [breaking out libraries from your code](https://www.playframework.com/documentation/2.3.x/SBTSubProjects), but deployment gets messy when you have a distinct application as a sub-project. It becomes difficult to separate the commit history between applications, and makes isolated rollbacks impossible.

A solution to this problem is [Git submodules](http://www.git-scm.com/book/en/v2/Git-Tools-Submodules). You can still use sbt sub-projects so long as your sub-project directory is actually a Git submodule added to your project with a command such as:

{% highlight text %}
$ git submodule add https://github.com/jkutner/play-sub-project
{% endhighlight %}

This will create a `.gitmodules` file in the root directory of your project, and add the secondary application (with it's own Git repository) as a sub-directory.

<img src="/assets/images/git-submodule-play.png" style="width: 100%; margin-left: 0; margin-right: 0" alt="Join Server">

Now you can manage both the primary (root directory) application and the secondary (sub-directory) application with the same sbt commands. But you'll still retain separate version control histories for each.

## Factor 2: Dependencies

Don't check JAR files into version control. Yes, another obvious one. But I have to say these things. It's worth asking yourself, however, why don't we check JAR files into Git? The answer is because they become unmanaged. It's easy to lose track of the dependency's version, and it makes updating it difficult. It also makes it difficult to pull the dependency into your application because it sits outside of your standard mechanisms (such as Ivy and Maven).

Ultimately, these are the same reasons we want to avoid any kind of global dependency, such as a system library or even a `.m2` directory.

Your `~/.m2` and `~/.ivy2` directories are great for development. They prevent the epic download of the Internet every time you spin up a new application. But in production, these global repositories make an application less self-contained, and less portable because the app is more reliant on the underlying platform.

Before deploying to production, you should vendor your dependencies. Vendoring is the process of moving the JAR files your application needs at runtime into your `target/` directory. The [sbt-native-packager](http://www.scala-sbt.org/sbt-native-packager/) plugin,
which is include by default when using [Play Framework](https://playframework.com/), does this for you with the `sbt stage` command.

## Factor 3: Configuration

Don't check your passwords into version control. Another one for the dummies right? Or is it? Most people know not to check personal passwords into Git, but very often I find that database credentials, Amazon access tokens and other private information is stored in a version control repository. This is a problem not only for security, but also for portability because it makes it difficult to deploy your application into new environments that are not pre-configured.

Your configuration, the things that change between environments (thus, this does not include you `conf/routes`), should be strictly seperated from your code. Configuration belongs in the environment as environment variables. That's what their for, after all.

A good example is your database connection parameters. Don't use a multitude of config files to store all the URLs, usernames, and passwords for each of the databases in your dev, stage, UAT and production environments. That makes your application brittle. Instead, store the database URL as an environment variable. You can access it like this in code:

{% highlight java %}
System.getenv("DATABASE_URL")
{% endhighlight %}

Or like this in your `conf/application.conf` file:

{% highlight text %}
db.default.url=${DATABASE_URL}
{% endhighlight %}

Here's a good litmus test for this factor: can you open source your application without compromising the security of any cedentials?

## Factor 4: Backing Services

A backing service is any service an app consumes over the network as part of its normal operation. Examples include datastores (such as MySQL or CouchDB), messaging/queueing systems (such as RabbitMQ or Beanstalkd), SMTP services for outbound email (such as Postfix), and caching systems (such as Memcached).

The code for a 12-factor app makes no distinction between local and third party services. To the app, both are attached resources, accessed via a URL or other locator/credentials stored in the config. A deploy of the twelve-factor app should be able to swap out a local MySQL database with one managed by a third party (such as Amazon RDS) without any changes to the app’s code. Likewise, a local SMTP server could be swapped with a third-party SMTP service (such as Postmark) without code changes. In both cases, only the resource handle in the config needs to change.

Thus, if you are storing connection paramters for your database and other backing services as environment variables, then you're well on your way to satisfiying this principle.

## Factor 5: Build, release, run

Your deployment process should have three discrete steps.
Build: compile the code and package artifacts
Release: combine your artifacts with the environmental configuration
Run: launch the application process

When using a tool such as sbt-native-packager, and cloud-based service such as Heroku, these steps are realized like so:

{% highlight text %}
$ sbt stage
...
$ sbt deployHeroku
...
$ target/universal/stage/bin/my-app
{% endhighlight %}

The `stage` command, which is provided by [sbt-native-packager](http://www.scala-sbt.org/sbt-native-packager/), compiles your code, vendors your dependencies, and packages your application for deployment. The `deployHeroku` command, which is provided by
the [sbt-heroku plugin](https://github.com/heroku/sbt-heroku), releases your app to the cloud. Finally, you can run your application using a bin script that was generated by sbt-native-packager. Heroku does this for you automatically.

Do not run your application in production with a command like `sbt run` or `activator run`. These are great development and build tools, but they are totally unnessecary in production. They add a layer of complexitiy and additional dependencies that only cause problems when running your application under the real world pressures of a production environment.

## Further reading

If these ideas resonate with you, try deploying your app on Heroku. Here is some documentation:

* [Getting Started with Scala on Heroku](https://devcenter.heroku.com/articles/getting-started-with-scala#introduction)
* [Deploying Scala and Play Applications with the Heroku sbt Plugin](https://devcenter.heroku.com/articles/deploying-scala-and-play-applications-with-the-heroku-sbt-plugin)

For more information on the 12-factor app, see [12-factor.net](http://12factor.net/). And for more discussion specific to
the JVM see James Ward's excellent post on why [Java Doesn't Suck](http://www.jamesward.com/2014/12/03/java-doesnt-suck-youre-just-using-it-wrong).

And of course, come see my talk at [ScalaDays Amsterdam 2015](http://event.scaladays.org/scaladays-amsterdam-2015).
