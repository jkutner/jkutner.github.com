---
layout: post
title:  "Deploying Clojure Apps to Heroku with Docker"
date:   2015-08-17 09:43:00
---

In this post, you'll learn how to deploy a Docker-based Clojure application to Heroku using the [Heroku Docker CLI](https://devcenter.heroku.com/articles/docker). We'll use the [Immutant Feature Demo](https://github.com/immutant/feature-demo) as an example, but you can follow along with any Clojure application as long as it uses Leiningen to build an [uberjar](https://github.com/technomancy/leiningen/blob/master/doc/TUTORIAL.md#uberjar). This is a Mac and Linux guide only (until Docker supports `docker-compose` on Windows).

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

To begin, clone the [Immutant demo app](https://github.com/immutant/feature-demo) to your local machine
(if you'd prefer a bare-bones Clojure app you can substitute [this Ring app](https://github.com/heroku/clojure-getting-started)):

{% highlight text %}
$ git clone https://github.com/immutant/feature-demo
$ cd feature-demo
{% endhighlight %}

The app is already prepared for Heroku. It contains a `Procfile`, which [tells Heroku how to run the app](https://devcenter.heroku.com/articles/procfile), and an `app.json` file that contains some meta-data about the app. The important part of the `app.json` file is the `"image"` element, shown below:

{% highlight json %}
{
  "name": "Immutant Feature Demo",
  "description": "A template for getting started with the popular Immutant framework.",
  "website": "http://immutant.org",
  "success_url": "/index.html",
  "addons": ["heroku-postgresql"],
  "image": "heroku/clojure"
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

This created a `Dockerfile` based on the `heroku/clojure` image and a `docker-compose.yml` that constructs the environment (including a local database running in a Docker container).

Now run this command to start the application in a container:


{% highlight text %}
$ docker-compose up web
...
Step 0 : RUN lein uberjar
 ---> Using cache
 ---> ada3689e717a
Successfully built ada3689e717a
...
{% endhighlight %}

The first time you run this it will take a while as Leiningen downloads the app's dependencies into the Docker container. But don't worry, they'll be cached.

When the container has started, you'll see some output like this:

{% highlight text %}
web_1              | boop
web_1              | boop
web_1              | beep
web_1              | boop
{% endhighlight %}

That's Immutant demonstrating it's scheduling feature.

Open the app in a browser by running this command:

{% highlight text %}
$ open http://$(docker-machine ip default):8080
{% endhighlight %}

After you've played around with some of the features, like WebSockets, you can deploy the app to Heroku. First, provision a new app thusly:

{% highlight text %}
$ heroku create
{% endhighlight %}

And deploy to Heroku with the Docker CLI

{% highlight text %}
$ heroku create
Creating limitless-mesa-1279... done, stack is cedar-14
https://limitless-mesa-1279.herokuapp.com/ | https://git.heroku.com/limitless-mesa-1279.git

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

Then you can open the app with this command:

{% highlight text %}
$ heroku open
{% endhighlight %}

Note that when using WebSockets in Firefox, you'll need to use an `http://` addres instead of the `https://` that Heroku defaults to.

## Development Workflow

In your normal workflow, you'd want to make some changes and see them appear in the Docker container. We'll demonstrate how that works. Open the `src/demo/scheduling.clj` file and look for this code:

{% highlight clojure %}
;; start a couple of jobs, along with a job to stop them in 20 seconds
(let [beep (sch/schedule #(println "beep") every-5s)
      ;; schedule a clj-time sequence
      boop (immutant.scheduling.joda/schedule-seq #(println "boop") (every-3s-lazy-seq))]
  (sch/schedule
    (fn []
      (println "unscheduling beep & boop")
      (sch/stop beep)
      (sch/stop boop))
    (in 20 :seconds)))
{% endhighlight %}

Change the `"beep"` string on the first line to `"crocodile"`.
Save the file, and then run these commands to rebuild the image:

{% highlight text %}
$ docker-compose build web
Building web...
Step 0 : FROM heroku/clojure
...
Removing intermediate container aedc7b201c86
Successfully built 6bd2d6e9a3ba

$ docker-compose up web
...
web_1              | boop
web_1              | boop
web_1              | crocodile
web_1              | boop
{% endhighlight %}

Open the app in a browser again and navigate to the `/hello` path. You'll see your changes. Each time modify your app, you need to re-build the image and then launch the `up` command. You can also get terminal access to the image by running the `shell` command thusly:

{% highlight text %}
$ docker-compose run shell
Building shell...
...
root@7c7b5905b2a0:~/user#
{% endhighlight %}

From this shell, you can run one-off tasks like database migrations.

Heroku's Docker support is currently in beta. As we work to make the integration
better, we'd love to hear your feedback so we can focus on building the things you need.
Feel free to reach out to me directly with you thoughts and ideas.

You can visit the Heroku Dev Center for more information on [Heroku's Docker CLI](https://devcenter.heroku.com/articles/docker).
And you can learn more about [Immutant](http://immutant.org/) and [Docker](https://docs.docker.com/)
from their respective documentation sites. You can also find more information about
[deploying Clojure apps to Heroku](https://devcenter.heroku.com/articles/deploying-clojure) on the Dev Center.
