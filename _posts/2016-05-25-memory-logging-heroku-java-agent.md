---
layout: post
title:  "Memory Logging with the Heroku Java Agent"
date:   2016-05-25 18:32:00
---

The [Heroku Java Agent](https://github.com/heroku/heroku-javaagent)
is a lightweight tool you can attach to a running Java process to log
heap and non-heap memory usage. It is a simple, but powerful reporting
mechanism that can provide essential information at critical moments.

When the agent is attached to an app, it will periodically print
something like this to stdout:

```
source=web.1 measure.mem.jvm.heap.used=33M measure.mem.jvm.heap.committed=376M measure.mem.jvm.heap.max=376M
source=web.1 measure.mem.jvm.nonheap.used=19M measure.mem.jvm.nonheap.committed=23M measure.mem.jvm.nonheap.max=219M
source=web.1 measure.threads.jvm.total=21 measure.threads.jvm.daemon=11 measure.threads.jvm.nondaemon=1 measure.threads.jvm.internal=9
```

The first line captures all aspects of heap memory, including the current use and maximum.
The second line captures non-heap usage, which includes thread stacks, metaspace, code cache,
and [some other things](https://devcenter.heroku.com/articles/java-memory-issues#jvm-memory-usage).
The last time reports the number of threads in use.

### Usage

To include the agent with your application, put this code in your `pom.xml`:

```xml
<dependency>
  <groupId>com.heroku.agent</groupId>
  <artifactId>heroku-javaagent</artifactId>
  <version>1.5</version>
  <scope>runtime</scope>
</dependency>
```

Or this in your `build.gradle`

```groovy
runtime "com.heroku.agent:heroku-javaagent:1.5"
```

Then build your application with either `mvn install` or `./gradlew stage`.

When you run your application (either locally, on Heroku or somewhere else),
you can attach the agent using the `-javaagent` option, like this:

```
java -javaagent:heroku-javaagent-1.5.jar=stdout=true,lxmem=true -cp target/app.jar com.example.Main
```

The location of `heroku-javaagent-1.5.jar` at runtime will depend on your build tool (Maven or Gradle)
and any frameworks you are using. Most often it is located in either
`target/dependency/` or `build/install/<app-name>/lib/`.

Note that the agent does not work with the -jar option.
If you are running an executable JAR file, you must change your command to use `-cp` and
provide a main class.