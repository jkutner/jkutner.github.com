---
layout: post
title:  "Building Spring Boot Docker Images with Heroku Buildpacks"
date:   2020-05-19 14:12:24
---

Spring Boot 2.3.0 introduced a new feature you can use to [package your app into a Docker image with Cloud Native Buildpacks](https://spring.io/blog/2020/05/15/spring-boot-2-3-0-available-now) (CNB). You can use this feature with Heroku buildpacks to create an image you can run on any cloud platform.

The new buildpack support works with both Maven and Gradle. For Maven you can use the command `mvn spring-boot:build-image` and with Gradle it’s `gradle bootBuildImage`. By default, both commands use the [Paketo buildpacks](https://paketo.io/) from Cloud Foundry, but the commands can be customized to run any buildpacks (even those you've created yourself).

### Maven

You can try the Heroku buildpacks with your own Boot app, or you can start with the [Heroku "Getting Started with Java" app](https://github.com/heroku/java-getting-started). Run these commands:

```
$ git clone https://github.com/heroku/java-getting-started
$ cd java-getting-started
$ ./mvnw spring-boot:build-image -Dspring-boot.build-image.builder=heroku/spring-boot-buildpacks
```

The `-Dspring-boot.build-image.builder` defines the set of buildpacks the plugin will use (you can also [configure this in your `pom.xml`](https://docs.spring.io/spring-boot/docs/current-SNAPSHOT/maven-plugin/reference/html/#build-image)). In this command we're using the Heroku buildpacks image `heroku/spring-boot-buildpack`. After it's done building you can run the image with this command:

```
$ docker run -it -p 5000:5000 java-getting-started:1.0
```

With the Docker container running, you can access the app at `http://localhost:5000`.

### Gradle

For apps that use Gradle, the process is similar. You can use your own app or the [Heroku "Getting Started with Gradle" app](https://github.com/heroku/gradle-getting-started).

```
$ git clone https://github.com/heroku/gradle-getting-started
$ cd gradle-getting-started
$ ./gradlew bootBuildImage --builder heroku/spring-boot-buildpacks
```

The `--builder` option defines the set of buildpacks the plugin will use (you can also [configure this in your `build.gradle`](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/html/#build-imagee)). We're using the Heroku buildpacks image `heroku/spring-boot-buildpack` again--the same builder we used with Maven. After it's done building you can run the image with this command:

```
$ docker run -it -p 5000:5000 gradle-getting-started:1.0
```

With the Docker container running, you can access the app at `http://localhost:5000`.

### Deploying

In either case (Maven or Gradle), you can deploy the resulting image to the [Heroku Container Runtime](https://devcenter.heroku.com/articles/container-registry-and-runtime) with commands like these:

```
$ heroku create
$ docker tag gradle-getting-started:1.0 registry.heroku.com/<app>/web
$ docker push registry.heroku.com/<app>/web
```

Enjoy!