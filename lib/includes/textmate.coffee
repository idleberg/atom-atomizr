parseJson = require 'parse-json'
plist = require 'plist'
uuid = require 'uuid'
shared = require './shared'

module.exports =

  read_plist: (input) ->
    # Validate CSON
    try
      data = plist.parse(input)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return false

    unless data.content? and data.tabTrigger? and data.scope?
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid TextMate snippet file. Aborting.", dismissable: false)
      return false

    # Conversion
    output =
      scope: data.scope
      completions: [
        contents: data.content
        trigger: data.tabTrigger
      ]

    return output

  write_plist: (meta, input) ->
    if input.completions[0].description
      name = input.completions[0].description
    else
      name = input.completions[0].trigger

    data =
      comment: meta
      content: input.completions[0].contents
      tabTrigger: input.completions[0].trigger
      name: name
      scope: input.scope
      uuid: uuid.v4()

    output = plist.build(data)

    return output
