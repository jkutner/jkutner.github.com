---
layout: post
title:  "Customizing JRuby Cipher Suites"
date:   2016-05-10 14:02:00
---

A flurry of [security vulnerabilities](https://en.wikipedia.org/wiki/Logjam_%28computer_security%29)
in the last couple of years has accelerated the deprecation of many
cryptographic protocols and cipher suites. As a result, you might have run into this error if you use JRuby:

{% highlight text %}
Java::JavaLang::RuntimeException: Could not generate DH keypair
    from sun.security.ssl.Handshaker.checkThrown(Handshaker.java:1362)
    from sun.security.ssl.SSLEngineImpl.checkTaskThrown(SSLEngineImpl.java:529)
    ...
{% endhighlight %}

The error occurs when you are trying to invoke a secure service, and the SSL/TLS handshake cannot be completed.

There are many potential causes for this error, including:

* An outdated JDK or JRuby
* A missing cipher suite
* A key size larger than what your JVM supports

If you're hitting this error, the first step is to try updating your JDK. Java 7 only supports key sizes up to 1024 bits by default.
But Java 8 raised this limit to 2048 bits.

Next, try upgrading your JRuby version. Then try updating [jruby-openssl](https://github.com/jruby/jruby-openssl) independently.

{% highlight text %}
$ gem install jruby-openssl
{% endhighlight %}

This will ensure you have the latest version of [Bouncy Castle](http://www.bouncycastle.org), the cryptographic library JRuby uses.

If you're still having problems -- don't worry. Not all is lost.

Before trying anything else, you'll need to capture some data about the service. Try invoking it outside of the JVM by
running [cURL](http://curl.haxx.se) like this (I'm using httpbin.org but you'll replace it with your service's URL):

{% highlight text %}
$ curl -Iv https://httpbin.org/
*   Trying 54.175.219.8...
* Connected to httpbin.org (54.175.219.8) port 443 (#0)
* TLS 1.2 connection using TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
...
{% endhighlight %}

Early in the output, you'll see the security protcol (`TLSv1.2`) and cipher suite (`TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`).

Now let's see if your JVM supports these. Create a file called `ciphers.rb` and put the following code in it:

{% highlight ruby %}
require 'openssl'
con = OpenSSL::SSL::SSLContext.new
con.ciphers.each { |c| puts c[0] }
{% endhighlight %}

Save the file and run it like this:

{% highlight text %}
$ jruby ciphers.rb
EXP-DES-CBC-SHA
EXP-EDH-RSA-DES-CBC-SHA
EXP-EDH-DSS-DES-CBC-SHA
DES-CBC-SHA
EDH-RSA-DES-CBC-SHA
...
{% endhighlight %}

This list is not exactly the same as what the JVM supports natively. You can get the list of natively support JVM ciphers by running this script:

{% highlight ruby %}
require 'java'
java_import 'javax.net.ssl.SSLServerSocketFactory'
ssf = SSLServerSocketFactory.get_default
ciphers = ssf.get_default_cipher_suites
ciphers.each { |c| puts c }
{% endhighlight %}

Hopefully you'll see the cipher cURL used in one of these lists (for the OpenSSL list you have to convert the snake-case format to kebab-case and remove the TLS).

Now test you service in JRuby, independently of your application, by creating a `test.rb` script with these contents:

{% highlight ruby %}
require 'net/http'
uri = URI.parse("https://httpbin.org/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.get(uri.request_uri)
{% endhighlight %}

And run the script with this command:

{% highlight text %}
$ jruby -J-Djavax.net.debug=all test.rb
{% endhighlight %}

The `javax.net.debug=all` property will cause the JVM to print out a lot of information about the SSL/TLS handshake.
Somewhere in the loads of output you'll see some lines like this:

{% highlight text %}
...
Ignoring unavailable cipher suite: TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
Ignoring unavailable cipher suite: TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
Ignoring unavailable cipher suite: TLS_DH_anon_WITH_AES_256_GCM_SHA384
Cipher Suites: [TLS_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_RSA_WITH_AES_128_CBC_SHA, TLS_DHE_DSS_WITH_AES_128_CBC_SHA, SSL_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA, SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA, SSL_RSA_WITH_DES_CBC_SHA, SSL_DHE_RSA_WITH_DES_CBC_SHA]
Cipher Suite: TLS_DHE_RSA_WITH_AES_128_CBC_SHA
%% Initialized:  [Session-1, TLS_DHE_RSA_WITH_AES_128_CBC_SHA]
...
{% endhighlight %}

Notice that the list of cipher suites is not exactly complete. And there are probably some important cipher suites in the list of those ignored.

Even though the runtime says they are unavailable, you can still enable them. Modify your `test.rb` script to include to look like this:

```ruby
require 'openssl'
require 'net/http'

uri = URI.parse("https://httpbin.org/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.ssl_version = :"TLSv1_2"
http.ciphers = OpenSSL::SSL::SSLContext.new.ciphers.map do |c|
  c[0].gsub("-", "+")
end

http.get(uri.request_uri)
```

This sets the list of default ciphers available to the Ruby runtime as those provided by `openssl`, and ultimately the underlying Bouncy Castle implementation.
It also set the `ssl_version` to `TLSv1_2`, which is a good idea because earlier versions have vulnerabilities.

Run the script again, and you should be able to make a successful connection.

I hope this helps anyone running into the same problem.