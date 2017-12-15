---
layout: post
title:  "Update Your Java Dependencies Early and Often"
date:   2017-12-15 12:01:00
---

Did you know version [2.8.8 of Jackson Databind](http://search.maven.org/#artifactdetails%7Ccom.fasterxml.jackson.core%7Cjackson-databind%7C2.8.8%7Cbundle) (a popular JSON library) has a [deserialization vulnerability](https://github.com/FasterXML/jackson-databind/issues/1599) that can be used to execute any code or command on your system? If you're using this version you need to update your app immediately.

Yet, many really smart Java developers advocate against *ever* updating dependencies so long as they still work. They [argue that keeping older versions of dependencies makes your app more secure](https://stackoverflow.com/questions/4410157/how-to-break-a-maven-build-when-dependencies-are-out-of-date). But their lackadaisical approach to updating versions is what [led Equifax to leave a serious remote-code-execution vulnerability in a production Java Struts app for four months after a fix was available](http://www.ajc.com/business/timeline-the-hacking-equifax/U06rkYrFjPY4NWJ7B0uhuI/).

I'm taking a stand: failing to update dependencies makes your app insecure. Why? Because [more than 70% of real-world attacks exploit a known vulnerability](http://www.verizonenterprise.com/verizon-insights-lab/dbir/) for which a fix is available but has not yet been applied. Updating your dependencies to the latest version may expose you to a [zero-day attack](https://en.wikipedia.org/wiki/Zero-day_(computing)), but that is a much smaller risk.

In this post, you'll learn how to ensure that your Java app is using the latest version of any managed dependency.

## Using Dependency Version Ranges

If you're using Maven to build your app, you probably also use static version numbers in your `pom.xml` like this:

```xml
<dependency>
  <groupId>com.fasterxml.jackson.core</groupId>
  <artifactId>jackson-databind</artifactId>
  <version>2.9.3</version>
</dependency>
```

A static version number will force Maven to use an exact dependency version no matter when or where you build the app. But you can also specify version ranges with Maven. For example:

```xml
<dependency>
  <groupId>com.fasterxml.jackson.core</groupId>
  <artifactId>jackson-databind</artifactId>
  <version>[2.9,)</version>
</dependency>
```

The `[2.9,)` version range instructs Maven to use the latest 2.9.X version of the `jackson-databind` library. With this configuration, the app will pick up security patches each time it's built. There are [many variations on how you can specify ranges in Maven](https://maven.apache.org/enforcer/enforcer-rules/versionRanges.html), which allow you tailor the acceptable versions your app can use.

But version ranges have a problem: your app might use a different version of a dependency depending on when you run the build. Build tools in other language ecosystems&mdash;such as [Bundler (Ruby)](http://bundler.io/),
[Yarn (Node.js)](https://yarnpkg.com/), or [Pipenv (Python)](https://github.com/pypa/pipenv)&mdash;solve this problem with a "lockfile", which records the exact version used for each build while still allowing you to specify a version range (i.e. decoupling the used version from the acceptable versions).

While Maven doesn't have a lockfile, Gradle does. Gradle is a popular alternative to Maven, and I wrote about how to [lock dependency versions in Gradle in an earlier post](http://jkutner.github.io/2017/03/29/locking-gradle-dependencies.html). That's a great choice if you're willing to switch to Gradle.

But there is still hope for Maven. You can use the `maven-enforcer-plugin` to enforce a version range, while locking the version in the `<dependency>` entry. All within your `pom.xml`.

## Enforcing Dependency Version Ranges

In version `3.0.0-M1` of the Maven Enforcer Plugin (a built-in Maven plugin), you can specify [configuration for `<bannedDependencies>` ](https://maven.apache.org/enforcer/enforcer-rules/bannedDependencies.html). For example:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-enforcer-plugin</artifactId>
  <version>3.0.0-M1</version>
  <executions>
    <execution>
      <id>enforce-banned-dependencies</id>
      <goals><goal>enforce</goal></goals>
      <configuration>
        <rules>
          <bannedDependencies>
            <excludes>
              <exclude>com.fasterxml.jackson.core:jackson-databind:(,2.9)</exclude>
            </excludes>
          </bannedDependencies>
        </rules>
        <fail>true</fail>
      </configuration>
    </execution>
  </executions>
</plugin>
```

This configuration ensures that `mvn verify` will fail if a version of `jackson-databind` less than `2.9` is used. You can combine this with an exact version in the `<dependency>` entry for `jackson-databind` to "lock" it.

This is a great improvement, but you still need to know when to update those locked dependencies, and you need a way to update them without manually looking up the latest version in Maven Central. Fortunately, this can all be done automatically.

## Reporting When Dependencies Need Updating

The built-in [Maven Versions Plugin](http://www.mojohaus.org/versions-maven-plugin/) can generate a report of all dependencies that are not using the latest version. Run the following command on any Maven app to see if it's dependencies need updating:

```
$ mvn versions:display-dependency-updates
...
[INFO] --- versions-maven-plugin:2.5:display-dependency-updates (default-cli) @ helloworld ---
[INFO] artifact com.fasterxml.jackson.core:jackson-databind: checking for updates from central
[INFO] The following dependencies in Dependencies have newer versions:
[INFO]   com.fasterxml.jackson.core:jackson-databind ........... 2.8.8 -> 2.9.3
```

If your dependency versions have been extracted into `<property>` elements you can run:

```
$ mvn versions:display-property-updates
...
[INFO] --- versions-maven-plugin:2.5:display-property-updates (default-cli) @ helloworld ---
[INFO] Major version changes allowed
[INFO]
[INFO] The following version property updates are available:
[INFO]   ${jackson-databind.version} .......................... 2.8.8 -> 2.9.3
```

These provide a great visual report, but can also use the `versions:dependency-updates-report` task on your Continuous Integration server to [generate a report file](http://www.mojohaus.org/versions-maven-plugin/dependency-updates-report-mojo.html), which you can send to your email or Slack. Unfortunately (in my opinion), you can't force the outdated dependencies to fail the build.

When you find dependencies that require updating, you can do so by running:

```
$ mvn versions:update-properties
```

This will modify any `<property>` elements that are used for `<dependency>` entries in your `pom.xml`. Then you can commit the changes to version control and resubmit to CI.

## Using a Dependency Reporting Service

The `versions:dependency-updates-report` is a great tool, but it requires a bit of manual work to set up notifications for Slack or email. Fortunately, there are some great services that will do the same thing for you.

My favorite is [VersionEye](https://www.versioneye.com). It hooks into a Github or Bitbucket repository and scans your app for dependencies that can be updated. You can configure it to send notifications for a project or for a specific dependency.

## Recommendations

Ultimately, here is what I believe every Java project using Maven should do:

* Extract all of your dependency versions into property elements.
* Set version ranges in the `maven-enforcer-plugin` for all of your dependencies.
* Run `versions:dependency-updates-report` as part of your CI flow.
* Set up notifications with either the versions report, or with a service like VersionEye.com.
* Run `mvn versions:update-properties` as often as possible.

Here's a [complete example of a what a `pom.xml` should look like](https://gist.github.com/jkutner/93674698888b3da2afe00c98ba88acd4). Stay secure my friends.
