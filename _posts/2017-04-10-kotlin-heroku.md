---
layout: post
title:  "Deploying Kotlin on Heroku with Ktor"
date:   2017-04-10 10:05:30
---

Kotlin reminds me of a young Harry Potter. It's fresh, full of zeal, and has a
great institution to nurture its growth. Harry had Hogworts, but Kotlin has the
entire JVM ecosystem behind it.

Kotlin is a statically typed, compiled programming language targeting the JVM,
Android and the browser. It sports many of the same features as other JVM
languages, but also introduces new capabilities like
[coroutines](https://kotlinlang.org/docs/reference/coroutines.html) and
[null safety](https://kotlinlang.org/docs/reference/null-safety.html).

The fastest way to get started with Kotlin on Heroku is by clicking this button
to deploy a simple [Ktor](https://github.com/Kotlin/ktor) based web app
that servers up some HTML and accesses a database:

[![Deploy to Heroku](https://camo.githubusercontent.com/c0824806f5221ebb7d25e559568582dd39dd1170/68747470733a2f2f7777772e6865726f6b7563646e2e636f6d2f6465706c6f792f627574746f6e2e706e67)](https://dashboard.heroku.com/new?&template=https%3A%2F%2Fgithub.com%2Forangy%2Fktor-heroku-start)

Many thanks to [Ilya Ryzhenkov](https://twitter.com/orangy) for putting this together for me. The Kotlin
community is both vibrant and helpful.

Now let's take a look at another example to see how a Kotlin web application
running on Heroku is put together.

## Using Coroutines

The Ktor repository contains a few sample apps that demonstrate the
unique capabilities of Kotlin. One of the more interesting
is the
[Ktor async sample](https://github.com/Kotlin/ktor/tree/master/ktor-samples/ktor-samples-async),
uses a coroutine to perform a CPU intensive operation without blocking a thread.
Coroutines can be used to  prevent blocking of IO operations too.

I've extracted this example into it's own repo, which you can clone locally by
running:

```sh-session
$ git clone https://github.com/kissaten/ktor-samples-async/
```

This `main` function in this example uses the experimental `async` function to call
a suspending function, `handleLongCalculation(start: Long)`:

```
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

The coroutine itself, `h`, is defined with the `suspend` keyword, which indicates
that this function can be paused at certain *suspension
points* and the current thread of execution
can perform some other work.

In this example, the suspension point is the `delay` call. Otherwise, the function
simply calculates some random number and renders it (along with the time it took to do so).

```
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

Now let's get this app ready for the cloud.

## Preparing a Ktor App for Heroku

There are only two changes required to make a typical Ktor app work on Heroku:

* Set the `port` from the `$PORT` environment variable.
* Define the `web` process type in a `Procfile`.

You set the port in the `resources/application.conf` by using the `$` notation to
reference environment variables, like this:

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

Then create a `Procfile`, and put the following line in it:

```
web: java -cp target/dependency/*:target/classes/ org.jetbrains.ktor.netty.DevelopmentHost
```

This defines a `web` process type that Heroku will run. The command it self it
a simple `java` command that launches Ktor's built-in Netty host with your app.

After you've installed the [Heroku CLI](), you can run the app locally with
the command:

```
$ heroku local web
```

Finally you can deploy this app to Heroku by running:

```sh-session
$ heroku create
$ git push heroku master
```

After the deployment process is finished, run `heroku open` to see the app, and
`heroku logs` to see the log output.

## Other ways to deploy Kotlin

Ktor includes bindings for Jetty and Tomcat as well as Netty. You can also create
an embedded Ktor server, which is exactly what the
[ktor-heroku-start example](https://github.com/orangy/ktor-heroku-start) does.

But there are also many other web frameworks to choose from. [Spring Boot has
support for Kotlin](https://spring.io/blog/2016/02/15/developing-spring-boot-applications-with-kotlin),
and so does [Vert.x](https://github.com/vert-x3/vertx-examples/tree/master/kotlin-example).
Kotlin integrates so well with Java APIs that it should be possible to use most Java frameworks from Kotlin.
