chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
Services = require 'service'

chai.use(chaiAsPromised)
expect = chai.expect

describe 'Services', ->
  describe 'registering', ->
    service = null
    beforeEach ->
      service = Object.create(Services.Service, {
        magic: ->
      })
    afterEach ->
      Services.unregister('TestService')

    it 'Allows a service to be registered', ->
      expect(Services.register("TestService", service)).to.equal(1)

    it 'Allows a service to be unregistered', ->
      Services.register('TestService', service)
      expect(Services.unregister('TestService', service)).to.equal(0)
