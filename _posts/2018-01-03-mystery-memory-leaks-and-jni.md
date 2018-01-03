---
layout: post
title:  "Mystery Memory Leaks and JNI"
date:   2018-01-03 09:12:42
---


Java libraries that invoke native code (i.e. code written in C/C++ and compiled for a specific platform) via the Java Native Interface (JNI) can allocate memory that is nearly invisible to standard JVM monitoring tools. This creates the potential for very mysterious memory leaks because JNI does not automatically garbage collect or track the non-JVM memory resources allocated on the native side.

In this post, I'll demonstrate a native memory leak using use a popular computer vision library called [OpenCV](https://opencv.org/), which is written in C++ and compiled into native binaries we can call from its built-in Java API. After demonstrating the leak, you'll learn why it happened and how to fix it.

## Example

The [example application](https://github.com/jkutner/opencv-java-leak) uses OpenCV to convert a colored image to greyscale. The program intentionally leaks memory, which means it will crash after running for a few minutes. To try it locally, clone the Git repo:

```sh-session
$ git clone https://github.com/jkutner/opencv-java-leak
$ cd opencv-java-leak
```

Then build the Docker image, which will compile OpenCV for Linux, by running:

```sh-session
$ docker-compose build
```

Finally, run the program in a Docker container with this command:

```sh-session
$ docker-compose run opencv
```

As the app runs, it will periodically log it's memory profile, which looks like this:

```
measure.mem.jvm.heap.used=2M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
measure.mem.jvm.nonheap.used=7M measure.mem.jvm.nonheap.committed=8M measure.mem.jvm.nonheap.max=0M
...
measure.mem.linux.vsz=2947M measure.mem.linux.rss=158M
measure.mem.jvm.heap.used=4M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
...
measure.mem.linux.vsz=3139M measure.mem.linux.rss=365M
measure.mem.jvm.heap.used=4M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
measure.mem.jvm.nonheap.used=9M measure.mem.jvm.nonheap.committed=10M measure.mem.jvm.nonheap.max=0M
...
measure.mem.linux.vsz=3395M measure.mem.linux.rss=595M
```

You'll see the JVM heap and non-heap stay very small. But the total process memory (`measure.mem.linux.rss`) will grow with each iteration.

If this app were running in production, you'd have quite the problem on your hands. Your container would crash once the memory consumed by the `java` process exceeded its limits. But most of the inspection tools you might ordinarily use (VisualVM, JConsole, and even Native Memory Tracking) will not report the memory memory allocated by the OpenCV code.

OpenCV uses JNI to invoke native code written in C++ (this is the code you compiled when you ran `docker-compose build`). The native code allocates memory with `malloc` (or a similar function), which askes the operating system to reserve a chunk of memory without the JVM knowing about it. Yet this chunk of memory will still be associated with the `java` process making the JNI call, which makes it quite elusive.

The root cause of the problem, however, is in the Java code that uses the OpenCV API for Java. Open the `Main.java` file in the project, and you'll see the following:

```java
String location = "resources/Poli.jpg";
Mat image = Imgcodecs.imread(location);
Imgproc.cvtColor(image, image, Imgproc.COLOR_BGR2GRAY);
Imgcodecs.imwrite("resources/Poli-gray.jpg", image);

// Uncomment this line to fix the leak
//image.release();
```

The program reads a JPEG file into memory (via JNI internally), converts it to greyscale, and writes the new image to disk. The `Mat` object holds a reference to the in-memory image, and when the JVM garbage collects the `Mat` object it will free the memory that was allocated natively. But the `Mat` object is very small and does consume much space on the heap, which means it will not be garbaged collected very quickly. Instead, the program needs to manually release that chunk of native memory in order to stay within the system limits.

Uncomment the `image.release()` line and rebuild the Docker image. Then run the program again:

```
$ docker-compose build
$ docker-compose run opencv
```

This time, the memory profile will remain flat, even as it continuously reads the JPEG files into memory.

```
measure.mem.jvm.heap.used=2M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
measure.mem.jvm.nonheap.used=7M measure.mem.jvm.nonheap.committed=8M measure.mem.jvm.nonheap.max=0M
...
measure.mem.linux.vsz=2883M measure.mem.linux.rss=63M
measure.mem.jvm.heap.used=4M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
measure.mem.jvm.nonheap.used=9M measure.mem.jvm.nonheap.committed=10M measure.mem.jvm.nonheap.max=0M
...
measure.mem.linux.vsz=2883M measure.mem.linux.rss=65M
measure.mem.jvm.heap.used=4M measure.mem.jvm.heap.committed=31M measure.mem.jvm.heap.max=58M
measure.mem.jvm.nonheap.used=9M measure.mem.jvm.nonheap.committed=10M measure.mem.jvm.nonheap.max=0M
...
measure.mem.linux.vsz=2883M measure.mem.linux.rss=65M
```

The memory profile of the process is greatly improved because the image file is only held in-memory very briefly and then released.

## Other places to look

OpenCV is only one of the commonly used Java libraries that makes JNI calls to allocate memory. Some other libraries you need to keep an eye on include:

* FFmpeg APIs: [Xuggler](http://www.xuggle.com/xuggler/), [JavaCPP FFmpeg](https://github.com/bytedeco/javacpp-presets/tree/master/ffmpeg), [FMJ](http://fmj-sf.net/index.php) (note that CLI wrappers do not use JNI).
* TensorFlow APIs: [TensorFlow for Java](https://www.tensorflow.org/api_docs/java/reference/org/tensorflow/package-summary)[JavaCPP TensorFlow](https://github.com/bytedeco/javacpp-presets/tree/master/tensorflow)
* Anything that uses [JNA](https://github.com/java-native-access/jna): [Apache Cassandra](http://cassandra.apache.org/), [JVM OpenVR Binding](https://github.com/kotlin-graphics/openvr)

In most cases, you'll be aware that you're using a library that calls out to native code (it's difficult and uncommon for these to kinds of dependencies to sneak into your app).

JNI creates yet another [category of Java memory like the ones described in my earlier post](http://jkutner.github.io/2017/04/28/oh-the-places-your-java-memory-goes.html). When your app starts having memory problems, make sure you consider this category in addition to the others.
