{CompositeDisposable} = require 'atom'

# 3rd-party dependencies
CSON = require 'cson'
parseCson = require 'cson-parser'
parseJson = require 'parse-json'
{parseString} = require 'xml2js'

module.exports = Atomizr =
  atom: atom
  workspace: atom.workspace
  grammars: atom.grammars
  subscriptions: null

  # Replace scope-name exceptions
  # https://gist.github.com/idleberg/fca633438329cc5ae327
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
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-atom-to-sublime-text': => @atomToSubl()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-completions-to-atom': => @sublToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-snippet-to-atom': => @sublSnipToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-atom-format': => @atomToAtom()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

  # Automatic conversion, based on scope
  autoConvert: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.coffee"
      @atomToSubl()
    else if scope is "source.json.subl"
      @sublToAtom()
    else if scope is "text.xml.subl"
      @sublSnipToAtom()

  # Convert Atom snippet into Sublime Text completion
  atomToSubl: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    # Validate CSON
    try
      obj = parseCson.parse(text)
    catch e
      @atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Conversion
    sublime =
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
        unless typeof j.prefix is 'undefined'
          sublime.completions.push { trigger: j.prefix, contents: j.body }

    # Minimum requirements
    if sublime.completions.length is 0
      @atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Atom snippet file. Aborting.", dismissable: false)
      return

    # Convert to JSON
    json = JSON.stringify(sublime, null, 2)

    # Write back to editor and change scope
    editor.setText(json)
    editor.setGrammar(@grammars.grammarForScopeName('source.json.subl'))

  # Convert Sublime Text completion into Atom snippet
  sublToAtom: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    # Validate JSON
    try
      obj = parseJson(text)
    catch e
      @atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Minimum requirements
    if typeof obj.scope is 'undefined' or typeof obj.completions is 'undefined'
      @atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Sublime Text completions file. Aborting.", dismissable: false)
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
      unless typeof v.trigger is 'undefined'
        completions[v.trigger] = { prefix: v.trigger, body: v.contents }

    atom = {}
    atom[scope] = completions

    # Convert to CSON
    cson = CSON.createCSONString(atom)

    # Write back to editor and change scope
    editor.setText(cson)
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))

  # Convert Sublime Text snippet into Atom snippet
  sublSnipToAtom: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    obj = null

    # Validate XML
    try
      parseString text, (e, result) ->
        obj = result.snippet
    catch e
      @atom.notifications.addError("Atomizr", detail: "Invalid XML, aborting", dismissable: false)
      return

    # Minimum requirements
    if typeof obj.scope is 'undefined' or typeof obj.content is 'undefined'
      @atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Sublime Text snippet file. Aborting.", dismissable: false)
      return

    # Get scope, convert if necessary
    for subl,atom of @exceptions
      if obj.scope.toString() is subl
        scope = atom
        break
      else
        scope = "." + obj.scope

    if obj.description
      description = obj.description
    else
      description = obj.tabTrigger

    snippet = {}
    snippet[obj.description] = { prefix: obj.tabTrigger[0], body: obj.content[0].trim() }

    atom = {}
    atom[scope] = snippet

    # Convert to CSON
    cson = CSON.createCSONString(atom)

    # Write back to editor and change scope
    editor.setText(cson)
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))

  # Convert Atom snippet format (CSON to JSON, or vice versa)
  atomToAtom: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    scope = editor.getGrammar().scopeName

    # Automatic conversion, based on scope
    if scope is "source.coffee"
      @csonToJson()
    else if scope is "source.json"
      @jsonToCson()

  csonToJson: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseCson.parse(text)
    catch e
      @atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    output = CSON.createJSONString(input)

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(@grammars.grammarForScopeName('source.json'))

  jsonToCson: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseJson(text)
    catch e
      @atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    output = CSON.createCSONString(input)

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))
