parseCson = require 'cson-parser'
shared = require './shared'

module.exports =

  read_cson: (input) ->
    # Validate CSON
    try
      data = parseCson.parse(input)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return false

    # Conversion
    output =
      scope: null
      completions: []

    for k,v of data
      # Get scope, convert if necessary
      for scopeSubl, scopeAtom of shared.exceptions
        if k is scopeAtom
          output.scope = scopeSubl
        else if k[0] is "."
          output.scope = k.substring(1)
        else
          output.scope = k

      for i, j of v
        if j.prefix?

          completions = {}

          # Create tab-separated description
          unless i is j.prefix
            completions.trigger = "#{j.prefix}"
            completions.description = i
          else
            completions.trigger = j.prefix

          completions.contents = shared.removeTrailingTabstops(j.body)
          output.completions.push completions

    # Minimum requirements
    if output.completions.length is 0
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Atom snippet file. Aborting.", dismissable: false)
      return false

    return output

  write_cson: (input) ->
    snippet = {}

    for scopeSubl, scopeAtom of shared.exceptions
      if input.scope is scopeSubl
        scope = scopeAtom
        break
      else
        if input.scope[0] isnt "."
          scope = ".#{input.scope}"
        else
          scope = input.scope

    for i in input.completions

      if i.description
        description = i.description
      else
        description = i.trigger

      body = shared.addTrailingTabstops(i.contents)

      snippet[description] = { prefix: i.trigger, body: body }

    output = {}
    output[scope] = snippet

    return output
