{CompositeDisposable} = require 'atom'

# 3rd-party dependencies
fs = require 'fs'
path = require 'path'
CSON = require 'cson'
parseCson = require 'cson-parser'
parseJson = require 'parse-json'
convert = require('xml-js')

module.exports = Atomizr =
  config:
    renameFiles:
      title: "Rename Files"
      description: "After conversion, files are renamed for better grammar detection"
      type: "boolean"
      default: true
      order: 1
    addTrailingTabstops:
      title: "Add trailing tab-stops"
      description: "Without trailing tab-stops, you can't jump past an Atom snippet"
      type: "boolean"
      default: true
      order: 2
    removeTrailingTabstops:
      title: "Remove trailing tab-stops"
      description: "Sublime Text files don't need trailing tab-stops"
      type: "boolean"
      default: true
      order: 3
  workspace: atom.workspace
  grammars: atom.grammars
  subscriptions: null
  meta: "Generated with Atomizr – https://atom.io/packages/atomizr"

  # Replace syntax scopes, since they don't always match
  # More info at https://gist.github.com/idleberg/fca633438329cc5ae327
  exceptions:
    "source.c++": ".source.cpp"
    "source.java-props": ".source.java-properties"
    "source.objc++": ".source.objcpp"
    "source.php": ".source.html.php"
    "source.scss": ".source.css.scss"
    "source.todo": ".text.todo"
    "source.markdown": ".source.gfm"

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:automatic-conversion': => @autoConvert()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-atom-to-sublime-text': => @atomToSubl(null)
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-to-atom': => @sublToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-completions-to-atom': => @sublCompletionsToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-snippet-to-atom': => @sublSnippetToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:toggle-atom-format': => @atomToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:toggle-sublime-sublformat': => @sublToSubl()

  deactivate: ->
    @subscriptions.dispose()

  # Automatic conversion, based on scope
  autoConvert: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.coffee"
      @atomToSubl(null)
    else if scope is "source.json.subl"
      @sublCompletionsToAtom()
    else if scope is "text.xml.subl"
      @sublSnippetToAtom()

  # Convert Atom snippet into Sublime Text completion
  atomToSubl: (editor) ->
    if editor is null
      editor = @workspace.getActiveTextEditor()

    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Validate CSON
    try
      obj = parseCson.parse(text)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Conversion
    sublime =
      meta: @meta
      scope: null
      completions: []

    for k,v of obj

      # Get scope, convert if necessary
      for subl,atom of @exceptions
        if k is atom
          sublime.scope = subl
        else
          sublime.scope = k.substring(1)

      for i, j of v
        if j.prefix?

          # Create tab-separated description
          unless i is j.prefix
            trigger = "#{j.prefix}\t#{i}"
          else
            trigger = j.prefix

          j.body = @removeTrailingTabstops(j.body)
          sublime.completions.push { trigger: trigger, contents: j.body }

    # Minimum requirements
    if sublime.completions.length is 0
      @invalidFormat("Atom snippet")
      return

    # Convert to JSON
    json = JSON.stringify(sublime, null, 2)

    # Write back to editor and change scope
    editor.setText(json)
    editor.setGrammar(@grammars.grammarForScopeName('source.json.subl'))
    @renameFile(editor, "sublime-completions")

  # Convert Sublime Text completion into Atom snippet
  sublToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.json.subl"
      @sublCompletionsToAtom()
    else if scope is "text.xml.subl"
      @sublSnippetToAtom()
    else
      @invalidFormat("Sublime Text")

  # Convert Sublime Text completion into Atom snippet
  sublCompletionsToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Validate JSON
    try
      obj = parseJson(text)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Minimum requirements
    unless obj.scope? or obj.completions?
      @invalidFormat("Sublime Text completions")
      return

    # Conversion
    completions = {}

    # Get scope, convert if necessary
    for subl,atom of @exceptions
      if obj.scope is subl
        scope = atom
        break
      else
        scope = "." + obj.scope

    for k,v of obj.completions
      if v.trigger?

        # Split tab-separated description
        unless v.trigger.indexOf("\t") is -1
          tabs = v.trigger.split("\t")

          atom.notifications.addWarning("Atomizr", detail: "Conversion aborted, trigger '#{v.trigger}' contains multiple tabs", dismissable: true) if tabs.length > 2

          trigger = tabs[0]
          description = tabs.slice(-1).pop()
        else
          description = v.trigger
          trigger = v.trigger

        v.contents = @addTrailingTabstops(v.contents)
        completions[description] = { prefix: trigger, body: v.contents }

    atom = { }
    atom[scope] = completions

    # Convert to CSON
    @makeCoffee(editor, atom)

  # Convert Sublime Text snippet into Atom snippet
  sublSnippetToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    obj = null

    # Validate XML
    try
      obj = convert.xml2js(text, {spaces: 4, compact:true})
    catch e
      atom.notifications.addError("Atomizr", detail: "Invalid XML, aborting", dismissable: false)
      return

    # Minimum requirements
    unless obj.snippet.scope? or obj.snippet.content._cdata?
      @invalidFormat("Sublime Text snippet")
      return

    # Get scope, convert if necessary
    for subl,atom of @exceptions
      if obj.snippet.scope.toString() is subl
        scope = atom
        break
      else
        scope = "." + obj.snippet.scope["_text"]

    if obj.snippet.description
      description = obj.snippet.description["_text"]
    else
      description = obj.snippet.tabTrigger["_text"]

    prefix = obj.snippet.tabTrigger["_text"]
    content = @addTrailingTabstops(obj.snippet.content._cdata.trim())

    snippet = {}
    snippet[description] = { prefix: prefix, body: content }

    atom = {}
    atom[scope] = snippet

    # Convert to CSON
    @makeCoffee(editor, atom)

  # Convert Atom snippet format (CSON to JSON, or vice versa)
  atomToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    scope = editor.getGrammar().scopeName

    # Automatic conversion, based on scope
    if scope is "source.coffee"
      @csonToJson()
    else if scope is "source.json"
      @jsonToCson()

  csonToJson: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseCson.parse(text)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    output = CSON.createJSONString(input)

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(@grammars.grammarForScopeName('source.json'))
    @renameFile(editor, "json")

  jsonToCson: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseJson(text)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Convert to CSON
    @makeCoffee(editor, input)

  # Convert Sublime snippet format (JSON to XML, or vice versa)
  sublToSubl: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    scope = editor.getGrammar().scopeName

    
    # Automatic conversion, based on scope
    if scope is "source.json.subl"
      @jsonToXml()
    else if scope is "text.xml.subl"
      @xmlToJson()

  xmlToJson: () ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = convert.xml2js(text, {spaces: 4, compact:true})
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Minimum requirements
    unless input.snippet.scope? or input.snippet.content._cdata?
      @invalidFormat("Sublime Text snippet")
      return

    obj =
      meta: @meta
      scope: input.snippet.scope["_text"]
      completions: [
        contents: input.snippet.content._cdata
        trigger: input.snippet.tabTrigger["_text"]
      ]

    if input.snippet.description
      obj.completions.trigger = "#{obj.completions.trigger}\t#{input.snippet.description['_text']}"

    json = JSON.stringify(obj, null, '\t')

    # Write back to editor and change scope
    editor.setText(json)
    editor.setGrammar(@grammars.grammarForScopeName('source.json.subl'))
    @renameFile(editor, "sublime-completions")

  jsonToXml: () ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseJson(text)
    catch e
      atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    obj =
      _comment: @meta
      snippet:
        content:
          _cdata: input.completions[0].contents
        tabTrigger:
          _text: input.completions[0].trigger
        scope:
          _text: input.scope

    xml = convert.js2xml(obj, {compact: true, spaces: 4})

    # Write back to editor and change scope
    editor.setText(xml)
    editor.setGrammar(@grammars.grammarForScopeName('text.xml.subl'))
    @renameFile(editor, "sublime-snippet")

  addTrailingTabstops: (input) ->
    unless input.match(/\$\d+$/g) is null and atom.config.get('atomizr.addTrailingTabstops') is not false
      # nothing to do here
      return input

    re  = /\${?(\d+)/g
    tabStops = []

    while (m = re.exec(input)) != null
      tabStops.push m[1]

    # no tab-stops
    unless tabStops.length
      return "#{input}$1"

    tabStops = tabStops.sort()
    highest = parseInt(tabStops[tabStops.length - 1]) + 1

    return "#{input}$#{highest}"

  removeTrailingTabstops: (input) ->
    if input.match(/\$\d+$/g) is null or atom.config.get('atomizr.removeTrailingTabstops') is false
      # nothing to do here
      return input

    return input.replace(/\$\d+$/g, "")

  renameFile: (editor, extension) ->
    if atom.config.get('atomizr.renameFiles')
      inputFile = editor.getPath()
      parentDir = path.dirname inputFile
      baseName = path.basename inputFile, path.extname inputFile
      outputFile = path.join parentDir, baseName + ".#{extension}"
      fs.rename inputFile, outputFile
      editor.saveAs(outputFile)

  invalidFormat: (type) ->
    atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid #{type} file. Aborting.", dismissable: false)

  makeCoffee: (editor, input) ->
    output = CSON.createCSONString(input)

    # Write back to editor and change scope
    editor.setText("# #{@meta}\n#{output}")
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))
    @renameFile(editor, "cson")
