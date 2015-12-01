---
layout: post
title:  "Improving Java Start-Up Time"
date:   2015-12-01 10:02:00
---

The performance of the JVM can’t be beat, unless you’re talking about its start-up time. The JVM isn't known for being fast to boot, and many application frameworks have only made the situation worse.

In this post, you’ll learn a few tricks that can help improve your app’s boot time. Much of what I’ll focus on is specific to the Spring framework, but some of this applies to all JVM apps. Your goal should be to get an application to boot in under a minute. At [Heroku](http://heroku.com), we believe this is a good practice that leads to better deployment processes. That's why it's a part of the [Disposability principle in the 12-factor app](http://12factor.net/disposability).

The most common causes of slow start-up include:

* Migrations: Running Liquibase or Flyway at boot time can add a minute or more.
* Massive classpaths
* Spring auto-config or lots of reflection at boot time.
* Ecache initialization, or any pre-caching
* Agents, such as New Relic, that instrument byte code at boot time.

I’ll address a few of these in this post.

## Why care about boot time?

Historically, the JVM ecosystem did not consider boot time to be important. The goal for most JVM apps was hot deployment, which required a persistent JVM that never restarted. But that dream never really came to fruition because memory leaks, PermGen, system updates, system crashes, and many other problems always required a restart.

Today, start-up time is a major concern for both production environments and development environments. In development, getting rapid feedback when you make changes is an important part of the process. That’s why frameworks such as [Play](https://playframework.com/) and [JRuby on Rails](https://github.com/jruby/jruby/wiki/JRubyOnRails) make it easy to reload changes in your app without restarting (in dev only).

In production, start-up time is important because it reduces the turnaround cycle for deployment, which in turn encourages [continuous deployment](https://en.wikipedia.org/wiki/Continuous_delivery#Relationship_to_Continuous_Deployment). If it takes less than a minute to restart your app, you are less likely to experience downtime and more likely to redeploy often.

## Migrations

The most common and probably the most expensive start-up drag is running migrations (a.k.a evolutions) at boot time. Some frameworks, such as [Liquibase](http://www.liquibase.org/) passively encourage this. The [Liquibase Spring Bean](http://www.liquibase.org/documentation/spring.html) does this for you.

Instead, it’s better to run your migrations in a separate process outside of the app booting. This is preferable because they won’t need to be run when simply restarting your app (only when redeploying new code). How you go about implementing this depends on your app and the platform you deploy to, but the Heroku guide for [Running Database Migrations for Java Apps](https://devcenter.heroku.com/articles/running-database-migrations-for-java-apps) should be generally applicable.

To summarize, you’ll want to create an executable class in your app that runs your migrations on demand. In that way you can execute a command like:

{% highlight text %}
java -cp myapp.jar:target/dependency/* com.example.Migrations
{% endhighlight %}

The exact details for getting this rightdepend on your framework, but most should allow this.

It's also possible to run migrations asynchronously at start-up. The [JHipster project has a nice template](https://github.com/jhipster/generator-jhipster/blob/v2.24.0/app/templates/src/main/java/package/config/liquibase/_AsyncSpringLiquibase.java) for this.

## Massive class paths

In his keynote at JavaOne 2015, Mark Reinhold cited massive classpaths as a common cause of degraded app start-up time and even general performance. He did not define specific thresholds, but I can confirm that I’ve seen apps with hundreds of JAR file dependencies, each with hundreds of classes in them, and they all suffer from this problem.

JDK 9, with [Project Jigsaw](http://openjdk.java.net/projects/jigsaw/), may provide some relief here. But in the meantime, I think this strengthens the case for a “microservices-like environment”. I’m not going to full-on advocate for microservices, but I think there are general principles embedded in this architectural style that we should all embrace. And decomposing an application into smaller, more cohesive apps is a good practice.

## Spring Auto-config

Spring Boot developers love Spring’s auto-config feature because they don’t have to write a bunch of XML to configure an app. Instead, they can annotate classes, and let the framework figure everything out at runtime. But there is a penalty for this.

Spring must scan all classes looking for annotations and wiring things up at boot time. The Spring philosophy is “fail fast & fail early” so any errors in configuration must be detected right away (before the app starts up). But if you have tons of beans and configuration annotations, it’s going to take a while to start your app.

One solution to this problem is the use of the `@Lazy` annotation. When used on a `@Bean` or `@Component` class, the class will not be initialized until referenced by another bean or explicitly retrieved from the enclosing `BeanFactory`. If `@Lazy` is present on a `@Configuration` class, this indicates that all `@Bean` methods within that `@Configuration` should be lazily initialized.

It also helps to break your application down into smaller apps that do one job well (maybe I’m talking about microservices again).

## Other options with side effects

All the recommendations mentioned thus far will not affect the general performance of your app. They only reduce boot time. But there are some options that improve boot time at the cost of peak performance. In some cases this may be desirable.

The first is Tiered compilation. Per the Oracle documentation:

> Tiered compilation, introduced in Java SE 7, brings client startup speeds to the server VM. Normally, a server VM uses the interpreter to collect profiling information about methods that is fed into the compiler. In the tiered scheme, in addition to the interpreter, the client compiler is used to generate compiled versions of methods that collect profiling information about themselves. Since the compiled code is substantially faster than the interpreter, the program executes with greater performance during the profiling phase. In many cases, a startup that is even faster than with the client VM can be achieved because the final code produced by the server compiler may be already available during the early stages of application initialization. The tiered scheme can also achieve better peak performance than a regular server VM because the faster profiling phase allows a longer period of profiling, which may yield better optimization.

You can enable  Tiered compilation with the following JVM arguments:

{% highlight text %}
-XX:+TieredCompilation -XX:TieredStopAtLevel=1
{% endhighlight %}

Another common option is disabling the JVM bytecode verification by setting this option:

{% highlight text %}
-Xverify:none
{% endhighlight %}

While this will improve startup time, it’s [generally discouraged in production systems](https://blogs.oracle.com/buck/entry/never_disable_bytecode_verification_in) for security and other reasons.

## Further Reading

I haven't been able to find a good comprehensive guide to improving boot time in production. Most resources focus on development time, which is important too. Here are some places to go for more information:

* [Drip](https://github.com/flatland/drip)
* [Spring Boot Devtools]](https://spring.io/blog/2015/06/17/devtools-in-spring-boot-1-3)