parseCson = require 'cson-parser'
{exceptions} = require './exceptions'

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
      for scopeSubl, scopeAtom of exceptions
        if k is scopeAtom
          output.scope = scopeSubl
        else if k[0] is "."
          output.scope = k.substring(1)
        else
          output.scope = k

      for i, j of v
        if j.prefix?

          # Create tab-separated description
          unless i is j.prefix
            trigger = "#{j.prefix}\t#{i}"
          else
            trigger = j.prefix

          j.body = @removeTrailingTabstops(j.body)
          output.completions.push { trigger: trigger, contents: j.body }

    # Minimum requirements
    if output.completions.length is 0
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Atom snippet file. Aborting.", dismissable: false)
      return false

    return output

  write_cson: (input) ->
    snippet = {}

    if input.scope[0] isnt "."
      input.scope = ".#{input.scope}"

    for i in input.completions

      if i.description
        description = i.description
      else
        description = i.trigger

      body = @addTrailingTabstops(i.contents)

      snippet[description] = { prefix: i.trigger, body: body }

    atom = {}
    atom[input.scope] = snippet

    return atom

  addTrailingTabstops: (input) ->
    unless input.match(/\$\d+$/g) is null and atom.config.get('atomizr.addTrailingTabstops') is not false
      # nothing to do here
      return input

    return "#{input}$0"

  removeTrailingTabstops: (input) ->
    if input.match(/\$\d+$/g) is null or atom.config.get('atomizr.removeTrailingTabstops') is false
      # nothing to do here
      return input

    return input.replace(/\$\d+$/g, "")
