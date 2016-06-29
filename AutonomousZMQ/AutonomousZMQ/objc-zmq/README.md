# objc-zmq

`objc-zmq` is an Objective-C binding to [ZeroMQ](http://zeromq.org/)

This is an Objective-C version of the reference ZeroMQ [object-oriented C API][zmq-docs]. It follows the guidelines laid out by the official ["Guidelines for ZeroMQ bindings"][binding-zmq].

[zmq-docs]: http://api.zeromq.org/zmq.html (zmq(7) Manual Page)
[binding-zmq]: http://www.zeromq.org/docs:bindings (Guidelines for ZeroMQ Bindings)


## Usage

To run the example project; clone the repo, and run `pod install` from the Project directory first.

## Requirements

- OSX 10.9 (Mavericks)
- Xcode 5.0.2

## Installation

objc-zmq is not yet available through [CocoaPods](http://cocoapods.org). 

To install it simply add the following line to your Podfile:

	pod "objc-zmq", :git => 'https://github.com/jeremy-w/objc-zmq.git'

## License

objc-zmq is available under the MIT license. See the LICENSE file for more info.

## Documentation

Refer to the [ZeroMQ manual pages][zmq-docs].

The Objective-C binding maintains a bit more state than the C API exposes, in that you can query a `ZMQContext` for its sockets and query a `ZMQSocket` for its context.

## Thread Safety

Early versions of ZeroMQ had some restrictive thread safety and coupling issues:

* Sockets can only be used from the thread that created them.
* All ZMQ sockets provided in a single call to `zmq_poll()` must have been created using the same context.

Because sockets are coupled to contexts for polling, you have to track each socket's context and make sure not to mix them. (The `ZMQSocket` class tracks this for you.) This is not as restrictive as it sounds, because most applications will only ever use a single context.

Prior to version 2.1.0, each socket was permanently bound to the thread that created it. This made it very difficult to use ZeroMQ sockets with Grand Central Dispatch or `NSOperationQueue`, because the only persistent thread that these two APIs expose is the thread you're least likely to want to perform socket operations on: the main thread.

Starting with version 2.1.0, a socket can be used from different threads provided a full memory barrier, such as that introduced by `<libkern/OSAtomic.h>`'s `OSMemoryBarrier` function, separates the socket's use on one thread from its use on another.

## To Do

* Add functional tests in the form of sample code.
* Tie polling into the runloop, similar to `NSStream`, `CFSocket`, or `CFFileDescriptor`.
