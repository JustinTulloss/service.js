chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
Services = require '../service.node'

chai.use(chaiAsPromised)
expect = chai.expect

describe 'Services', ->
  describe 'registering', ->
    beforeEach ->
      @service = Object.create(Services.Service, {
        magic: ->
      })

  it 'Allows a service to be registered', ->
    expect(Services.register("TestService", @service)).to.equal(1)

  it 'Allows a service to be unregistered', ->
    Services.register('TestService', @service)
    debugger;
    expect(Services.unregister('TestService', @service)).to.equal(0)
