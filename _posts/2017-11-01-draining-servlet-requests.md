---
layout: post
title:  "Draining Servlet Requests"
date:   2017-11-01 10:01:00
---

Restarts happen, but your users shouldn’t notice them. Every user request should run to completion before the server processing them shuts itself down. This is known as draining requests, and it’s described in the [Disposability principle](https://12factor.net/disposability) of the [12-factor app](https://12factor.net/). At a high level, here’s what should happen:

1. A router or proxy stops sending new requests to the server.
2. The server waits for all active requests to finish.
3. When all requests are finished, the server shuts down.

A Tomcat, Jetty, or other servlet container will forcibly terminate all active requests when receiving a signal to shut down, which can result in user’s getting an [HTTP 503](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503). But you can prevent this with the addition of a small servlet Filter.

### Creating a DrainFilter

A [Servlet Filter](https://docs.oracle.com/javaee/7/api/javax/servlet/Filter.html) is an object used to pre-process requests before they reach a Servlet. You can, for example, use Filters to redirect requests based on headers or block requests based on IP address. The Filter shown below will count requests, and wait until they are all complete when shutting down.

```java
public class DrainFilter implements Filter {

  private AtomicInteger activeConnections = new AtomicInteger(0);

  public void init(FilterConfig filterConfig) throws ServletException { }

  public void doFilter(ServletRequest servletRequest,
                       ServletResponse servletResponse,
                       FilterChain filterChain
                      ) throws IOException, ServletException {
    activeConnections.incrementAndGet();
    filterChain.doFilter(servletRequest, servletResponse);
    activeConnections.decrementAndGet();
  }

  public void destroy() {
    while (activeConnections.get() > 0) {
      LockSupport.parkNanos(activeConnections, 1);
    }
  }
}
```

The `doFilter` method is run for every request the server receives. Each time it is invoked, it increments the `activeConnections` counter and continues the FilterChain, which will allow other Filters to run and send the request to a servlet. After the FilterChain is complete, it decrements the `activeConnections` counter.

The `destroy` method is called when the server receives a [SIGTERM signal](https://en.wikipedia.org/wiki/Signal_(IPC)#SIGTERM), which begins the server shut down process. You can send this signal to a foreground process on your Mac or Linux machine by running `kill -15 PID` (you can get the PID using `jps`). This is the proper way to shut down a production server, and it’s exactly what [Heroku](https://heroku.com) does to an app. You should only send SIGKILL, by running `kill -9 PID`, after a predefined timeout period (you can’t wait *forever*). On Heroku, the timeout is 30 seconds.

### Adding the DrainFilter to an App

How you add the DrainFilter depends on what kind of server you’re running. If you’re packaging your app into a WAR file and running it with [Tomcat Webap Runner](https://github.com/jsimone/webapp-runner) (hopefully you’re not still using standalone Tomcat) then you can add the Filter your `web.xml` like this:

```xml
<filter>
  <filter-name>DrainFilter</filter-name>
  <filter-class>com.example.DrainFilter</filter-class>
</filter>
<filter-mapping>
  <filter-name>DrainFilter</filter-name>
  <url-pattern>/*</url-pattern>
</filter-mapping>
```

The `url-pattern` maps this Filter to every route served by the app.

If you’re using embedded Jetty, you can add the Filter programmatically to your `ServletContextHandler` like this:

```java
ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
context.addFilter(DrainFilter.class, "/", EnumSet.of(DispatcherType.REQUEST));
```

But embedded Jetty will not invoke the Filter’s destroy method unless you tell it to like this:

```java
server.setStopAtShutdown(true);
```

### Other Solutions

For Tomcat, It’s possible to drain requests by [configuring a load balancer to monitor active sessions](https://tomcat.apache.org/connectors-doc/common_howto/loadbalancers.html) and wait until they are complete. But solution is specific to Tomcat, and it requires sticky sessions, which introduce problems of their own.

### Shutting Down Gracefully

Draining requests reduces the likelihood of an error happening at shutdown, which makes restarts less painful and thereby easier to perform. When restarts aren't a big deal, you're more likely to redeploy your app, which makes your entire development and release workflow more predictable. Graceful shutdown is an essential characteristic of any continuous deployment implementation.
