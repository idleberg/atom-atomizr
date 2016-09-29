{CompositeDisposable} = require 'atom'

# 3rd-party dependencies
fs = require 'fs'
path = require 'path'
CSON = require 'cson'
parseCson = require 'cson-parser'
parseJson = require 'parse-json'

SublimeText = require './includes/sublime-text'
Atom = require './includes/atom'

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
  subscriptions: null
  meta: "Generated with Atomizr – https://atom.io/packages/atomizr"

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
    editor = atom.workspace.getActiveTextEditor()
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
      editor = atom.workspace.getActiveTextEditor()

    unless editor?
      atom.beep()
      return
    input = editor.getText()

    data = Atom.read_cson(input)
    return if data is false

    output = SublimeText.write_json(data)
    return if output is false

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(atom.grammars.grammarForScopeName('source.json.subl'))
    @renameFile(editor, "sublime-completions")

  # Convert Sublime Text completion into Atom snippet
  sublToAtom: ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.json.subl"
      @sublCompletionsToAtom()
    else if scope is "text.xml.subl"
      @sublSnippetToAtom()
    else
      atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Sublime Text file. Aborting.", dismissable: false)

  # Convert Sublime Text completion into Atom snippet
  sublCompletionsToAtom: ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    input = editor.getText()

    data = SublimeText.read_json(input)
    return if data is false

    output = Atom.write_cson(data)
    return if output is false

    # Convert to CSON
    @makeCoffee(editor, output)

  # Convert Sublime Text snippet into Atom snippet
  sublSnippetToAtom: ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    input = editor.getText()
  
    data = SublimeText.read_xml(input)
    return if data is false
    
    output = Atom.write_cson(data)
    return if output is false

    # Convert to CSON
    @makeCoffee(editor, output)

  # Convert Atom snippet format (CSON to JSON, or vice versa)
  atomToAtom: ->
    editor = atom.workspace.getActiveTextEditor()
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
    editor = atom.workspace.getActiveTextEditor()
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
    editor.setGrammar(atom.grammars.grammarForScopeName('source.json'))
    @renameFile(editor, "json")

  jsonToCson: ->
    editor = atom.workspace.getActiveTextEditor()
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
    editor = atom.workspace.getActiveTextEditor()
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
    editor = atom.workspace.getActiveTextEditor()
    unless editor?
      atom.beep()
      return
    input = editor.getText()

    data = SublimeText.read_xml(input)
    return if data is false

    output = SublimeText.write_json(data)
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
    data = SublimeText.read_json(input)
    return if data is false

    output = SublimeText.write_xml(data)
    return if output is false

    # Write back to editor and change scope
    editor.setText(output)
    editor.setGrammar(atom.grammars.grammarForScopeName('text.xml.subl'))
    @renameFile(editor, "sublime-snippet")

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

  renameFile: (editor, extension) ->
    if atom.config.get('atomizr.renameFiles')
      inputFile = editor.getPath()
      parentDir = path.dirname inputFile
      baseName = path.basename inputFile, path.extname inputFile
      outputFile = path.join parentDir, baseName + ".#{extension}"
      fs.rename inputFile, outputFile
      editor.saveAs(outputFile)

  makeCoffee: (editor, input) ->
    output = CSON.createCSONString(input)

    # Write back to editor and change scope
    editor.setText("# #{@meta}\n#{output}")
    editor.setGrammar(atom.grammars.grammarForScopeName('source.coffee'))
    @renameFile(editor, "cson")
