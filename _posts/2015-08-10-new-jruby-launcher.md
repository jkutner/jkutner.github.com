---
layout: post
title:  "A New JRuby Launcher"
date:   2015-08-10 16:43:00
---

**Updated:** September 11, 2015. Please try this again with the new release!

At JRubyConf, [Tom](https://twitter.com/tom_enebo) and [Charlie](https://twitter.com/headius) (of JRuby fame) goaded me into rewriting the jruby-launcher (effectively the `jruby` command). I have made a lot of progress, and now I need some help testing it. Please take 5 mins and do the following:

1. Download the `mjruby` [binary for your platform](https://github.com/jkutner/mjruby/releases/tag/v0.3).
2. Put it in your `$JRUBY_HOME/bin` directory (next to your `jruby` command)
3. Rename the existing `jruby` or `jruby.exe` to `jruby.old`
4. Rename `mjruby` to `jruby` (using `.exe` if on Windows of course)
4. Run the most complicated JRuby thing you can think of.
5. Tell me what broke.

## Why a new `jruby` command?

The existing `jruby` command — depending on your platform — is either a [Bash script](https://github.com/jruby/jruby/blob/master/bin/jruby.bash) or an EXE compiled from a horrific pile of C++ code that is [jruby-launcher](https://github.com/jruby/jruby-launcher/). Both of these implementations make maintenance difficult. The Bash script also makes it impossible to inspect the JVM before running it (because launching two JVM processes when running `jruby` would be super slow).

## What makes `mjruby` different?

My launcher is built with [mruby](https://github.com/mruby/mruby) and [mruby-cli](https://github.com/hone/mruby-cli). mruby is a subset of Ruby that can be compiled into bytecode and run natively on various platforms. It was created by Matz and it's used by Seimens, Hashicorp, Heroku and IIJ to make light-weight binary executables that don't suck.

Here's what that means: my `mjruby` command is written mostly in Ruby instead of in C++ and/or Bash. It's easier to maintain, and it's portable across Mac, Linux and Windows. It also has unit tests!

## Ship it?

Not yet. I also need to add FreeBSD support and test it on a variety of platforms. But aside from that, I only have a few small [open issues](https://github.com/jkutner/mjruby/issues).

Please please please give this a try. And file an issue if you run into something that doesn't work (you probably will).
