---
layout: post
title:  "Deploying Gradle Apps to Heroku with Docker"
date:   2015-08-17 09:43:00
---

In this post, you'll learn how to deploy a Docker-based Gradle application to Heroku using the [Heroku Docker CLI](https://devcenter.heroku.com/articles/docker). We'll use a simple [Ratpack](http://ratpack.io/) app as an example, but you can follow along with any Gradle application. This is a Mac and Linux guide only (until Docker supports `docker-compose` on Windows).

## Prerequisites

You'll need a few pieces of software before you get started:

* Docker (easily installed with the [Docker Toolbox](https://www.docker.com/toolbox))
* Docker Compose (You'll have this if you installed the Toolbox)
* [Heroku Toolbelt](https://toolbelt.heroku.com/)

You'll also need to create a [free Heroku account](http://heroku.com/). Then login from the terminal like so:

{% highlight text %}
$ heroku login
{% endhighlight %}

Once that's complete, you can install the Heroku Docker CLI with this command:

{% highlight text %}
$ heroku plugins:install heroku-docker
{% endhighlight %}

Now you're ready to deploy.

## Deploying an App

To begin, clone the [Ratpack demo app](https://github.com/heroku/gradle-getting-started) to your local machine:

{% highlight text %}
$ git clone https://github.com/heroku/gradle-getting-started
$ cd gradle-getting-started
{% endhighlight %}

The app is already prepared for Heroku. It contains a `Procfile`, which [tells Heroku how to run the app](https://devcenter.heroku.com/articles/procfile), and an `app.json` file that contains some meta-data about the app. The important part of the `app.json` file is the `"image"` element, shown below:

{% highlight json %}
{
  "name": "Getting Started with Gradle on Heroku",
  "description": "A bare-bones Ratpack app, which can easily be deployed to Heroku.",
  "image": "heroku/gradle",
  "addons": [ "heroku-postgresql" ]
}
{% endhighlight %}

The `"image"` element is what Heroku uses to determine the base Docker image to run the container from.
The `"addons"` element determines what additional services will be attached to your container. The Heroku
currently supports Postgres, Redis and a few others services with more to come.
Given this configuration, we can initialize the app with the following command:

{% highlight text %}
$ heroku docker:init
Wrote Dockerfile
Wrote docker-compose.yml
{% endhighlight %}

This created a `Dockerfile` based on the `heroku/gradle` image and a
`docker-compose.yml` defining the containers in your environemnt
(including a local Postgres database running on Docker).

Now run this command to start the application in a container:

{% highlight text %}
$ docker-compose up web
{% endhighlight %}

The first time you run this it will take a while as Gradle downloads the app's dependencies into the Docker container. Dut don't worry, they'll be cached. You'll also see a Postgres database initialize and start up -- all running locally.

When the container has finished booting, you'll see some output like this:

{% highlight text %}
web_1 | [main] INFO ratpack.server.RatpackServer - Ratpack started for http://localhost:8080
{% endhighlight %}

Open the app in a browser by running this command:

{% highlight text %}
$ open "http://$(docker-machine ip default):8080"
{% endhighlight %}

Now try accessing the database. The sample contains a little bit of code that inserts a value into a column. It looks like this:

{% highlight java %}
Statement stmt = connection.createStatement();
stmt.executeUpdate("CREATE TABLE IF NOT EXISTS ticks (tick timestamp)");
stmt.executeUpdate("INSERT INTO ticks VALUES (now())");
ResultSet rs = stmt.executeQuery("SELECT tick FROM ticks");
{% endhighlight %}

Browse to the `/db` path to see it in action:

{% highlight text %}
$ open "http://$(docker-machine ip default):8080/db"
{% endhighlight %}

Your containerized web app and database are now connected. You've created a local cloud right here on your machine. Now you can create a Heroku app and deploy to the public cloud.
First, provision a new app thusly:

{% highlight text %}
$ heroku create
Creating limitless-mesa-1279... done, stack is cedar-14
https://limitless-mesa-1279.herokuapp.com/ | https://git.heroku.com/limitless-mesa-1279.git
{% endhighlight %}

And deploy to Heroku with the Docker CLI

{% highlight text %}
$ heroku docker:release
Remote addons: heroku-postgresql (1)
Local addons: heroku-postgresql (1)
Missing addons:  (0)
Creating local slug...
Building web...
...
uploading slug...
releasing slug...
Successfully released limitless-mesa-1279!
{% endhighlight %}

You can open the remote app with this command:

{% highlight text %}
$ heroku open
{% endhighlight %}

Now you can get to work on modifying this app.

## Development Workflow

In your normal workflow, you'd want to make some changes and see them appear in the Docker container. We'll demonstrate how that works. Open the `src/main/java/Main.java` and look for the `/hello` route:

{% highlight java %}
.get("hello", ctx -> {
  ctx.render("Hello!");
})
{% endhighlight %}

Change the `"Hello!"` string to anything you'd like. Save the file, and then run these commands:

{% highlight text %}
$ docker-compose build web
...
$ docker-compose up web
...
web_1 | [main] INFO ratpack.server.RatpackServer - Ratpack started for http://localhost:8080
{% endhighlight %}

Open the app in a browser again and navigate to the `/hello` path to see your changes. Each time you modify your app, you need to re-build the image and then launch the `up` command. You can also get terminal access to the image by running the `shell` command thusly:

{% highlight text %}
$ docker-compose build shell
Building shell...
...
root@7c7b5905b2a0:~/user#
{% endhighlight %}

From this shell, you can run one-off tasks like database migrations.

Heroku's Docker support is currently in beta. As we work to make the integration
better, we'd love to hear your feedback so we can focus on building the things you need.
Feel free to reach out to me directly with you thoughts and ideas.

You can visit the Heroku Dev Center for more information on [Heroku's Docker CLI](https://devcenter.heroku.com/articles/docker
  ).
And you can learn more about [Ratpack](http://ratpack.io/) and [Docker](https://docs.docker.com/)
from their respective documentation sites. You can also find more information about
[deploying Gradle apps to Heroku](https://devcenter.heroku.com/articles/deploying-gradle-apps-on-heroku) on the Dev Center.
