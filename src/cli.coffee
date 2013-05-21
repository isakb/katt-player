#jshint node:true

fs = require 'fs'
argparse = require 'argparse'
express = require 'express'
KattPlayer = require './katt-player'
pkg = require '../package'

# For argument validation / transformation.
CUSTOM_TYPES =
  engine: (value) ->
    if KattPlayer.hasEngine(value)
      KattPlayer.getEngine value
    else if fs.existsSync(value)
      require value
    else
      throw new Error "Invalid engine: #{value}."

  json: (value) ->
    try
      JSON.parse(value)
    catch e
      throw new Error "Invalid JSON string: #{value}. #{e}."


parseArgs = ->
  engines = KattPlayer.getEngineNames().join(', ')

  parser = new argparse.ArgumentParser
    description: pkg.description
    version: pkg.version
    addHelp: true

  parser.addArgument ['-e', '--engine'],
    help: "Engine as built-in [#{engines}] or file path. (%(defaultValue)s)"
    defaultValue: 'linear'
    type: CUSTOM_TYPES.engine

  parser.addArgument ['-p', '--port'],
    help: 'Port number. (%(defaultValue)d)'
    defaultValue: 1337
    type: 'int'

  parser.addArgument ['scenarios'],
    help: 'Scenarios as files/folders'
    nargs: '+'

  parser.addArgument ['--engine-options'],
    help: 'Options for the engine. (%(defaultValue)s)'
    defaultValue: '{}'
    metavar: 'JSON_STRING'
    type: CUSTOM_TYPES.json
    dest: 'engineOptions'

  parser.parseArgs()


exports.main = (args = process.args) ->
  args = parseArgs(args)
  app = express()
  engine = new args.engine(app, args.engineOptions)
  new KattPlayer(app, engine,
    scenarios: args.scenarios
  )
  console.log 'Server start on http://127.0.0.1:' + args.port
  app.listen args.port
