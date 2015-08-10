---
layout: post
title:  "A New JRuby Launcher"
date:   2015-08-10 16:43:00
---

At JRubyConf, [Tom](https://twitter.com/tom_enebo) and [Charlie](https://twitter.com/headius) (of JRuby fame) goaded me into rewriting the jruby-launcher (effectively the `jruby` command). I have made a lot of progress, and now I need some help testing it. Please take 5 mins and do the following:

1. Download the `mjruby` [binary for your platform](https://github.com/jkutner/mjruby/releases/tag/v0.1).
2. Put it in your `$JRUBY_HOME/bin` directory (next to your `jruby` command)
3. Set `JAVA_HOME`
4. Use `mjruby` instead of `jruby` to launch the most complicated thing you can think of.
5. Tell me what broke.

There is catch though: Windows thinks my binary is a virus. The command works for a moment, but then crashes with an error StackHash_0a9e that appears to be related to data execution prevention (DEP). But I'm running Windows in a VM, so please test this anyways as YMMV.

I desperately need help with the Windows part. I've exhausted my ability to debug the problem.

## Why a new `jruby` command?

The existing `jruby` command — depending on your platform — is either a [Bash script](https://github.com/jruby/jruby/blob/master/bin/jruby.bash) or an EXE compiled from a horrific pile of C++ code that is [jruby-launcher](https://github.com/jruby/jruby-launcher/). Both of these implementations make maintenance difficult. The Bash script also makes it impossible to inspect the JVM before running it (because launching two JVM processes when running `jruby` would be super slow).

## What makes `mjruby` different?

My launcher is built with [mruby](https://github.com/mruby/mruby) and [mruby-cli](https://github.com/hone/mruby-cli). mruby is a subset of Ruby that can be compiled into bytecode and run natively on various platforms. It was created by Matz and it's used by Seimens, Hashicorp, Heroku and IIJ to make light-weight binary executables that don't suck.

Here's what that means: my `mjruby` command is written mostly in Ruby instead of in C++ and/or Bash. It's easier to maintain, and it's portable across Mac, Linux and Windows (theoretically). It also has unit tests!

## Ship it?

Not yet. I need to fix the Windows thing. I also need to add FreeBSD support and test it on a variety of platforms. But aside from those biggies, I have some [open issues](https://github.com/jkutner/mjruby/issues).

Please please please give this a try. And file an issue if you run into something that doesn't work (you probably will).
