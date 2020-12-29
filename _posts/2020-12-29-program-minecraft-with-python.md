---
layout: post
title:  "Programming Minecraft with Python in Docker"
date:   2020-12-29 14:09:24
---

In this post, you'll learn how to use Python to program a Minecraft server running in a Docker container.

A Docker container is an isolated environment where you can set up programs and run commands in a controlled and reproducible way. If you make a mistake, it's no problem; just delete the container start again. This makes the complicated process of setting up a Minecraft server much more dependable.

To begin, you'll need to install a few tools and create a Docker image for your server.

### Build the image

To run the commands in this tutorial, you'll need to install [Pack](https://buildpacks.io/docs/tools/pack/), which requires that you also install [Docker](https://www.docker.com/products/docker-desktop). Make sure every thing is working by running:

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED

$ pack --version
0.15.1
```

Next, create a directory to store your Minecraft server. On Mac or Linux run:

```
$ git clone https://github.com/jkutner/minecraft-python-server
$ cd minecraft
```

Now use Pack to create a Minecraft server Docker image using the [Minecraft buildpack](https://github.com/jkutner/minecraft-buildpack) by running this command:

```
$ pack build --builder jkutner/minecraft-builder:18 minecraft
```

Check that your image is ready by running this command:

```
$ docker image ls minecraft
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
minecraft           latest              bbc0352e09ea        41 years ago        1.21GB
```

(don't worry, it's [not really 41 years ago](https://medium.com/buildpacks/time-travel-with-pack-e0efd8bf05db))

Now you're ready to run the server.

### Run the image locally

You'll begin by running the server locally (on your personal computer), but later on you can deploy it to a cloud platform. Use the `docker run` command to start a container with the image you created in the previous section:

```
$ docker run -it -p 4711:4711 -p 25566:25566 minecraft
```

The new container will expose two [ports](https://en.wikipedia.org/wiki/Port_%28computer_networking%29) (4711 and 25566), which you'll use to connect to the server.

Test it by openning your Minecraft app. Install version 1.12.2 and launch the game. Then select "Multiplayer" and "Direct Connection", and paste the address `localhost:25566 as the "Server Address" and click "Join Server".

Leave your player in the game, and return to your terminal session to start using Python.

### Use Python to connect

To use Python with your server, you'll need to have [Python installed](https://wiki.python.org/moin/BeginnersGuide/Download) on your machine. Once it's installed, you'll be able to start a Python shell by running

```
$ python --version
Python 3.9.1
```

Install the mcpi package (note: on some computers you'll need to run `pip3` instead of `pip`):

```
$ pip install mcpi
```

Now start a Python shell session by running the `python` command with no arguments:

```
$ python
Python 3.9.1 (default, Dec 10 2020, 10:36:35)
[Clang 12.0.0 (clang-1200.0.32.27)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

From the `>>>` prompt, you can start using the `mcpi` library. First, you'll need to import the library by running:

```
>>> from mcpi.minecraft import Minecraft
```

Then create a new client:

```
>>> mc = Minecraft.create()
```

Finally, you can use the `mc` variable to run commands against your Minecraft server. For example, you can get the type of block located at position `x=0`, `y=0`, `z=0`:

```
>>> mc.getBlock(0,0,0)
1
```

Or you can teleport your player to a new location on the board:

```
>>> mc.player.setTilePos(0,100,0)
```

A full list of available commands can be found in the [mcpi documentation](https://github.com/martinohanlon/mcpi).

Now you're ready to start hacking on your Minecraft server. The `mcpi` library let's you teleport, turn blocks into gold, instantly generate structures, and even save structures.

### How it works

The repository you cloned from Github contains a `plugins.txt` file. This file indicates that we want to use [Spigot](https://www.spigotmc.org/), which is a modified Minecraft server that provides additional features while remaining compatible with normal Minecraft game mechanics. A Spigot server can be extended by installing plugins. You've added the [RaspberryJuice plugin](https://www.spigotmc.org/resources/raspberryjuice.22724/), which is needed to use Python.

### Resources

I lot of this setup is derived from the instructions in the book [Learn to Program with Minecraft](https://nostarch.com/programwithminecraft) from [No Starch Press](https://nostarch.com/). I strongly recommend it if you're new to either Python or Minecraft.
