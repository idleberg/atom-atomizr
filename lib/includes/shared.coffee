module.exports =

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

  addTrailingTabstops: (input) ->
    return unless input?

    unless input.match(/\$\d+$/g) is null and atom.config.get('atomizr.addTrailingTabstops') is not false
      # nothing to do here
      return input

    return "#{input}$0"

  removeTrailingTabstops: (input) ->
    return unless input?

    if input.match(/\$\d+$/g) is null or atom.config.get('atomizr.removeTrailingTabstops') is false
      # nothing to do here
      return input

    return input.replace(/\$\d+$/g, "")
