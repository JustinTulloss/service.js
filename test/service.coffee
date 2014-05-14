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
      Services.stop('TestService')
      Services.unregister('TestService')

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
      Services.start('TestService')
      expect(-> Services.start('TestService')).not.to.Throw

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

  describe 'stopping', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service)
      Services.register('TestService', service)
    afterEach -> Services.unregister('TestService')

    it 'allows all services to be stopped', (done) ->
      service.onStop = done
      Services.start('TestService')
      Services.stop()

    it 'allows a single type of service to be stopped'
