# Atomizr for Atom

[![apm](https://img.shields.io/apm/l/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/v/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/dm/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![Travis](https://img.shields.io/travis/idleberg/atom-atomizr.svg?style=flat-square)](https://travis-ci.org/idleberg/atom-atomizr)
[![David](https://img.shields.io/david/idleberg/atom-atomizr.svg?style=flat-square)](https://david-dm.org/idleberg/atom-atomizr)
[![David](https://img.shields.io/david/dev/idleberg/atom-atomizr.svg?style=flat-square)](https://david-dm.org/idleberg/atom-atomizr?type=dev)

Converts Sublime Text completions into Atom snippets, and vice versa.

Also available for [Sublime Text](https://github.com/idleberg/sublime-atomizr) and the [command line](https://github.com/idleberg/ruby-atomizr) (see [comparison chart](https://gist.github.com/idleberg/db6833ee026d2cd7c043bba36733b701)).

## Installation

Install `atomizr` from Atom's [Package Manager](http://flight-manual.atom.io/using-atom/sections/atom-packages/) or the command-line equivalent:

`$ apm install atomizr`

### GitHub

Change to your Atom packages directory:

```bash
# Windows
$ cd %USERPROFILE%\.atom\packages

# Linux & macOS
$ cd ~/.atom/packages/
```

Clone the repository as `atomizr`:

```bash
$ git clone https://github.com/idleberg/atom-atomizr atomizr
```

## Usage

This plugin works on active views only, so start by opening a Sublime Text completion or an Atom snippet.

There are several commands available to start conversion, each available from the [Command Palette](http://flight-manual.atom.io/getting-started/sections/atom-basics/#_command_palette) and the Packages menu.

* Automatic conversion
* Convert Sublime Text to Atom
* Convert Atom to Sublime Text
* Convert Sublime Text completions to Atom
* Convert Sublime Text snippet to Atom
* Toggle Atom format (CSON⟷JSON)
* Toggle Sublime Text format (XML⟷JSON)

The shortcut for automatic conversion is also available in the context menu.

### Keyboard Shortcuts

*The following examples all use the macOS shortcuts, for Linux or Windows use <kbd>Ctrl</kbd>+<kbd>Alt</kbd> rather than just <kbd>Ctrl</kbd>.*

Memorizing the keyboard shortcuts for conversion is easy. Just think of the <kbd>S</kbd> key for Sublime Text and the <kbd>A</kbd> key for Atom.

* Sublime Text to Atom (S to A): <kbd>Ctrl</kbd>+<kbd>S</kbd>, <kbd>Ctrl</kbd>+<kbd>A</kbd>
* Atom to Sublime Text (A to S): <kbd>Ctrl</kbd>+<kbd>A</kbd>, <kbd>Ctrl</kbd>+<kbd>S</kbd>

For automatic conversion, press <kbd>Ctrl</kbd>+<kbd>C</kbd> twice.

## Grammar

To ensure automatic conversion to work more reliably, this package installs grammar for a variety of Sublime Text files. As a side effect, these files get proper syntax highlighting.

## License

This work is licensed under the [The MIT License](LICENSE.md).

## Donate

You are welcome support this project using [Flattr](https://flattr.com/submit/auto?user_id=idleberg&url=https://github.com/idleberg/atom-atomizr) or Bitcoin `17CXJuPsmhuTzFV2k4RKYwpEHVjskJktRd`
