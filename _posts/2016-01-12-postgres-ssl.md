---
layout: post
title:  "Using SSL with the Postgres JDBC Driver"
date:   2016-01-12 16:02:00
---

The [PostgreSQL JDBC Driver](https://jdbc.postgresql.org/) defaults to using an unencrypted connection.
At Heroku, this presented a problem when
we decided to move certain database types to dedicated single-tenant instances. Our hope was to improve
performance for our customers without them needing to change a single line of code. But the new database instances
required an SSL connection, which meant our customers would need to adjust their database configuration before we
could migrate them.

To make the user experience more streamlined, we decided to turn SSL on globally for anyone using
the Postgres JDBC driver on the platform. In this way, customers would get more powerful databases without even touching their code.

It's useful to understand how we did this because it can be replicated in your development environment to ensure SSL
is used when connecting to a remote test, stage or even production database.

## Setting the SSL Mode

Since version `9.2-1002-jdbc4`, the PostgreSQL JDBC driver has supported the `sslmode` property, which corresponds to the
`sslmode` setting in [libpq](http://www.postgresql.org/docs/current/static/libpq-ssl.html). The desired value when connecting
to a Heroku PostgreSQL server is `sslmode=require`. In a JDBC URL, this might look like this:

{% highlight text %}
jdbc:postgresql://host:5432/db?sslmode=require
{% endhighlight %}

The "require" value ensures that the connection will be encrypted but trusts that the network will make the correct connection.
That is, if there is a certificate present it will validate it, but if a certificate is not present it will still make an encrypted connection.

This parameter can easily be added to a connection string, but that requires a little work to make sure everything is correct in all
the right places. If it is not correct, the connection will fail if the server requires SSL (as they do on Heroku).
Furthermore, there are frameworks that automatically create a
JDBC URL for you, and it is not always simple to append parameters to these URLs.

Thus, Heroku needed a way to set `sslmode` outside of the connection string.

## Adding Driver Properties to the Classpath

The Postgres JDBC Driver will check the JVM's classpath for a `org/postgresql/driverconfig.properties` file, which can
contain any number of properties, just as the JDBC URL would.

On Heroku, we created a small JAR file containing only this properties file, with the following contents:

{% highlight text %}
sslmode=require
{% endhighlight %}

Then, using the [buildpack](https://devcenter.heroku.com/articles/buildpacks),
we put the JAR file in the `lib/ext` directory of the JDK, which means it will be
on the classpath of every JVM-based application on Heroku.

## Do this at home kids

The approach used on Heroku is also great for your local development environment. If you prefer to
developing against a cloud based Postgres instance instead of hosting a Postgres server locally, then
you set the the `sslmode` property for all your projects.

One way to do this is by simply dropping the [Heroku JAR file] that enables SSL into your
`JAVA_HOME/jre/lib/ext` directory. Then if you need to connect to a database without SSL, you
can add the URL parameter `sslmode=disable`. Thus, you'll default to the safe approach.

Another method is to set this property on an app-by-app basis. That is, create a
`src/resources/org/postgresql/driverconfig.properties` file in your project with the
same contents shown above, and put it on the classpath for your app.

Whatever method you choose, you'll know that SSL is being used, which I'm sure your
users will appreciate as much as ours.
