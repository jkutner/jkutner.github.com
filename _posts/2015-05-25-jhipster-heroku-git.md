---
layout: post
title:  "Deploying JHipster Apps to Heroku with Git"
date:   2015-05-25 11:43:00
---

JHipster is a [Yeoman](http://yeoman.io/) generator used to create
[Spring Boot](http://projects.spring.io/spring-boot/) and
[AngularJS](https://angularjs.org/) apps.

I've contributed improvements to a [Heroku](https://heroku.com) sub-generator for
deploying a JHipster app as a prepackaged WAR file to the Heroku PaaS. But it's
also possible to deploy to Heroku using Git. The advantage of using Git is that
Heroku will preprocess all Javascript files for you so you don't have to do it
locally.

## Creating a JHipster app

To begin, make sure you have [the JHipster dependencies installed](http://jhipster.github.io/installation.html).
Then generate a new JHipster app (make sure you choose PostgreSQL for the database. I've included my choice for the other setup questions):

{% highlight text %}
$ mkdir myapp/
$ cd myapp/
$ yo jhipster
...
? (3/14) Do you want to use Java 8? Yes (use Java 8)
? (4/14) Which *type* of authentication would you like to use? HTTP Session Authentication (stateful, default Spring Security mechanism)
? (5/14) Which *type* of database would you like to use? SQL (H2, MySQL, PostgreSQL)
? (6/14) Which *production* database would you like to use? PostgreSQL
? (7/14) Which *development* database would you like to use? H2 in-memory with Web console
? (8/14) Do you want to use Hibernate 2nd level cache? No
? (9/14) Do you want to use a search engine in your application? No
? (10/14) Do you want to use clustered HTTP sessions? No
? (11/14) Do you want to use WebSockets? No
? (12/14) Would you like to use Maven or Gradle for building the backend? Maven (recommended)
? (13/14) Would you like to use Grunt or Gulp.js for building the frontend? Grunt (recommended)
? (14/14) Would you like to use the Compass CSS Authoring Framework? No
{% endhighlight %}

Now you can get it ready for Heroku.

## Preparing for Heroku

Create a [Heroku account](http://heroku.com) and install the [Heroku Toolbelt](https://toolbelt.heroku.com/).

Now run the sub-generator to prepare the application for Heroku:

{% highlight text %}
$ yo jhipster:heroku
{% endhighlight %}

This will actually provision a new Heroku app, and deploy a WAR file to it.
That's not the goal of this article, but it will ensure that your app is
prepared with a PostgreSQL database and some other things.

*NOTE: It is very likely that the app will timeout during the boot process, and
the app will fail to start. Heroku imposes a default boot-time limit of 60
seconds, and Spring's auto-configuration takes up a good portion of that. Add to
that Tomcat's JAR scanning and booting under 60 seconds it tough. However,
this is easy to remedy by simply asking [Heroku Support](https://help.heroku.com/) to increase your
boot timeout to 120 seconds.*

When the Heroku app was provisioned, a Git repository was also created with a
Git remote for Heroku. Before moving on, make sure you've committed everything
to this repo:

{% highlight text %}
$ git add .
$ git commit -m "Prepared for Heroku"
{% endhighlight %}

Now you can deploy to that Heroku Git remote.

## Deploying with Git

Check that your Git repo has the Heroku remote by running this command:

{% highlight text %}
$ git remote
heroku
{% endhighlight %}

Now, preare the remote Heroku application for JHipster by adding the Node.js
and Java buildpacks:

{% highlight text %}
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-nodejs.git
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-java.git
{% endhighlight %}

Then define the Maven options such that the correct profiles are used:

{% highlight text %}
$ heroku config:set MAVEN_CUSTOM_OPTS="-Pprod,heroku -DskipTests"
{% endhighlight %}

Now prepare the NPM configuration so that Heroku can use Bower and Grunt. Run
this command:

{% highlight text %}
$ npm install bower grunt-cli --save
{% endhighlight %}

Your `package.json` now contains something like this (which you could also have added manually instead of running the `npm` command):

{% highlight json %}
"dependencies": {
  "bower":"1.4.1",
  "grunt-cli":"0.1.13"
}
{% endhighlight %}

Next, add a Maven profile to clear some unneeded build-time dependencies from the slug.
Add this code to your `pom.xml` in the `<profiles>` section:

{% highlight xml %}
<profile>
  <id>heroku</id>
  <build>
    <plugins>
      <plugin>
      <artifactId>maven-clean-plugin</artifactId>
      <version>2.5</version>
      <executions>
        <execution>
          <id>clean-build-artifacts</id>
          <phase>install</phase>
          <goals><goal>clean</goal></goals>
          <configuration>
            <excludeDefaultDirectories>true</excludeDefaultDirectories>
            <filesets>
              <fileset>
                <directory>node_modules</directory>
              </fileset>
              <fileset>
                <directory>.heroku/node</directory>
              </fileset>
              <fileset>
                <directory>target</directory>
                <excludes>
                  <exclude>*.war</exclude>
                </excludes>
              </fileset>
            </filesets>
          </configuration>
        </execution>
      </executions>
      </plugin>
    </plugins>
  </build>
</profile>
{% endhighlight %}

Now add the `package.json` and `pom.xml` changes to Git by running these commands:

{% highlight text %}
$ git add package.json pom.xml
$ git commit -m "Update for Heroku Git"
{% endhighlight %}
Finally, deploy with Git:

{% highlight text %}
$ git push heroku master
{% endhighlight %}

Heroku will install Node.js, NPM, Bower and Grunt. Then Maven will execute and preprocess your Javascript assets.

You can view your app by running this command:

{% highlight text %}
$ heroku open
{% endhighlight %}

If you have any trouble, reach out to [Heroku Support](https://help.heroku.com/).
