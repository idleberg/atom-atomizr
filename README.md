# Atomizr for Atom

[![apm](https://img.shields.io/apm/l/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/v/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![apm](https://img.shields.io/apm/dm/atomizr.svg?style=flat-square)](https://atom.io/packages/atomizr)
[![Travis](https://img.shields.io/travis/idleberg/atom-atomizr.svg?style=flat-square)](https://travis-ci.org/idleberg/atom-atomizr)
[![David](https://img.shields.io/david/idleberg/atom-atomizr.svg?style=flat-square)](https://david-dm.org/idleberg/atom-atomizr)
[![David](https://img.shields.io/david/dev/idleberg/atom-atomizr.svg?style=flat-square)](https://david-dm.org/idleberg/atom-atomizr?type=dev)

Converts Sublime Text completions into Atom (or Visual Studio Code) snippets, and vice versa.

Also available for [Sublime Text](https://github.com/idleberg/sublime-atomizr) and the [command line](https://github.com/idleberg/ruby-atomizr) (see the [comparison chart](https://gist.github.com/idleberg/db6833ee026d2cd7c043bba36733b701)).

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

Install Node dependencies:

```bash
$ cd atomizr
$ yarn || npm install
```

## Usage

This plugin works on active views only, so start by opening a Sublime Text completion or an Atom snippet.

There are several commands available to start conversion, each available from the [Command Palette](http://flight-manual.atom.io/getting-started/sections/atom-basics/#_command_palette) and the Packages menu.

Action                                     | Input           | Output
-------------------------------------------|-----------------|----------------
Automatic conversion¹                      | `CSON|JSON|XML` | `CSON|JSON|XML`
Convert Atom to Sublime Text               | `CSON|JSON`     | `JSON`
Convert Atom to Visual Studio Code         | `CSON|JSON`     | `JSON`
Convert Sublime Text to Atom²              | `JSON|XML`      | `CSON|JSON`
Convert Sublime Text to Visual Studio Code | `JSON|XML`      | `JSON`
Convert Visual Studio Code to Atom²        | `JSON`          | `CSON|JSON`
Convert Visual Studio Code to Sublime Text | `JSON`          | `JSON`
Toggle Atom format                         | `CSON|JSON`     | `JSON|CSON`
Toggle Sublime Text format                 | `JSON|XML`      | `XML|JSON`

¹⁾ converts Atom and Sublime Text only  
²⁾ target syntax can be specified in the settings  

### Keyboard Shortcuts

*The following examples use the macOS keyboard shortcuts. On Linux or Windows use <kbd>Ctrl</kbd>+<kbd>Alt</kbd> as modifier key instead of <kbd>Ctrl</kbd>.*

Memorizing the keyboard shortcuts for conversion is easy. Just think of the <kbd>A</kbd> key for Atom, the <kbd>S</kbd> key for Sublime Text and the <kbd>V</kbd> key for Visual Studio Code:

Action                             | Mnemonic | Shortcut
-----------------------------------|----------|-----------------------------------------------------------
Atom to Sublime Text               | “A to S” | <kbd>Ctrl</kbd>+<kbd>A</kbd>, <kbd>Ctrl</kbd>+<kbd>S</kbd>
Atom to Visual Studio Code         | “A to V” | <kbd>Ctrl</kbd>+<kbd>A</kbd>, <kbd>Ctrl</kbd>+<kbd>V</kbd>
Sublime Text to Atom               | “S to A” | <kbd>Ctrl</kbd>+<kbd>S</kbd>, <kbd>Ctrl</kbd>+<kbd>A</kbd>
Sublime Text to Visual Studio Code | “S to V” | <kbd>Ctrl</kbd>+<kbd>S</kbd>, <kbd>Ctrl</kbd>+<kbd>V</kbd>
Visual Studio Code to Atom         | “V to A” | <kbd>Ctrl</kbd>+<kbd>V</kbd>, <kbd>Ctrl</kbd>+<kbd>A</kbd>
Visual Studio Code to Sublime Text | “V to S” | <kbd>Ctrl</kbd>+<kbd>V</kbd>, <kbd>Ctrl</kbd>+<kbd>S</kbd>
Atom to Atom                       | “A to A” | <kbd>Ctrl</kbd>+<kbd>A</kbd>, <kbd>Ctrl</kbd>+<kbd>A</kbd>
Sublime Text to Sublime Text       | “S to S” | <kbd>Ctrl</kbd>+<kbd>S</kbd>, <kbd>Ctrl</kbd>+<kbd>S</kbd>

For automatic conversion, press <kbd>Ctrl</kbd>+<kbd>C</kbd> twice.

## Grammar

To ensure automatic conversion to work more reliably, this package installs grammar for a variety of Sublime Text files. As a side effect, these files get proper syntax highlighting.

## License

This work is licensed under the [The MIT License](LICENSE.md).

## Donate

You are welcome support this project using [Flattr](https://flattr.com/submit/auto?user_id=idleberg&url=https://github.com/idleberg/atom-atomizr) or Bitcoin `17CXJuPsmhuTzFV2k4RKYwpEHVjskJktRd`
