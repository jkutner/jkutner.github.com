---
layout: post
title:  "Asynchronous Request Processing with JRuby"
date:   2015-06-04 11:43:00
---

Many Ruby developers have turned to Node.js because it allows them to do the kind of asynchronous programming that improves throughput, latency, and resource utilization. Its inherent non-blocking IO makes asynchronous request processing natural. CRuby doesn't have a built-in async IO solution, but JRuby does!

In this post, you'll learn how to use Servlet 3.1 with Warbler to process requests asynchronously. This allows you to continue using the frameworks you love, such as Sinatra and Rails, without blocking on each request.
Then we'll look at a non-Ruby framework, Netty, which allows you to do low-level non-blocking IO in Java and Scala. But it's just as easy to use it with Ruby.

## Why Process Requests Asynchronously?

Your web server has a limited number of threads that can handle requests, and those
threads often spend their time waiting for a request to do some kind of IO.
That is, the thread is not in use — it's just blocked waiting for some other process
to finish up.

<img src="/assets/images/block-wait.png" style="width: 100%; margin-left: 0; margin-right: 0" alt="Join Server">

Now imagine a request thread being freed up to handle other requests instead of blocking
for a single request to finish. That's async request processing, and it can dramatically improve
throughput in an IO constrained application (such as an app that relies heavily on a database).

## Using Warbler and Servlet 3.x

The Java Servlet 3.x spec introduced support for non-blocking IO in several forms.
We'll demonstrate how to use `javax.servlet.AsyncContext` with a background thread.
To begin, clone my example repository.

{% highlight text %}
$ git clone git@github.com:jkutner/jruby-async-servlets-example.git
{% endhighlight %}

This project contains a simple Sintra app with this route:

{% highlight ruby %}
get '/' do
  response.headers["Transfer-Encoding"] = "chunked"
  async = env['java.servlet_request'].start_async

  Thread.new do
    sleep 10 # something that takes a long time
    async.response.output_stream.println("<p>Asynchronous thing!</p>")
    async.complete
  end

  "<p>Synchronous part!</p>"
end
{% endhighlight %}

This code creates a new `AsyncContext` and then starts a background thread. The
background thread simulates some long process (such as waiting for a database query to finish).
But before the background thread finishes, the request thread will write the "Synchronous part"
to the response body, and move on to handle the next request. When the background thread completes,
it will also write to the response body without the help of the request thread.

You can run the example like this:

{% highlight text %}
$ cd jruby-async-servlets-example
$ bundle install
$ bundle exec warble war
$ java -jar jruby-async-servlets-example.war
...
2015-04-08 09:19:11.078:INFO:oejs.AbstractConnector:Started SelectChannelConnector@0.0.0.0:8080
{% endhighlight %}

Then browse to `http://localhost:8080/` and watch as the output rolls in.

Another feature introduce by Servlet 3.x is the `ReadListener`/`WriteListener`
classes which allow you to asynchronously read from a request body and write to a response body.
These are a little more difficult to use from JRuby, but [kares](http://kares.org/) and I hope to add some
native support for these classes to [jruby-rack](https://github.com/jruby/jruby-rack) in the near future.

## Using Netty

You don't have to use Servlets though. Netty is a client-server framework that isn't based on the Servlet spec. It enables quick and easy development of network applications such as protocol servers and clients. It greatly simplifies and streamlines network programming such as TCP and UDP socket servers. And it's used by some pretty major players including [Apple, Google, Airbnb, Spotify, Twitter, and more](http://netty.io/wiki/adopters.html).

To use Netty, you'll have to leave the comfort of frameworks like Sinatra and Rails -- there isn't a mapping between Rack and Netty like there is for Servlets with [jruby-rack](https://github.com/jruby/jruby-rack). It also requires some pretty low-level HTTP programming.

You can clone my example app like this:

{% highlight text %}
$ git clone git@github.com:jkutner/jruby-netty-example.git
{% endhighlight %}

Then you can install the dependencies by running these commands:

{% highlight text %}
$ cd jruby-netty-example
$ jruby -S gem install jbundler
$ jbundler install
{% endhighlight %}

JBundler will download the Netty dependency for you. Look ma, no XML! Now you can run the app like so:

{% highlight text %}
$ jruby server.rb
{% endhighlight %}

The `server.rb` file is pretty complicated for a "Hello World" example,
and you really have to understand Netty to follow what's going on.
But as you can see, it's pure Ruby code.

{% highlight ruby %}
response = DefaultFullHttpResponse.new(
  HttpVersion::HTTP_1_1,
  HttpResponseStatus::OK,
  Unpooled.wrappedBuffer(content));
{% endhighlight %}

Netty is based on an event-loop in which handlers process IO events generated by the framework. You can see where this is started:

{% highlight ruby %}
boss_group = NioEventLoopGroup.new(1)
worker_group = NioEventLoopGroup.new
{% endhighlight %}

With the event-loop created, we can bootstrap the server:

{% highlight ruby %}
bootstrap = ServerBootstrap.new
bootstrap.group(boss_group, worker_group)
  .channel(NioServerSocketChannel.java_class)
  .option(ChannelOption::SO_BACKLOG, java.lang.Integer.new("200"))
  .childOption(ChannelOption::ALLOCATOR, PooledByteBufAllocator::DEFAULT)
  .childHandler(MyChildHandler.new)
...
future = bootstrap.bind(port.to_i).sync
{% endhighlight %}

The code for the handler is a little complex because the Netty API is very "fine-grained". It's not an application framework. But many frameworks, such as Finagle, Ratpack and Play are built on it. Maybe there's room for a JRuby application framework built on Netty. Or maybe we can bridge Netty to Rack.

## Next Steps

Hopefully I've shown you some cool examples of what's possible with JRuby.
But there is much more to be unlocked.
I'd like to work on the following projects:

* Support for `ReadListener`/`WriteListener` in jruby-rack
* A netty-rack bridge.
* A new Ruby web framework specifically for non-blocking IO, and built on Netty

If you're interested in helping with any of these, reach to me
on [IRC](https://github.com/jruby/jruby/wiki/IRC) or [Twitter](https://twitter.com/codefinger).
