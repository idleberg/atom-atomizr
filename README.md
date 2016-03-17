# Atomizr

[![apm](https://img.shields.io/apm/l/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/v/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/dm/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![Travis](https://img.shields.io/travis/idleberg/atom-atomizr.svg?style=flat-square)](https://travis-ci.org/idleberg/atom-atomizr)
[![David](https://img.shields.io/david/dev/idleberg/atom-atomizr.svg?style=flat-square)](https://david-dm.org/idleberg/atom-atomizr#info=dependencies)

Converts Sublime Text completions into Atom snippets, and vice versa.

This package is also available for [Sublime Text](https://github.com/idleberg/sublime-atomizr) and as an even more powerful [Ruby script](https://github.com/idleberg/atomizr).

## Installation

### apm

* Install package `apm install atomizr` (or use the GUI)

### GitHub

1. Change directory `cd ~/.atom/packages/`
2. Clone repository `git clone https://github.com/idleberg/atom-atomizr atomizr`

## Usage

This plugin works on active views only, so start by opening a Sublime Text completion or an Atom snippet. 

There are four basic commands available to start conversion, each available from the Command Palette and the Packages menu.

* Automatic conversion
* Convert Sublime Text completions to Atom
* Convert Sublime Text snippet to Atom
* Convert Atom to Sublime Text
* Convert Atom snippet format

A shortcut for automatic conversion is also available in the context menu.

### Keyboard Shortcuts

Memorizing the keyboard shortcuts for conversion is easy. Just think of the <kbd>s</kbd> key for Sublime Text and the <kbd>a</kbd> key for Atom:

* Sublime Text to Atom: <kbd>Ctrl</kbd>+<kbd>s</kbd>, <kbd>Ctrl</kbd>+<kbd>a</kbd> (for completions)
* Atom to Sublime Text: hold <kbd>Ctrl</kbd>+<kbd>a</kbd>, <kbd>Ctrl</kbd>+<kbd>s</kbd>

For automatic conversion, press <kbd>Ctrl</kbd>+<kbd>c</kbd> twice. To switch the Atom snippet from CSON to JSON (or vice versa), press <kbd>Ctrl</kbd>+<kbd>a</kbd> twice.

## Grammar

To ensure automatic conversion to work more reliably, this package installs grammar for a variety of Sublime Text files. As a side effect, these files get proper syntax highlighting.

## License

This work is licensed under the [The MIT License](LICENSE.md).

## Donate

You are welcome support this project using [Flattr](https://flattr.com/submit/auto?user_id=idleberg&url=https://github.com/idleberg/atom-atomizr) or Bitcoin `17CXJuPsmhuTzFV2k4RKYwpEHVjskJktRd`
