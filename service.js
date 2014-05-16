(function(Q) {
  'use strict';

  // Check for dependencies
  if (!Object.create) {
    throw new Error("An Object.create polyfill is required to use Services");
  }
  if (typeof Q === 'undefined') {
    throw new Error("The Q promises library is required to use Services");
  }

  // A map of service names to implementations
  var serviceProtos = {};
  // This is actually not instances, but a map of names to promises
  // that produce instances.
  var servicePromises = {};
  var doNothing = function() {};

  // Services
  // --------
  // `Services` is the namespace for the services library. It contains
  // functions for registering service implementations and starting/stopping
  // services.
  var Services = {
    // Registers a service implementation. Takes the name of the service and
    // the implementation. The implementation should extend `Services.Service`.
    // Returns the priority of this implementation (aka the number of
    // implementations available).
    //
    // ### Example
    // ```js
    // var DefaultImplementation = Object.create(Services.Service);
    // Services.register('MyService', DefaultImplementation);
    // ```
    register: function(name, service) {
      if (serviceProtos[name]) {
        serviceProtos[name].push(service);
      } else {
        serviceProtos[name] = [service];
      }
      return serviceProtos[name].length;
    },
    // Unregisters a particular service. Can also unregister all of a particular
    // service's implementations if not passed a particular service.
    //
    // Returns the number of remaining implementations.
    // ### Example
    // ```js
    // // Unregisters one implementation of the service called `service`
    // Services.unregister('MyService', service);
    //
    // // Unregisters all services implementing MyService
    // Services.unregister('MyService');
    // ```
    unregister: function(name, service) {
      if (servicePromises[name]) {
        throw new Error("Cannot unregister a service that is starting or started");
      }
      var serviceList = serviceProtos[name];
      if (service) {
        for (var i = 0; i < serviceList.length; i++) {
          if (serviceList[i] === service) {
            serviceList.splice(i, 1);
          }
        }
        return serviceList.length;
      } else {
        delete serviceProtos[name];
        return 0;
      }
    },
    // Starts all the services or a subset of services. Returns a promise that
    // is resolved when the services have started. If a service fails to start,
    // the 
    start: function() {
      var serviceNames = arguments.length ? arguments : Object.keys(serviceProtos);
      var promises = [];
      for (var i = 0; i < serviceNames.length; i++) {
        (function() {
          // We copy the list so that modifications to the implementation list
          // don't get started if they're registered after start is called.
          // All this code would be cleaner with persistent data structures.
          var serviceName = serviceNames[i];
          var serviceList = serviceProtos[serviceName].slice(0);
          if (servicePromises[serviceName]) {
            throw new Error("Cannot start a service that's already started: " + serviceName);
          }
          function attemptToStart(j) {
            var instance = Object.create(serviceList[j]);
            instance.onInitialize();
            var isUsable = Q(instance.isUsable());
            var startPromise = isUsable.then(function(usable) {
              if (usable) {
                var startPromise = instance.onStart() || Q(instance);
                // Guarantee that the final promise always resolves to the
                // started instance of the service.
                startPromise = startPromise.then(function() {
                  return instance;
                }, function(reason) {
                  // If we did not successfully start, delete the start promise
                  delete servicePromises[serviceName];
                  throw reason;
                });
                servicePromises[serviceName] = startPromise;
                return startPromise;
              } else {
                j++;
                if (j < serviceList.length) {
                  return attemptToStart(j);
                } else {
                  delete servicePromises[serviceName];
                  throw new Error("No usable implementations of " + serviceName);
                }
              }
            });
            servicePromises[serviceName] = startPromise;
            return startPromise;
          }
          promises.push(attemptToStart(0));
        }).call(this);
      }
      return Q.allSettled(promises);
    },
    stop: function() {
      var name;
      var serviceNames = arguments.length ? arguments : Object.keys(servicePromises);
      var promises = [];
      for (var i = 0; i < serviceNames.length; i++) {
        (function(name) {
          if (!servicePromises[name]) { return; }
          promises.push(servicePromises[name].done(function(instance) {
            instance.onStop();
            delete servicePromises[name];
          }));
        }).call(this, serviceNames[i]);
      }
      return Q.all(promises);
    },
    ready: function() {
      var promises = [];
      for (var i = 0; i < arguments.length; i++) {
        var name = arguments[i];
        if (!servicePromises[name]) {
          throw new Error(name + " was not started or failed to start");
        }
        promises.push(servicePromises[name]);
      }
      return Q.all(promises);
    },
    // A function that allows you to inspect the current state of the various
    // running services. It returns an object with two properties: `registered`
    // and `running`.
    //
    // This is useful information to contain in error reporting.
    //
    // `registered` is an object with the registered service
    // names as its properties and the number of implementations registered as
    // the values.
    //
    // `running` returns an object with the started or starting service names
    // as its properties and a state snapshot as its value. The state snapshot
    // contains a `state` property indicating whether the service has started
    // yet or not and, if it has, the implementation that's running.
    //
    // ### Example
    // ```js
    // {
    //    registered: {
    //      MyService: 1,
    //      AnotherService: 2,
    //      UnusedService: 1
    //    },
    //    running: {
    //      MyService: { state: "pending" },
    //      AnotherService: {
    //        state: "running",
    //        value: <the instance of the running service>
    //      }
    //    }
    // }
    // ```
    status: function() {
      var i, name;
      var registeredNames = Object.keys(serviceProtos);
      var registered = {};
      for (i = 0; i < registeredNames.length; i++) {
        name = registeredNames[i];
        registered[name] = serviceProtos[name].length;
      }
      var running = {};
      var runningNames = Object.keys(servicePromises);
      for (i = 0; i < runningNames.length; i++) {
        name = runningNames[i];
        running[name] = servicePromises[name].inspect();
      }
      return {
        registered: registered,
        running: running
      };
    },
    // Service
    // -------
    // A base prototype for a service. All other services should extend this one
    // or implement every method that it implements.
    //
    // ### Example
    // ```js
    // var MyService = Object.create(Services.Service);
    // // This uses underscore.js, which is not required.
    // _.extend(MyService, {
    //   onStart: function() {
    //     // Do everything needed to start running.
    //   },
    //   myMethod: function() {
    //     //...
    //   }
    // });
    // ```
    Service: {
      // Called when object is first created. Must be synchronous.
      onInitialize: doNothing,

      // Called when service is being started. Can return a promise if startup
      // involves an asynchronous action.
      onStart: doNothing,

      // Called when the service is being stopped.
      onStop: doNothing,

      // Called to determine whether this implementation can be used in the
      // current environment. Can return a promise if figuring out the answer
      // is asynchronous.
      isUsable: function() {
        return true;
      }
    }
  };
  this.Services = Services;
  return Services;
}).call(this, Q);
