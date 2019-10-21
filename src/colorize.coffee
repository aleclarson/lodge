
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

  if !colorEnabled
    log.bold = noop
    Object.keys(colors).forEach (key) ->
      log[key] = noop
    return

  wrap = (a, b, msg) ->
    '\x1b[' + a + 'm' + msg + '\x1b[' + b + 'm'

  getRgb = ([r, g, b]) ->
    '38;5;' + (16 + (36 * r) + (6 * g) + b)

  log.bold = (msg) ->
    if msg is '' then '' else wrap 1, 22, msg

  Object.keys(colors).forEach (key) ->
    color = getRgb colors[key]
    log[key] = (msg) ->
      if msg is '' then '' else wrap color, 0, msg
