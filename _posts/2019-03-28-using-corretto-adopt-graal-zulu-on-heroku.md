---
layout: post
title:  "Using Corretto, AdoptOpenJDK, Graal, and Zulu on Heroku"
date:   2019-03-27 09:12:42
---

In the last year, chosing a Java runtime to install has become more... interesting.

There are great write-ups on which Java SDK (JDK) to use from [Simon Ritter of Azul](https://www.azul.com/eliminating-java-update-confusion/) and [Matt Raible of Okta](https://developer.okta.com/blog/2019/01/16/which-java-sdk), but in this post you'll learn how to use a few of those choices on Heroku.

The default OpenJDK build provide by Heroku is great choice, but if you have some special need or want to get the latest JDK 8 patches you'll need a different distribution. In this post we'll cover:

* Azul Zulu JDK
* Amazon Corretto JDK
* AdoptOpenJDK
* GraalVM

If you don't care which of these you use, then you're probably best following the [Heroku documentation for Java](https://devcenter.heroku.com/articles/java-support) and picking the right major, minor, or update version. Otherwise, you'll probably want to start with Zulu.

## Using Zulu

[Zulu](https://www.azul.com/downloads/zulu/) is 100% free and open source distribution of OpenJDK from [Azul Systems](https://www.azul.com/). It's a great choice for an alternative JVM on Heroku because it's officially supported. You can use Zulu by adding a `system.properties` file to your app with the following contents:

```
java.runtime.version=zulu-1.8.0_202
```

Add this file to Git, and run `git push heroku master` as described in the [Heroku guide to getting started with Java](https://devcenter.heroku.com/articles/getting-started-with-java). Run the following command to confirm that it worked:

```
$ heroku run java -version
Running java -version on ⬢ mighty-brook-32719... up, run.4864 (Free)
openjdk version "1.8.0_202"
OpenJDK Runtime Environment (Zulu 8.36.0.1-CA-linux64) (build 1.8.0_202-b05)
OpenJDK 64-Bit Server VM (Zulu 8.36.0.1-CA-linux64) (build 25.202-b05, mixed mode)
```

## Using AdoptOpenJDK

[AdoptOpenJDK](https://adoptopenjdk.net) is a community of Java User Group (JUG) members, Java developers, and vendors who provide free and open source builds of OpenJDK. You can use AdoptOpenJDK binaries by adding a third-party buildpack to your Heroku app in conjunction with an official buildpack.

```
$ heroku buildpacks:set jdk/adopt
$ heroku buildpacks:add heroku/java
```

Then execute `git push heroku master` as before, and you'll be running with an AdoptOpenJDK binary. Run the following command to confirm that it worked:

```
$ heroku run java -version
Running java -version on ⬢ mighty-brook-32719... up, run.8770 (Free)
openjdk version "1.8.0_202"
OpenJDK Runtime Environment (AdoptOpenJDK)(build 1.8.0_202-201903270428-b08)
OpenJDK 64-Bit Server VM (AdoptOpenJDK)(build 25.202-b08, mixed mode)
```

You can customize the JDK version with [environment variables or a `system.properties` file](https://github.com/jkutner/adoptopenjdk-buildpack#customizing).

## Using Corretto

[Corretto](https://docs.aws.amazon.com/corretto/index.html) is a no-cost, multiplatform, production-ready distribution of the OpenJDK from Amazon. You can use it on Heroku by adding a third-party buildpack to your Heroku app in conjunction with an official buildpack:

```
$ heroku buildpacks:set jdk/corretto
$ heroku buildpacks:add heroku/java
```

Then execute `git push heroku master` as before, and you'll be running with a Corretto binary. Run the following command to confirm that it worked:

```
$ heroku run java -version
Running java -version on ⬢ mighty-brook-32719... up, run.3636 (Free)
openjdk version "1.8.0_202"
OpenJDK Runtime Environment Corretto-8.202.08.2 (build 1.8.0_202-b08)
OpenJDK 64-Bit Server VM Corretto-8.202.08.2 (build 25.202-b08, mixed mode)
```

The Corretto buildpack has a few configuration options, which you can learn about in the [buildpack's README](https://github.com/jkutner/corretto-buildpack).

## Using GraalVM

The last JDK option is a little different than the others. [GraalVM](https://www.graalvm.org/) is a universal virtual machine for running applications written in JavaScript, Python, Ruby, R, JVM-based languages like Java, Scala, Kotlin, Clojure, and more. You can use it on Heroku by adding a third-party buildpack to your Heroku app in conjunction with an official buildpack:

```
$ heroku buildpacks:set jdk/graal
$ heroku buildpacks:add heroku/java
```

Then execute `git push heroku master` as before, and you'll be running with GraalVM. Run the following command to confirm that it worked:

```
$ heroku run java -version
Running java -version on ⬢ mighty-brook-32719... up, run.9591 (Free)
openjdk version "1.8.0_202"
OpenJDK Runtime Environment (build 1.8.0_202-20190206132807.buildslave.jdk8u-src-tar--b08)
OpenJDK GraalVM CE 1.0.0-rc14 (build 25.202-b08-jvmci-0.56, mixed mode)
```

The Graal buildpack has a few configuration options, which you can learn about in the [buildpack's README](https://github.com/jkutner/graal-buildpack).

# So Many Choices

As mentioned before, it's probably best to stick with the [default JDK provided by Heroku](https://devcenter.heroku.com/articles/java-support). But these are all great choices. For more information, see the [Heroku documentation on Java](https://devcenter.heroku.com/categories/java-support).