parseJson = require 'parse-json'
shared = require './shared'

module.exports =

  read_json: (input) ->
    # Validate CSON
    try
      data = parseJson(input)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return false

    # Conversion
    output =
      scope: "source"
      completions: []

    for key, val of data
      if val.prefix?

        # Create tab-separated description
        body = shared.removeTrailingTabstops(val.body)
        trigger = val.prefix

        unless key is val.prefix
          description = key
        else
          description = null

        if description?
          output.completions.push { trigger: trigger, contents: body, description: description }
        else
          output.completions.push { trigger: trigger, contents: body }

    # Minimum requirements
    if output.completions.length is 0
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Visual Studio Code snippet file. Aborting.", dismissable: false)
      return false

    return output

  write_json: (input) ->
    data = {}

    for i in input.completions

      if i.description
        description = i.description
      else
        description = i.trigger

      body = shared.addTrailingTabstops(i.contents)

      data[description] = { prefix: i.trigger, body: body }

    try
      output = JSON.stringify(data, null, 2)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return false

    return output
