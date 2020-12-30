---
layout: post
title:  "Programming Minecraft with Python in Docker"
date:   2020-12-29 14:09:24
---

In this post, you'll learn how to use Python to program a Minecraft server running in a Docker container.

A Docker container is an isolated environment where you can set up programs and run commands in a controlled and reproducible way. If you make a mistake, it's no problem; just delete the container start again. This makes the complicated process of setting up a Minecraft server much more dependable.

To begin, you'll need to install a few tools and create a Docker image for your server.

### Build the server

Open a terminal because you'll need to run several commands. On MacOS you can open `Terminal.app` and on Windows you can open `cmd.exe`.

To run the commands, you'll need to install [Pack](https://buildpacks.io/docs/tools/pack/) and [Docker](https://www.docker.com/products/docker-desktop). Click those links and follow the installation instructions (this is probably the hardest part of the tutorial, so don't get discouraged!). Then make sure everything is working by running the following commands:

_(warning: do not include the `>` character in your commands. That's only meant to show the [prompt](https://www.lifewire.com/command-prompt-2625840). On Windows this will look something like `C:\>`)_

```
> docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED

> pack --version
0.15.1
```

Next, create a directory to store your Minecraft server. In that directory, create a file called `plugins.txt` and put the following contents into it:

```
raspberryjuice
```

This will ensure that the [RaspberryJuice plugin](https://www.spigotmc.org/resources/raspberryjuice.22724/) gets installed. You'll need to this to use Python with your server.

Now use Pack to create a Minecraft server Docker image using the [Minecraft buildpack](https://github.com/jkutner/minecraft-buildpack). From the directory you just created, running these commands (warning: the `pack build` command take several minutes the first time you run it):

```
> pack trust-builder jkutner/minecraft-builder:18
> pack build --builder jkutner/minecraft-builder:18 minecraft
```

Check that your image is ready by running this command:

```
> docker image ls minecraft
REPOSITORY          TAG                 IMAGE ID            CREATED
minecraft           latest              bbc0352e09ea        41 years ago
```

_(don't worry, it's [not really 41 years ago](https://medium.com/buildpacks/time-travel-with-pack-e0efd8bf05db))_

Now you're ready to run the server.

### Run the server locally

You'll begin by running the server locally (on your personal computer), but later on you can deploy it to a cloud platform. Use the `docker run` command to start a container with the image you created in the previous section:

```
> docker run -it -p 4711:4711 -p 25566:25566 minecraft
```

The new container will expose two [ports](https://en.wikipedia.org/wiki/Port_%28computer_networking%29) (4711 and 25566), which you'll use to connect to the server.

Test it by openning your Minecraft app. Install version 1.12.2 and launch the game. Then select "Multiplayer" and "Direct Connection", and paste the address `localhost:25566 as the "Server Address" and click "Join Server".

Leave your player in the game, and return to your terminal session to start using Python.

### Use Python to connect

To use Python with your server, you'll need to have [Python installed](https://wiki.python.org/moin/BeginnersGuide/Download) on your machine. Once it's installed, you'll be able to start a Python shell by running

```
> python --version
Python 3.9.1
```

Install the mcpi package (note: on some computers you'll need to run `pip3` instead of `pip`):

```
> pip install mcpi
```

Now start a Python shell session by running the `python` command with no arguments:

```
> python
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

### Go build something awesome!

Now you can create Python files (i.e. files that end in `.py`) and run them like any other Python script. For example, you might take the commands you ran earlier and put them in a `teleport.py` script with the following contents:

```python
from mcpi.minecraft import Minecraft

mc = Minecraft.create()
mc.player.setTilePos(0,100,0)
```

Then you can run it with a command like `python teleport.py`. As long as your server is running, your scripts will be able to interact with it. If it's not running, you'll get an error that looks something like this:

```
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/local/lib/python3.9/site-packages/mcpi/minecraft.py", line 376, in create
    return Minecraft(Connection(address, port))
  File "/usr/local/lib/python3.9/site-packages/mcpi/connection.py", line 17, in __init__
    self.socket.connect((address, port))
ConnectionRefusedError: [Errno 61] Connection refused
```

If that happens, make sure your server is running by executing the same `docker run` command you ran earlier:

```
> docker run -it -p 4711:4711 -p 25566:25566 minecraft
```

Eventually, you'll want to customize your server by increasing your ops level or setting some `server.properties`. When that time comes, see the [documentation for the Minecraft buildpack](https://github.com/jkutner/minecraft-buildpack/blob/master/README.md).

### How it works

The `plugins.txt` file indicates that you want to use [Spigot](https://www.spigotmc.org/), which is a modified Minecraft server that provides additional features while remaining compatible with normal Minecraft game mechanics. A Spigot server can be extended by installing plugins. You've added the [RaspberryJuice plugin](https://www.spigotmc.org/resources/raspberryjuice.22724/), which is needed to use Python.

### Resources

A lot of this setup is derived from the instructions in the book [Learn to Program with Minecraft](https://nostarch.com/programwithminecraft) from [No Starch Press](https://nostarch.com/). I strongly recommend it if you're new to either Python or Minecraft.
