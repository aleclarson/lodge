
colors =

  # saturated colors
  red: [5, 0, 0]
  blue: [0, 1, 5]
  green: [0, 5, 1]
  yellow: [5, 5, 0]
  cyan: [0, 3, 4]
  pink: [5, 0, 4]

  # light colors
  lred: [5, 0, 1]
  lblue: [3, 3, 5]
  lgreen: [0, 5, 3]
  lyellow: [5, 5, 2]
  lcyan: [1, 4, 5]
  lpink: [5, 1, 4]

  # grayscale
  white: [5, 5, 5]
  silver: [4, 4, 4]
  gray: [2, 2, 2]
  coal: [1, 1, 1]
  black: [0, 0, 0]

noop = (arg) -> arg

module.exports = (log, colorEnabled) ->

  if colorEnabled
    ansi = require 'ansi-256-colors'
    Object.keys(colors).forEach (key) ->
      color = ansi.fg.getRgb ...colors[key]
      log[key] = (msg) ->
        if msg is '' then msg else color + msg + ansi.reset
      return

  else Object.keys(colors).forEach (key) ->
    log[key] = noop
    return