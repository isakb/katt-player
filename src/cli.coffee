# Copyright 2013 Klarna AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

fs = require 'fs'
argparse = require 'argparse'
_ = require 'lodash'
kattPlayer = require './katt-player'
pkg = require '../package'

# For argument validation / transformation.
CUSTOM_TYPES =
  engine: (value) ->
    if kattPlayer.hasEngine(value)
      kattPlayer.getEngine value
    else if fs.existsSync(value)
      require value
    else
      throw new Error "Invalid engine: #{value}."

  json: (value) ->
    try
      JSON.parse(value)
    catch e
      throw new Error "Invalid JSON string: #{value}. #{e}."


parseArgs = (args) ->
  engines = kattPlayer.getEngineNames().join(', ')

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

  parser.addArgument ['--hostname'],
    help: 'Server hostname / IP address. (%(defaultValue)d)'
    defaultValue: '0.0.0.0'
    type: 'string'

  parser.addArgument ['scenarios'],
    help: 'Scenarios as files/folders'
    nargs: '+'

  parser.addArgument ['--engine-options'],
    help: 'Options for the engine. (%(defaultValue)s)'
    defaultValue: '{}'
    metavar: 'JSON_STRING'
    type: CUSTOM_TYPES.json
    dest: 'engineOptions'

  parser.parseArgs(args)


main = exports.main = (args = process.args) ->
  args = parseArgs(args)
  {hostname, port} = args
  args.engineOptions.vars ?= {}
  _.merge args.engineOptions, {vars: {hostname, port}}
  engine = new args.engine(args.scenarios, args.engineOptions)
  kattPlayer.makeServer(engine).listen port, hostname, ->
    console.log "Server started on http://#{hostname}:#{port}"


main()  if require.main is module
