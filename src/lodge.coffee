colorize = require './colorize'
hasFlag = require 'has-flag'

{env} = process

quiet = ->
quiet.debug = -> quiet
colorize quiet, false

if !hasFlag('--quiet') and env.QUIET isnt '1'

  colorEnabled =
    if isTTY
      !hasFlag('--no-color') and env.NO_COLOR isnt '1'
    else env.COLOR is '1'

  warningsEnabled =
    !hasFlag('--no-warnings') and env.NO_WARNINGS isnt '1'

  console.log 'colorEnabled:', colorEnabled
  console.log 'isTTY:', isTTY

  if typeof document is 'undefined'
    {isTTY} = process.stdout

    inspect = do ->
      util = require 'util'
      opts = colors: colorEnabled, depth: 1
      (arg) -> util.inspect arg, opts

    format = (arg, type) ->
      switch type
        when '%s' then String arg
        when '%O' then inspect arg
        when '%d', '%f' then Number arg
        when '%i' then parseInt arg
        else arg

    createLog = (stream, prefix) -> (...args) ->
      i = 0
      output = prefix

      if typeof args[0] is 'string'
        input = args[i++]
        offset = 0
        pattern = /%[dfisO]/g
        while match = pattern.exec input
          arg = args[i++]
          output += input.slice(offset, match.index) + format arg, match[0]
          offset = match.index + 2
        output += input.slice offset

      while i < args.length
        output += ' ' if i > 0
        output += inspect args[i++]

      stream.write output + '\n'
      return

    log = createLog process.stdout, ''
    colorize log, colorEnabled
    log.warn =
      if warningsEnabled
      then createLog process.stdout, log.yellow('⚠️  warn: ')
      else -> # no-op
    log.error = createLog process.stderr, log.red('🔥 error: ')

  else
    log = console.log.bind()
    colorize log, colorEnabled
    log.warn =
      if warningsEnabled
      then console.warn
      else -> # no-op
    log.error = console.error

  # Warnings and errors are not disabled by --quiet
  quiet.warn = log.warn
  quiet.error = log.error

  if hasFlag('--debug') or /^(\*|1)$/.test env.DEBUG
    isDebug = -> true
  else
    env.DEBUG = env.DEBUG.replace(/\*/g, '.*').replace(/,/g, '|')
    DEBUG_RE = new RegExp '^(' + env.DEBUG + ')$'
    isDebug = (id) -> DEBUG_RE.test id

  log.debug = (id) ->
    if isDebug id then log else quiet

module.exports = log
