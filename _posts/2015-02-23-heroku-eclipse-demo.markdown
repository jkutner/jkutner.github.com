---
layout: post
title:  "How to Deploy to Heroku from Eclipse"
date:   2015-02-23 22:18:00
---

This short video (less than a minute and a half) demonstrates how to create,
deploy and configure a Heroku application from Eclipse.

<iframe width="560" height="315" src="https://www.youtube.com/embed/NcCeUp4rygU?vq=hd720" frameborder="0" allowfullscreen></iframe>

You may have noticed the `pom.xml` file in this example contains some configuration
for the [heroku-maven-plugin](https://github.com/heroku/heroku-maven-plugin).
That code is shown below:

{% highlight xml %}
<plugin>
  <groupId>com.heroku.sdk</groupId>
  <artifactId>heroku-maven-plugin</artifactId>
  <version>0.3.4</version>
  <configuration>
    <appName>${heroku.appName}</appName>
  </configuration>
</plugin>
{% endhighlight %}

For a more detailed description of how to configure the plugin, see the
Heroku DevCenter article [Deploying Java Applications with the Heroku Maven Plugin](https://devcenter.heroku.com/articles/deploying-java-applications-with-the-heroku-maven-plugin).

The DevCenter also has a textual walk through of the steps required to
[Deploy Java Applications to Heroku from Eclipse](https://devcenter.heroku.com/articles/deploying-java-applications-to-heroku-from-eclipse-or-intellij-idea)
