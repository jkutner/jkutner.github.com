---
layout: post
title:  "Inline Buildpacks: Creating Docker Images the Easy Way"
date:   2025-09-24 09:41:00
---

Using buildpacks can be as easy as dropping a `project.toml` in your app repository, and adding some custom logic to build your app. But unlike a `Dockerfile`, the resulting image can benefit from powerful features like [rebase](https://buildpacks.io/docs/for-app-developers/concepts/rebase/) and advanced caching.

In this post, you'll learn how to use a simple inline buildpack to build a Docker image for a Python app. Unlike other examples that use off-the-shelf buildpacks from [Heroku](https://github.com/heroku/buildpacks) or [Paketo](https://paketo.io/), this tutorial will rely only on _your_ custom inline buildpack.

## Getting your app

Let's start with a simple Python app. You can use your own, or clone my example repo:

```
git clone https://github.com/jkutner/python-inline-buildpack
```

Move into the app directory, and you're ready.

## Creating your buildpack

Create a `project.toml` in the root directory of your app, and put the following code in it:

```toml
[_]
schema-version = "0.2"

[io.buildpacks]
builder = "heroku/builder:24"

[[io.buildpacks.group]]
id = "uv-buildpack"

    [io.buildpacks.group.script]
    api = "0.10"
    inline = """#!/bin/bash
curl -LsSf https://astral.sh/uv/install.sh | sh
. $HOME/.local/bin/env

uv sync

cp $HOME/.local/bin/uv .
"""
```

Before you build an image, take a look at what this script is doing. First, it defines the builder image you'll use, `heroku/builder:24`, which contains several buildpacks you could have used instead of your own custom buildpack. But that's not the goal of this tutorial, so you're override those Heroku buildpacks. 

Your custom buildpack is defined in the `io.buildpacks.group` table. The most important part is the `inline` key, which defines the script that will build your app (this is equivilent to a `Dockerfile` in some sense). The `inline` script installs `uv` with `curl`, uses `uv` to install your dependencies, and saves `uv` to the workspace directory so that it's available at runtime.

Great! Now you can build your image.

## Building an image

Install the [Pack CLI](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/) and run the following to create a Docker image from your repo:

```
pack build my-py-app
```

When this has finished, you'll be able to run the image with this command:

```
docker run -p 8080:8080 py-test ./uv run src/python_app.py
```

Now you can view your app running at `http://localhost:8080`. 

That was pretty simple, but you might wonder why this is better than just creating an equivilent `Dockerfile` and running `docker build`. Well, let's discuss that.

## Why is this better?

The code in the `project.toml` you created is comparable to a `Dockerfile`, but it provides all of the powerful features of buildpacks including:
* Rebasing the image (i.e. updating the base image without rebuilding)
* Advanced caching mechanisms that can improve build performance
* Composibility with off-the-shelf buildpacks (you can mix your custom buildpack in with other builpacks)
* Reproduces the same app image digest by re-running the build

These are all standard buildpack features that you can learn more about at [https://buildpacks.io/](https://buildpacks.io/).

## Advanced configuration

The inline buildpack you created earlier is pretty rudimentary. It doesn't cache `uv` or the `.venv` dir it creates. That's a bit of a disadvantage over `Dockerfile` on the surface, but the buildpack interface offers you much more advanced caching mechanisms. 

For example, you could add the following to the end of the script (instead of copying the `uv binary to the working directory):

```
uv_layer="$1/uv"
mkdir -p $uv_layer/bin
cp $HOME/.local/bin/uv $uv_layer/bin/uv

echo "[types]" >> "${uv_layer}.toml"
echo "launch = true" >> "${uv_layer}.toml"
```

This creates a new layer called `"uv"` and defines it's [layer metadata](https://github.com/buildpacks/spec/blob/main/buildpack.md#layer-content-metadata-toml). Once you've created this layer, you can customize how it's cached, and if it should be visible to other buildpacks.

Now you have all the power of Cloud Native Buildpacks at your finger tips, and you didn't even need to create a full-blown buildpack! The down-side is that you can't publish and share this buildpack, but that might be ok if it's very specific to your app. The example here is pretty useful in general, but there are other times where you may just want to run a script that's included with your app. 