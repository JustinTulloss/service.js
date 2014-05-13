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
  var serviceInstances = {};
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
    unregister: function(name, service) {
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
    start: function(serviceNames) {
      if (typeof serviceNames === 'string') {
        serviceNames = [serviceNames];
      }
      var promises = [];
      for (var i = 0; i < serviceNames.length; i++) {
        (function() {
          // We copy the list so that modifications to the implementation list
          // don't get started if they're registered after start is called.
          // All this code would be cleaner with persistent data structures.
          var serviceName = serviceNames[i];
          var serviceList = serviceProtos[serviceName].slice(0);
          function attemptToStart(j) {
            var instance = Object.create(serviceList[j]);
            instance.onInitialize();
            var isUsable = instance.isUsable();
            return isUsable.then(function(usable) {
              if (usable) {
                var startPromise = instance.onStart() || Q(instance);
                // Guarantee that the final promise always resolves to the
                // started instance of the service.
                return startPromise.then(function() {
                  return instance;
                });
              } else {
                j++;
                if (j < serviceList.length) {
                  return attemptToStart(j);
                } else {
                  throw new Error("No usable implementations of " + serviceName);
                }
              }
            });
          }
          promises.push(attemptToStart(0));
        }).call(this);
      }
      return Q.all(promises);
    },
    stop: function(serviceNames) {
    },
    ready: function(serviceNames) {
    },
    // A base prototype for
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
        return Q.resolve(true);
      }
    }
  };
  this.Services = Services;
  return Services;
}).call(this, Q);
