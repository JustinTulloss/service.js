# Some nonsense to make these tests run in both browser and node environments
if typeof require != 'undefined'
  chai = require 'chai'
  chaiAsPromised = require 'chai-as-promised'
  Services = require 'service'
else
  chai = window.chai
  chaiAsPromised = window.chaiAsPromised
  Services = window.Services

chai.use(chaiAsPromised)
expect = chai.expect

describe 'Services', ->
  describe 'registering', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service)
    afterEach ->
      Services.unregister('TestService')

    it 'Allows a service to be registered', ->
      expect(Services.register("TestService", service)).to.equal(1)

    it 'Allows a service to be unregistered', ->
      Services.register('TestService', service)
      Services.register('TestService', Object.create(Services.Service))
      expect(Services.unregister('TestService', service)).to.equal(1)

    it 'Allows all of a particular service to be unregistered', ->
      Services.register('TestService', service)
      Services.register('TestService', Object.create(Services.Service))
      expect(Services.unregister('TestService')).to.equal(0)

  describe 'starting', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service)
      Services.register('TestService', service)
    afterEach ->
      Services.stop('TestService').then -> Services.unregister('TestService')

    it 'returns a promise that resolves if nothing happens in onStart', ->
      expect(Services.start('TestService')).to.eventually.eql([service])

    it 'returns a promise that resolves when a promise returned from onStart is resolved', ->
      defer = Q.defer()
      service.onStart = -> defer.promise
      setTimeout(
        -> defer.resolve()
      , 2)
      expect(Services.start('TestService')).to.eventually.eql([service])

    it 'does not allow you to double start a service', ->
      Services.start('TestService').then ->
        expect(-> Services.start('TestService')).to.throw(Error)

    describe 'isUsable', ->
      service2 = null
      beforeEach ->
        service2 = Object.create(Services.Service)
        Services.register('TestService', service2)

      it 'uses the second implementation if the first is not usable', ->
        service.isUsable = -> false
        expect(Services.start('TestService')).to.eventually.eql([service2])

      it 'uses the second implementation if the first is not usable async', ->
        deferred = Q.defer()
        service.isUsable = -> deferred.promise
        setTimeout(
          -> deferred.resolve(false)
        , 2)
        expect(Services.start('TestService')).to.eventually.eql([service2])

      it 'rejects the start if no implementations are usable', ->
        deferred = Q.defer()
        service.isUsable = -> false
        service2.isUsable = -> deferred.promise
        setTimeout(
          -> deferred.resolve(false)
        , 2)
        expect(Services.start('TestService')).to.eventually.be.rejected

      it 'wont behave as if things succeeded if there was an exception', ->
        service.isUsable = -> throw new Error("Something bad happened")
        expect(-> Services.start('TestService')).to.throw(Error, "Something bad happened")

  describe 'stopping', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service)
      @onStopCalled = false
      service.onStop = => @onStopCalled = true
      Services.register('TestService', service)
    afterEach -> Services.stop().then -> Services.unregister('TestService')

    it 'allows all services to be stopped', (done) ->
      Services.start('TestService')
      Services.stop().done =>
        expect(@onStopCalled).to.be.true
        done()

    it 'allows a single type of service to be stopped', ->
      service2 = Object.create(Services.Service)
      secondStopCalled = false
      service2.onStop = -> secondStopCalled = true
      Services.register('TestService2', service2)
      Services.start('TestService')
      Services.stop('TestService').done =>
        expect(@onStopCalled).to.be.true
        expect(secondStopCalled).to.be.false
        Services.stop().then ->
          Services.unregister('TestService2')

  describe 'ready', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service)
      Services.register('TestService', service)
      Services.start('TestService')

    afterEach ->
      Services.stop().then -> Services.unregister('TestService')

    it 'resolves when a service is ready', ->
      Services.ready('TestService').spread (instance) ->
        expect(service.isPrototypeOf(instance)).to.be.true

    it 'resolves when multiple services are ready', ->
      deferred = Q.defer()
      service2 = Object.create(Services.Service)
      service2.onStart = -> deferred.promise
      Services.register('TestService2', service2)
      Services.start('TestService2')
      setTimeout(->
        deferred.resolve()
      , 1)
      Services.ready('TestService', 'TestService2').spread (instance, instance2) ->
        expect(service.isPrototypeOf(instance)).to.be.true
        expect(service2.isPrototypeOf(instance2)).to.be.true
        Services.stop('TestService2').then -> Services.unregister('TestService2')

    it 'throws if ready is called before start', ->
      expect(-> Services.ready('Bogus')).to.throw(Error)

    it 'throws if ready is called on a service that failed to start', ->
      service.onStart = -> throw new Error("Could not start")
      expect(-> Services.ready('Bogus')).to.throw(Error)

  describe 'status', ->
    it 'returns an object with `running` and `registered` properties`', ->
      expect(Services.status()).to.have.keys(['running', 'registered'])
    it 'returns the correct services for running and registered', ->
      service = Object.create(Services.Service)
      service2 = Object.create(Services.Service)
      Services.register('TestService', service)
      Services.register('TestService2', service2)
      Services.start('TestService').then ->
        expect(Services.status()).to.eql({
          registered: {
            TestService: 1
            TestService2: 1
          }
          running: {
            TestService: {
              state: 'fulfilled'
              value: service
            }
          }
        })
