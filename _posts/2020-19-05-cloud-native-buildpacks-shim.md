---
layout: post
title:  "Using your Heroku Buildpacks with the Pack CLI"
date:   2020-05-18 09:12:24
---

You can't teach an old dog new tricks, but you can wrap it in an API compatibility layer. In this post, you'll learn how to use older versions of Heroku Buildpacks with the [Pack CLI](https://buildpacks.io/docs/install-pack/) by wrapping them in a Cloud Native Buildpack shim using a URL in the form:

```
https://cnb-shim.herokuapp.com/v1/<namespace>/<name>
```

[Cloud Native Buildpacks](https://buildpacks.io) (CNB) are a new way of building Docker images without a `Dockerfile`, but they're based on a much older technology: [Heroku Buildpacks](https://devcenter.heroku.com/articles/buildpacks). Buildpacks were first created almost 10 years ago as a way of adding multiple-language support for the Heroku platform. Over time, other platforms adopted the technology, but the lack of neutral governance for the Buildpack API led to a fracturing of the ecosystem. In 2018, the ecosystem rejoined with [a new unified API under the CNCF](https://blog.heroku.com/buildpacks-go-cloud-native).

<img src="/assets/images/buildpacks-history.png" style="width: 100%; margin-left: 0; margin-right: 0" alt="Buildpacks History">

The new API version broke compatibility with existing Heroku buildpacks (which we call `v2(a)` buildpacks). But we didn't want to eschew the thousands of existing buildpacks, so we built a [`v2(a)` to CNB compatibility layer](https://github.com/heroku/cnb-shim) or "CNB shim".

The CNB shim can be used with any buildpack in the [Heroku Buildpack Registry](https://devcenter.heroku.com/articles/buildpack-registry). After finding a buildpack with the `heroku buildpacks:search` command or publishing a buildpack with the `heroku buildpacks:register` command, you can use it with the Pack CLI by referencing a URL in the form: `https://cnb-shim.herokuapp.com/v1/<namespace>/<name>`. For example, to use the [Elixir Buildpack](https://github.com/hashnuke/heroku-buildpack-elixir) you might run:

```
$ git clone https://github.com/HashNuke/heroku-buildpack-elixir-test elixir-app
$ cd elixir-app
$ pack build -b https://cnb-shim.herokuapp.com/v1/hashnuke/elixir -B heroku/buildpacks:18 elixir-app
```

Then you can run that image with a command like:

```
$ docker run -it -e PORT=5000 -p 5000:5000 elixir-app
```

You can also use this URL in your [`builder.toml`](https://buildpacks.io/docs/operator-guide/create-a-builder/) or `project.toml`.

### Tradeoffs

The downside to using the shim is that `v2(a)` buildpacks can't create more than one layer. Your entire app and its dependencies will be baked into one large layer in the Docker image (a bit like a [Heroku slug](https://devcenter.heroku.com/articles/slug-compiler)). However, the base image still has its own layers.

The upside, in addition to easily turning your source code into a Docker image, is that you can update your base image with the [`pack rebase`](https://buildpacks.io/docs/concepts/operations/rebase/) command. Rebasing is one of the biggest advantages of buildpacks over other Docker build mechanisms because it allows you to apply certain kinds of security patches without rebuilding the image.

The official `heroku/buildpacks:18` builder image uses the CNB shim for several of the officially supported buildpacks (as you can see from its [`builder.toml`](https://github.com/heroku/pack-images/blob/master/builder.toml)). But it also includes some first-class CNBs (like the Node.js, Java, and Ruby CNBs).

Whatever buildpacks you choose to run, you'll gain the composibility, modularily, speed, and security of the buildpack ecosystem.