Service.js
----------
[![Build Status][status-img]][status-page]

Service.js is a library for managing abstractions over how your program
interacts with the outside world.

A "service" is an interface to some global funcationality.
Examples would be error reporting, data persistence,
API abstraction, performance monitoring, audio playback abstraction, even
DOM manipulation abstraction.

An "implementation" of a service is an object that implements the service's
interface and registers itself with the services library. There may be multiple
implementations of a service, the priority is determined by the order of
registration.

An "instance" of a service is a particular implementation that's been
instantiated, intialized, and (usually) started. Instances are what the
application code actually uses and can be accessed by calling `Services.ready`.

An example should help clear this up.

### Example Usage
In this example, we have two implementations of the "Socket" service, which the
pubsub service uses to actually accomplish sending and receiving messages.
The `SocketService` service uses websockets and registers itself first, thereby
having a higher priority. However, if the client doesn't have WebSockets, the
`PollingService` implementation of 'Socket' will be started instead.

```js
// Web socket implmentation of 'Socket'
var WebSocketService = Object.create(Services.Service);
WebSocketService.isUsable = function() {
  return 'WebSocket' in window;
};
Services.register('Socket', WebSocketService);

// Polling implementation of 'Socket'
var PollingSocketService = Object.create(Services.Service);
Services.register('Socket', PollingSocketService);

// Implementation of pubsub (there's only 1 in the example)
var Pubsub = Object.create(Services.Service);
Pubsub.onStart = function() {
  return Services.ready('Socket');
}
Pubsub.publish = function() { /* publish stuff */ }
Pubsub.subscribe = function() { /* subscribe to stuff */ }
Services.register('Pubsub', Pubsub);

// Later, in application code
Services.start();
Services.ready('Pubsub').spread(function(pubsub) {
  // `pubsub` is an instance of the Pubsub service implementation
  pubsub.publish('up and running!');
});
```

[status-img]: https://api.travis-ci.org/JustinTulloss/service.js.svg
[status-page]: https://travis-ci.org/JustinTulloss/service.js
