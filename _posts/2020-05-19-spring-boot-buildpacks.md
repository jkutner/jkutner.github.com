---
layout: post
title:  "Building Spring Boot Docker Images with Heroku Buildpacks"
date:   2020-05-19 14:12:24
---

Spring Boot 2.3.0 introduced a new feature you can use to [package your app into a Docker image with Cloud Native Buildpacks](https://spring.io/blog/2020/05/15/spring-boot-2-3-0-available-now) (CNB). In this post, you'll learn how to use this mechanism with Heroku buildpacks to create an image you can run on any cloud platform.

The new buildpack support works with both Maven and Gradle by running the command `mvn spring-boot:build-image` or `gradle bootBuildImage` respectively. By default, both use the [Paketo buildpacks](https://paketo.io/) from Cloud Foundry, but the commands can be customized to run any buildpacks (even those you've created yourself).

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

### Adding Your Own Buildpacks

You can introduce custom Cloud Native Buildpacks to the Spring Boot build process by [creating your own builder image](https://buildpacks.io/docs/operator-guide/create-a-builder/). A builder image is a constuct that encapsulates multiple buildpacks so they can be distributed.

You can start with an example like either the [`heroku/spring-boot-buildpacks` builder](https://github.com/heroku/pack-images/blob/e1f0e77b8becc221ac2ca27203cf3d02973d11af/spring-boot-builder.toml) or the default [`gcr.io/paketo-buildpacks/builder:base-platform-api-0.3` builder](https://github.com/paketo-buildpacks/builder) and add your own buildpacks to the `builder.toml. Then use the [Pack CLI](https://buildpacks.io/docs/install-pack/) run a command like:

```
$ pack create-builder my-spring-boot-buildpacks --builder-config ./builder.toml
```

Then run Maven with the `-Dspring-boot.build-image.builder=my-spring-boot-buildpacks` option or Gradle with the `--builder my-spring-boot-buildpacks` option.

### Deploying

In either case (Maven or Gradle), you can deploy the resulting image to the [Heroku Container Runtime](https://devcenter.heroku.com/articles/container-registry-and-runtime) with commands like these:

```
$ heroku create
$ docker tag gradle-getting-started:1.0 registry.heroku.com/<app>/web
$ docker push registry.heroku.com/<app>/web
```

Enjoy!