{CompositeDisposable} = require 'atom'

# Dependencies
CSON = require('CSON')

module.exports = Atomizr =
  workspace: atom.workspace
  grammars: atom.grammars
  subscriptions: null

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:automatic-conversion': => @autoConvert()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-atom-to-sublime-text': => @convertAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-to-atom': => @convertSubl()

  deactivate: ->
    @subscriptions.dispose()

  # Automatic conversion, based on scope
  autoConvert: ->
    editor = @workspace.getActiveTextEditor()
    scope = editor.getGrammar().scopeName

    if scope is "source.coffee"
      @convertAtom()
    else if scope is "source.json.subl"
      @convertSubl()

  # Convert Atom snippet into Sublime Text completion
  convertAtom: ->
    editor = @workspace.getActiveTextEditor()
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
  convertSubl: ->
    editor = @workspace.getActiveTextEditor()
    text = editor.getText()

    obj = CSON.parseJSONString(text)

    # Valid JSON?
    if obj instanceof Error || typeof obj.scope is 'undefined'
      throw new SyntaxError("Invalid JSON")

    # Conversion
    scope = "." + obj.scope
    completions = {}

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
