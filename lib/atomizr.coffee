{CompositeDisposable} = require 'atom'

# Dependencies
CSON = require('CSON')

module.exports = Atomizr =
  atom: atom
  workspace: atom.workspace
  grammars: atom.grammars
  subscriptions: null

  # https://gist.github.com/idleberg/fca633438329cc5ae327
  scopes:
    "source.cpp": ".source.cpp"
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
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-to-atom': => @sublToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-atom-format': => @atomToAtom()

  deactivate: ->
    @subscriptions.dispose()

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

  # Convert Atom snippet into Sublime Text completion
  atomToSubl: ->
    editor = @workspace.getActiveTextEditor()
    if typeof editor is "undefined"
      @atom.beep()
      return
    text = editor.getText()

    obj = CSON.parseCSONString(text)

    # Valid CSON?
    if obj instanceof Error
      throw new SyntaxError("Invalid CSON")

    # Conversion
    sublime =
      scope: null
      completions: []

    for k,v of obj

      # Get scope, convert if necessary
      for subl,atom of @scopes
        if k is atom
          sublime.scope = subl
        else
          sublime.scope = k.substring(1)

      for i, j of v
        unless typeof j.prefix is 'undefined'
          sublime.completions.push { trigger: j.prefix, contents: j.body }

    if sublime.completions.length is 0
      throw new RangeError("No snippets to convert")

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

    obj = CSON.parseJSONString(text)

    # Valid JSON?
    if obj instanceof Error || typeof obj.scope is 'undefined'
      throw new SyntaxError("Invalid JSON")

    # Conversion
    completions = {}

    # Get scope, convert if necessary
    for subl,atom of @scopes
      if obj.scope is subl
        scope = atom
      else
        scope = "." + obj.scope

    for k,v of obj.completions
      unless typeof v.trigger is 'undefined'
        completions[v.trigger] = { prefix: v.trigger, body: v.contents }

    if completions.length is 0
      throw new RangeError("No completions to convert")

    atom = {}
    atom[scope] = completions

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
    input = CSON.parseCSONString(text)
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
    input = CSON.parseJSONString(text)
    output = CSON.createCSONString(input)

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))
