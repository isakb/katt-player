###
   Copyright 2013 Klarna AB

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
###

BasicEngine = require './basic'

# A naïve "RESTful" engine without any magic apart from silly routing with a
# random response in case of many possible responses for the same route.
module.exports = class SillyRestEngine extends BasicEngine

  constructor: ({scenarios, options}) ->
    return new SillyRestEngine({scenarios, options}) \
      unless this instanceof SillyRestEngine

    super
    @requestToResponses = {}
    @eachBlueprint (blueprint, filename) =>
      for t in blueprint.transactions
        (@requestToResponses[@hashify(t.request)] or= []).push t.response

    console.log 'Silly "RESTful" routing table'
    console.log @requestToResponses


  hashify: (req) ->
    [req.method, req.url].join(':')


  middleware: (req, res, next) ->
    possibleResponses = @requestToResponses[@hashify(req)]
    return @sendError res, 500, 'No possible response'  unless possibleResponses

    index = Math.floor(Math.random() * possibleResponses.length)
    response = possibleResponses[index]
    {headers, body, status} = response

    res.body = body
    res.statusCode = status
    res.setHeader header, headerValue  for header, headerValue of headers
    @sendResponse req, res, next
    true
