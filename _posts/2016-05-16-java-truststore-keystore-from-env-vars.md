---
layout: post
title:  "Creating Java TrustStores and KeyStores from Environment Variables"
date:   2016-05-12 14:02:00
---

Java apps have traditionally managed TrustStores and KeyStores as regular files on the filesystem in JKS format with `keytool`.
This mechanism was fine when the state-of-the-art in system administration required copying files from server to server.
But in the era of the cloud, our apps need a better system.

The [12-factor manifesto](http://12factor.net/config)
encourages the use of environment variables for secrets, credentials, and any configuration that changes
between environments. KeyStores and TrustStores fall into this category. You don't want to store your private key as a file on someone
else's computer, and the certificates you provide will likely differ between environments (for example, you might use self-signed certs
in staging and offical certs in prod).

In this post, you'll learn how to dynamically create KeyStores and TrustStores in Java from environment variables
using the [EnvKeyStore](https://github.com/jkutner/env-keystore) library, which I created to relieve some pain
points in the [Kafka Java Client](https://cwiki.apache.org/confluence/display/KAFKA/Clients#Clients-Java).
But it's useful for all kinds of servers and clients.

### Using a TrustStore

To demonstrate the use of an in-memory TrustStore, we'll invoke a service that has
a self-signed certificate. By default, the HTTP client will reject this call because
the certificate cannot be trusted.

Clone the [EnvKeyStore examples project](https://github.com/jkutner/env-keystore-examples) by running
this command:

```
$ git clone https://github.com/jkutner/env-keystore-examples
```

In the project you'll find a `TrustStoreExample` class that looks like this:

```java
public class TrustStoreExample {
  public static void main(String[] args) throws Exception {
    String urlStr = "https://ssl.selfsigned.xyz";
    URL url = new URL(urlStr);
    HttpsURLConnection conn = (HttpsURLConnection)url.openConnection();
    conn.setDoInput(true);
    conn.setRequestMethod("GET");
    conn.getInputStream().close();
  }
}
```

Compile the class with `mvn package`, and run it with this command:

```
$ java -cp target/app.jar TrustStoreExample
```

You'll get the following exception:

```
Exception in thread "main" javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
        at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
        at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1949)
        at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:302)
        ...
```

To fix the error, we'll add the service's certificate to a TrustStore used by the HTTP client.

The certification can be downloaded at [http://www.selfsigned.xyz](http://www.selfsigned.xyz) (this is a sample service I created
just for the purpose of testing self-signed certs), or you can run the following command on *nix platforms to set it as an environment
variable.

```
$ export TRUSTED_CERT="$(curl http://www.selfsigned.xyz/server.crt)"
```

On Windows you'll need to use the `set` command with the contents you downloaded from the site.

Now modify your Java class by adding this code to the begining of the `main` method:

```java
KeyStore ts = new EnvKeyStore("TRUSTED_CERT").keyStore();

String tmfAlgorithm = TrustManagerFactory.getDefaultAlgorithm();
TrustManagerFactory tmf = TrustManagerFactory.getInstance(tmfAlgorithm);
tmf.init(ts);

SSLContext sc = SSLContext.getInstance("TLSv1.2");
sc.init(null, tmf.getTrustManagers(), new SecureRandom());
HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
```

The first line captures the certificate from the environment variable
and creates a `KeyStore` object. The remaining lines are boilerplate Java code that
registers the `KeyStore` with an `SSLContext`.

Now recompile the class by running `mvn package` again, and run the
`java -cp target/app.jar TrustStoreExample` command one more time.
It will invoke the service successfully now.

This mechanism saves you from creating a `cacerts` file and uploading it to each
of your production servers. Or worse: checking that file into a Git repository,
which couples it to the codebase.
But this mechanism is even more important when it comes to KeyStores.

### Using a KeyStore

If you're terminating an SSL connection on the server side, you have to manage
a secret key, a public certificate and a password. All of these can be stored
as environment variables the `EnvKeyStore` can extract.

To demostrate this, we'll create a [Ratpack](http://ratpack.io) HTTP server. The
code for this is in the [env-keystore-examples](https://github.com/jkutner/env-keystore-examples)
project in the `KeyStoreExample` class.
It looks like this:

```java
public class KeyStoreExample {
  public static void main(String[] args) throws Exception {
    EnvKeyStore eks = EnvKeyStore.create(
        "KEYSTORE_KEY", "KEYSTORE_CERT", "KEYSTORE_PASSWORD");
    RatpackServer.start(s -> s
      .serverConfig(c -> {
        c.baseDir(BaseDir.find());
        c.ssl(SSLContexts.sslContext(eks.toInputStream(), eks.password()));
      })
      .handlers(chain -> chain
        .all(ctx -> ctx.render("Hello from Ratpack!"))
      )
    );
  }
}
```

Before you can run this class, you'll need to create the secrets and set them as environment variables.
If you have [`openssl` installed](https://devcenter.heroku.com/articles/ssl-certificate-self#prerequisites)
you can create one by running these commands:

```
$ openssl genrsa -des3 -passout pass:x -out server.pass.key 2048
...
$ openssl rsa -passin pass:x -in server.pass.key -out server.key
writing RSA key
$ rm server.pass.key
$ openssl req -new -key server.key -out server.csr
...
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:California
...
A challenge password []:
...
$ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

Now set your environment variables thusly:

```
$ export KEYSTORE_KEY="$(cat server.key)"
$ export KEYSTORE_CERT="$(cat server.crt)"
$ export KEYSTORE_PASSWORD="password"
```

Then run the server with this command:

```
$ java -cp target/app.jar KeyStoreExample
[main] INFO ratpack.server.RatpackServer - Starting server...
[main] INFO ratpack.server.RatpackServer - Building registry...
[main] INFO ratpack.server.RatpackServer - Ratpack started for https://localhost:5050
```

Finally, open a browser to [https://localhost:5050](https://localhost:5050). After you accept the
security exception for the self-signed cert, you'll see the "Hello" page.

You can learn more about including the `EnvKeyStore` library in your app by reading the
[project's README](https://github.com/jkutner/env-keystore/blob/master/README.md).
In short, you only need to included it as a Maven dependency like this:

```xml
<dependency>
  <groupId>com.github.jkutner</groupId>
  <artifactId>env-keystore</artifactId>
  <version>0.1.0</version>
</dependency>
```

Then use the `EnvKeyStore` class as described above. Enjoy!