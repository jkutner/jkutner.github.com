---
layout: post
title:  "Deploying Kotlin on Heroku with Ktor"
date:   2017-04-10 10:05:30
---

Kotlin reminds me of a young Harry Potter. It's fresh, full of zeal, and has the support of a
great institution. Harry had Hogworts, but Kotlin has the
entire JVM ecosystem to nurture its growth.

Like Java, Kotlin is a statically typed, compiled language. But it differs from Java
by sporting many advanced features borrowed from other JVM
languages and introducing new capabilities like
[coroutines](https://kotlinlang.org/docs/reference/coroutines.html) and
[null safety](https://kotlinlang.org/docs/reference/null-safety.html).

Clicking this button is the fastest way to get started with Kotlin. It deploys a simple [Ktor](https://github.com/Kotlin/ktor) based web app on Heroku (for free):

[![Deploy to Heroku](https://camo.githubusercontent.com/c0824806f5221ebb7d25e559568582dd39dd1170/68747470733a2f2f7777772e6865726f6b7563646e2e636f6d2f6465706c6f792f627574746f6e2e706e67)](https://dashboard.heroku.com/new?&template=https%3A%2F%2Fgithub.com%2Forangy%2Fktor-heroku-start)

Many thanks go to [Ilya Ryzhenkov](https://twitter.com/orangy) for putting this together. The Kotlin
community is vibrant and extremely helpful. I chatted with Ilya in the
[Kotlin Slack group](https://kotlinlang.slack.com) where over six thousand people are hanging out.

You can dive into [the source code for that example](https://github.com/orangy/ktor-heroku-start)
if you'd like (it serves up HTML and accesses a database),
but we'll take a look at another more interesting example to see how a Kotlin web application
running on Heroku is put together.

### Using Coroutines

The [Ktor repository](https://github.com/Kotlin/ktor) contains a few sample apps that demonstrate
both basic and unique capabilities of Kotlin. An interesting one is the
[Ktor async sample](https://github.com/Kotlin/ktor/tree/master/ktor-samples/ktor-samples-async),
which uses a coroutine to perform some CPU intensive work without blocking the main thread.

I've extracted this example into it's own repo, which you can clone locally by
running:

```sh-session
$ git clone https://github.com/kissaten/ktor-samples-async/
```

The `main` function in the app uses the experimental `async` feature to call
a suspending function, `handleLongCalculation(start: Long)`:

```kotlin
fun Application.main() {
    install(DefaultHeaders)
    install(CallLogging)
    install(Routing) {
        get("/{...}") {
            val start = System.currentTimeMillis()
            async(executor.asCoroutineDispatcher()) {
                call.handleLongCalculation(start)
            }.await()
        }
    }
}
```

The `handleLongCalculation` function is defined with the `suspend` keyword, which indicates
that this function can be paused at certain *suspension points* so that the main
thread of execution can perform some other work while it waits.

In this example, the suspension point is the `delay` call. Otherwise, the function
simply calculates some random number and renders it (along with the time it took to do so).

```kotlin
private suspend fun ApplicationCall.handleLongCalculation(start: Long) {
  val queue = System.currentTimeMillis() - start
  var number = 0
  val random = Random()
  for (index in 0..300) {
    delay(10)
    number += random.nextInt(100)
  }

  val time = System.currentTimeMillis() - start
  respondHtml {
    head {
      title { +"Async World" }
    }
    body {
      h1 {
        +"We calculated this after ${time}ms (${queue}ms in queue): $number"
      }
    }
  }
}
```

If we bombard this server with requests, we'll see that the time to cacluate
these random numbers is much faster than a synchronous version of the code.

The coroutine in this example is used to prevent a CPU operation from blocking,
but it can also be used to prevent blocking of network IO, file IO, and GPU operations.

Now, let's get this app ready for the cloud.

### Preparing a Ktor App for Heroku

There are only two changes required to make a typical Ktor app work on Heroku:

* Set the `port` from the `$PORT` environment variable.
* Define the `web` process type in a `Procfile`.

We can set the port in the `resources/application.conf` by using the `$` notation to
reference an environment variable, like this:

```
ktor {
  deployment {
    environment = development
    port = ${PORT}
  }

  application {
    modules = [ org.jetbrains.ktor.samples.async.AsyncApplicationKt.main ]
  }
}
```

Then we create a `Procfile`, and put the following line in it:

```
web: java -cp target/dependency/*:target/classes/ org.jetbrains.ktor.netty.DevelopmentHost
```

This defines a `web` process type that Heroku will use to run the app. It uses
a simple `java` command to launch Ktor's built-in Netty host with the app on the classpath.

If you've installed the [Heroku CLI](https://cli.heroku.com), you can run the app locally with
the command:

```
$ heroku local web
```

Finally, you can deploy this app to Heroku by running:

```sh-session
$ heroku create
$ git push heroku master
```

After the deployment process is finished, run `heroku open` to see the app, and
`heroku logs` to see the log output.

### Other ways to deploy Kotlin

Ktor includes bindings for Jetty and Tomcat in addition to Netty, which we used here.
You can even create an embedded Ktor server, which is exactly what the
[ktor-heroku-start example](https://github.com/orangy/ktor-heroku-start) does.

But there are many other web frameworks to choose from. [Spring Boot has
support for Kotlin](https://spring.io/blog/2016/02/15/developing-spring-boot-applications-with-kotlin),
and so does [Vert.x](https://github.com/vert-x3/vertx-examples/tree/master/kotlin-example).
In fact, Kotlin integrates so well with Java APIs that it should be possible to use most Java frameworks from Kotlin.

All you need now is a wand.
