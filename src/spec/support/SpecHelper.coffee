jade        = require 'jade'
fs          = require 'fs'
path        = require 'path'
jsdom       = require("jsdom").jsdom
jasmineExt  = require './JasmineExtensions'

exports.viewPath = (name) -> path.join(__dirname, '..', '..', 'views', "#{name}.jade")

exports.viewContent = (viewName, cb) ->
  viewPath = exports.viewPath viewName
  fs.readFile viewPath, 'utf8', (err, jadeContent) ->
    cb(err, jadeContent)

exports.compileJade = (viewName, cb) ->
  viewPath = exports.viewPath viewName
  jadeContent = exports.viewContent viewName, (err, jadeContent) ->
    cb(err) if err
    try
      jadeResult = jade.compile(jadeContent, {pretty: true, filename: viewPath})
    catch err
      cb(err)
    cb(null, jadeResult)

exports.getHtmlFromView = (viewName, data, cb) ->
  exports.compileJade viewName, (err, jadeResult) ->
    cb(err) if err
    try
      html = jadeResult(data)
    catch err
      cb(err)
    cb(null, html)

exports.getWindowFor = (html, cb) ->
  fs.readFile path.join(__dirname, "../../public/javascripts/lib/jquery.min.js".split('/')...), (err, jqueryFile) ->
    fs.readFile path.join(__dirname, "../../public/javascripts/lib/jasmine-jquery.js".split('/')...), (err, jasmineJqueryFile) ->
      cb(err, null) if err
      jsdom.env html: html, src: [jqueryFile, jasmineJqueryFile], done: (err, window) ->
        cb(err) if err
        cb(null, window, window.$)

exports.getWindowFromView = (viewName, data, cb) ->
  exports.getHtmlFromView viewName, data, (err, html) ->
    cb(err) if err
    exports.getWindowFor html, (err, window, $) ->
      cb(err) if err
      cb(null, window, window.$)

exports.patchEventEmitterToHideMaxListenerWarning = ->
  return if exports.eventEmitterPatched
  exports.eventEmitterPatched = true
  events = require('events')
  Old = events.EventEmitter
  events.EventEmitter = ->
    this.setMaxListeners(0)
  events.EventEmitter:: = Old::

exports.localMongoDB = "mongodb://localhost/openstore"

exports.startServer = (cb) ->
  process.env.CUSTOMCONNSTR_mongo = exports.localMongoDB
  exports.cleanDB (err) ->
    cb err if err
    app = require('../../app')
    app.start (server) ->
      exports._server = server
      cb null, server if cb

exports.whenDone = (condition, callback) ->
  if condition()
    process.nextTick callback
  else
    process.nextTick -> whenDone(condition, callback)

exports.whenServerLoaded = (cb) ->
  if exports._server
    process.nextTick cb
    return
  exports.whenDone((-> exports._server isnt null), -> cb())

exports.cleanDB = (cb) ->
  mongoose = require 'mongoose'
  mongoose.connect process.env.CUSTOMCONNSTR_mongo
  mongoose.connection.on 'error', (err) ->
    console.error "connection error:#{err.stack}"
    cb err
  mongoose.connection.db.collections (err, cols) ->
    for col in cols
      unless col.collectionName.substring(0,6) is 'system'
        console.log "dropping #{col.collectionName}"
        col.drop()
    mongoose.connection.close()
    cb()



jasmineExt.beforeAll (done) ->
  process.addListener 'uncaughtException', (error) -> console.log "Error happened:\n#{error.stack}"
  exports.patchEventEmitterToHideMaxListenerWarning()
  exports.startServer (err, server) ->
    done err if err
    done()

jasmineExt.afterAll ->
  if exports._server
    exports._server.close()
  else
    console.log "Server not defined on 'afterAll'"
