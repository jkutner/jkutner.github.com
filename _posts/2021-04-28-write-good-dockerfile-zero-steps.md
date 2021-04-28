---
layout: post
title:  "Write a Good Dockerfile in 0 Steps"
date:   2021-04-28 09:07:54
---


If you already have the [Pack CLI](https://buildpacks.io/docs/tools/pack/) installed, you can create a Docker image for any Java, Node.js, Python, or Ruby app (without a `Dockerfile`) by running:

```
$ pack build --builder heroku/buildpacks:20 my-app
```

Or with Spring Boot, you can run the following command (which uses the [Paketo Buildpacks](https://paketo.io/)):

```
$ ./mvnw spring-boot:build-image
```

Both of these commands will create a well-structured Docker image that has several advantages over one you create with a `Dockerfile`, including:

* It can be [rebased](https://buildpacks.io/docs/concepts/operations/rebase/) (i.e. the operating system can be updated in milliseconds without a re-build)
* The cache won't be unnecessarily invalidated because lower layers changed.
* You can combine multiple language runtimes without copy-pasting from other `Dockerfile`s
* It can have multiple entrypoints for each operational mode
* Reproduces the same app image digest by re-running the build
* Includes a bill-of-materials describing the contents of the image
