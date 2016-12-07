convert = require 'xml-js'
parseJson = require 'parse-json'
shared = require './shared'

module.exports =
  meta: "Generated with Atomizr – https://atom.io/packages/atomizr"

  read_json: (input) ->
    # Validate JSON
    try
      data = parseJson(input)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Minimum requirements
    unless data.scope? or data.completions?
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Sublime Text completions file. Aborting.", dismissable: false)
      return false

    # Conversion
    output = {}

    output.scope = data.scope

    output.completions = []
    i = 0

    for k,v of data.completions
      if v.trigger?

        # Split tab-separated description
        unless v.trigger.indexOf("\t") is -1 or atom.config.get('atomizr.ignoreTabChar') is true
          tabs = v.trigger.split("\t")

          atom.notifications.addWarning("Atomizr", detail: "Conversion aborted, trigger '#{v.trigger}' contains multiple tabs", dismissable: true) if tabs.length > 2

          trigger = tabs[0]
          description = tabs.slice(-1).pop()
        else
          trigger = v.trigger
          description = null

        if description?
          output.completions[i] = { description: description, trigger: trigger, contents: v.contents }
        else
          output.completions[i] = { trigger: trigger, contents: v.contents }

        i++

    return output

  read_xml: (input) ->
    # Validate XML
    try
      data = convert.xml2js(input, {spaces: 4, compact:true})
    catch e
      atom.notifications.addError("Atomizr", detail: "Invalid XML, aborting", dismissable: false)
      return false
 
    # Minimum requirements
    unless data.snippet.scope? or data.snippet.content._cdata?
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Sublime Text snippet file. Aborting.", dismissable: false)
      return false

    output = {}

    # Get scope, convert if necessary
    output.scope = data.snippet.scope["_text"]

    if data.snippet.description
      description = data.snippet.description["_text"]

    trigger = data.snippet.tabTrigger["_text"]
    contents = data.snippet.content._cdata.trim()

    if description
      output.completions = [
        description: description
        trigger: trigger
        contents: contents
      ]
    else
      output.completions = [
        trigger: trigger
        contents: contents
      ]

    return output

  write_json: (input) ->
    completions = []
    i = 0

    for item in input.completions
      contents = item.contents
      if item.description
        trigger = "#{item.trigger}\t#{item.description}"
      else
        trigger = item.trigger
      
      completions[i] =
        contents: contents
        trigger: trigger

      i++

    data = {
      '#': @meta
      scope: input.scope
      completions: completions
    }
    
    try
      output = JSON.stringify(data, null, 2)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return false

    return output

  write_xml: (input) ->
    if input.completions[0].description
      obj =
        _comment: " #{@meta} "
        snippet:
          content:
            _cdata: input.completions[0].contents
          tabTrigger:
            _text: input.completions[0].trigger
          description:
            _text: input.completions[0].description
          scope:
            _text: input.scope
    else
      obj =
        _comment: " #{@meta} "
        snippet:
          content:
            _cdata: input.completions[0].contents
          tabTrigger:
            _text: input.completions[0].trigger
          scope:
            _text: input.scope

    output = convert.js2xml(obj, {compact: true, spaces: 4})

    return output

  xmlToJson: () ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    input = editor.getText()

    data = @read_xml(input)
    return if data is false

    output = @write_json(data)
    return if output is false

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(atom.grammars.grammarForScopeName('source.json.subl'))
    @renameFile(editor, "sublime-completions")

  jsonToXml: () ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    input = editor.getText()

    # Conversion
    data = @read_json(input)
    return if data is false

    output = @write_xml(data)
    return if output is false

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(atom.grammars.grammarForScopeName('text.xml.subl'))
    @renameFile(editor, "sublime-snippet")
