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

```javascript
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

// This is usually called once after all services are registered and your app
// is ready to start. In `window.onload` for instance.
Services.start();

// Anywhere in your app where you need to use a service, you can get access
Services.ready('Pubsub').spread(function(pubsub) {
  // `pubsub` is an instance of the Pubsub service implementation
  pubsub.publish('up and running!');
});
```

There is complete [API documentation][api] available.

Using the library
-----------------

### In a browser

Just include `build/service.min.js` in a script tag. Then `Services` will be
globally available.

#### If you use AMD

- Copy build/service.amd.js to the appropriate place in your application, rename
it service.js.
- Then you can just `require(['service'] function(Services) {}` to your heart's
content.

### In Node.js
`npm install service-js`

Then in your app all you need to do is require it:

`var Services = require('service-js');`

Development
-----------

### Running tests
`make test`

### Building a release
`make release`

Files will end up in the `build` directory.

<a href="https://github.com/JustinTulloss/service.js"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/38ef81f8aca64bb9a64448d0d70f1308ef5341ab/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f6461726b626c75655f3132313632312e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png"></a>

[status-img]: https://api.travis-ci.org/JustinTulloss/service.js.svg
[status-page]: https://travis-ci.org/JustinTulloss/service.js
[api]: http://justintulloss.github.io/service.js/
