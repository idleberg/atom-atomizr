{CompositeDisposable} = require 'atom'

# 3rd-party dependencies
fs = require 'fs'
path = require 'path'
CSON = require 'cson'
parseCson = require 'cson-parser'
parseJson = require 'parse-json'
{parseString} = require 'xml2js'

module.exports = Atomizr =
  config:
    renameFiles:
      title: "Rename Files"
      description: "This will rename all files after the conversion"
      type: "boolean"
      default: true
  atom: atom
  workspace: atom.workspace
  grammars: atom.grammars
  subscriptions: null
  meta: "Generated with Atomizr – https://atom.io/packages/atomizr"

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
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-to-atom': => @sublToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-completions-to-atom': => @sublCompletionsToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:convert-sublime-text-snippet-to-atom': => @sublSnippetToAtom()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomizr:toggle-atom-snippet-format': => @atomToAtom()

  deactivate: ->
    @subscriptions.dispose()

  # Automatic conversion, based on scope
  autoConvert: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      @atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.coffee"
      @atomToSubl()
    else if scope is "source.json.subl"
      @sublCompletionsToAtom()
    else if scope is "text.xml.subl"
      @sublSnippetToAtom()

  # Convert Atom snippet into Sublime Text completion
  atomToSubl: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
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
      @atom.notifications.addWarning("Atomizr", detail: "This doesn't seem to be a valid Atom snippet file. Aborting.", dismissable: false)
      return

    # Convert to JSON
    json = JSON.stringify(sublime, null, 2)

    # Write back to editor and change scope
    editor.setText(json)
    editor.setGrammar(@grammars.grammarForScopeName('source.json.subl'))
    @renameFile(editor, "sublime-completions")

    # rename file
    inputFile = editor.getPath()
    parentDir = path.dirname(inputFile)
    baseName = path.basename(inputFile, path.extname(inputFile))
    outputFile =  path.join(parentDir, baseName + ".sublime-completions")
    fs.rename(inputFile, outputFile)

  # Convert Sublime Text completion into Atom snippet
  sublToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      @atom.beep()
      return
    scope = editor.getGrammar().scopeName

    if scope is "source.json.subl"
      @sublCompletionsToAtom()
    else if scope is "text.xml.subl"
      @sublSnippetToAtom()

  # Convert Sublime Text completion into Atom snippet
  sublCompletionsToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
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
    unless obj.scope? or obj.completions?
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
      if v.trigger?

        # Split tab-separated description
        unless v.trigger.indexOf("\t") is -1
          tabs = v.trigger.split("\t")

          @atom.notifications.addWarning("Atomizr", detail: "Conversion aborted, trigger '#{v.trigger}' contains multiple tabs", dismissable: true) if tabs.length > 2

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
    unless obj.scope? or obj.content?
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

    obj.content = @addTrailingTabstops(obj.content[0].trim())

    snippet = {}
    snippet[obj.description] = { prefix: obj.tabTrigger[0], body: obj.content }

    atom = {}
    atom[scope] = snippet

    # Convert to CSON
    @makeCoffee(editor, atom)

  # Convert Atom snippet format (CSON to JSON, or vice versa)
  atomToAtom: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
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
    unless editor?
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
    @renameFile(editor, "json")

  jsonToCson: ->
    editor = @workspace.getActiveTextEditor()
    unless editor?
      @atom.beep()
      return
    text = editor.getText()

    # Conversion
    try
      input = parseJson(text)
    catch e
      @atom.notifications.addError("Atomizr", detail: e, dismissable: true)
      return

    # Convert to CSON
    @makeCoffee(editor, input)

  addTrailingTabstops: (input) ->
    unless input.match(/\$\d+$/g) is null
      # nothing to do here
      return input

    re  = /\${?(\d+)/g;
    tabStops = [];

    while (m = re.exec(input)) != null
      tabStops.push m[1]

    # no tab-stops
    unless tabStops.length
      return "#{input}$1"
    
    tabStops = tabStops.sort()
    highest = parseInt(tabStops[tabStops.length - 1]) + 1

    return "#{input}$#{highest}"

  removeTrailingTabstops: (input) ->
    if input.match(/\$\d+$/g) is null
      # nothing to do here
      return input

    return input.replace(/\$\d+$/g, "")

  renameFile: (editor, extension) ->
    if @atom.config.get('atomizr.renameFiles')
      inputFile = editor.getPath()
      parentDir = path.dirname inputFile
      baseName = path.basename inputFile, path.extname inputFile
      outputFile = path.join parentDir, baseName + ".#{extension}"
      fs.rename inputFile, outputFile

  makeCoffee: (editor, input) ->
    output = CSON.createCSONString(input)

    # Write back to editor and change scope
    editor.setText("# #{@meta}\n#{output}")
    editor.setGrammar(@grammars.grammarForScopeName('source.coffee'))
    @renameFile(editor, "cson")
