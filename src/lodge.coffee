colorize = require './colorize'
hasFlag = require 'has-flag'

env =
  if typeof process isnt 'undefined'
  then process.env
  else window

isCLI =
  typeof window is 'undefined'

hasFlag =
  if isCLI then require 'has-flag'
  else -> false

isQuiet =
  hasFlag('--quiet') or env.QUIET is '1'

NO_WARNINGS =
  hasFlag('--no-warnings') or env.NO_WARNINGS is '1'

NO_COLOR =
  if isCLI and process.stdout.isTTY
    hasFlag('--no-color') or env.NO_COLOR is '1'
  else env.COLOR isnt '1'

TRACE_WARNINGS =
  if !NO_WARNINGS
    hasFlag('--trace-warnings') or env.TRACE_WARNINGS is '1'
  else false

quiet = -> # no-op
quiet.write = -> # no-op

colorize quiet, !NO_COLOR

methods =
  warn: null
  error: null
  write: null

if !isQuiet
  colorize methods, !NO_COLOR

if isCLI

  inspect = do ->
    util = require 'util'
    opts = colors: !NO_COLOR, depth: 1
    (arg) -> util.inspect arg, opts

  format = (arg, type) ->
    switch type
      when '%s' then String arg
      when '%O' then inspect arg
      when '%d', '%f' then Number arg
      when '%i' then parseInt arg
      else arg

  createWriter = (stream, prefix) -> (...args) ->
    i = 0
    output =
      if prefix
      then @prefix and @prefix() + ' ' + prefix or prefix
      else @prefix and @prefix() or ''

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

  methods.warn =
    if !NO_WARNINGS
    then createWriter process.stdout, quiet.yellow('warn: ')
    else -> # no-op

  methods.error =
    createWriter process.stderr, quiet.red('error: ')

  if !isQuiet
    methods.write = createWriter process.stdout

  if TRACE_WARNINGS then do ->
    {warn} = methods
    methods.warn = ->
      warn ...arguments

      err = new Error
      Error.captureStackTrace err, arguments.callee
      stack = err.stack
      console.log stack.slice stack.indexOf('\n') + 1
      return

else
  createWriter = (write) -> ($1, ...args) ->
    if !$0 = @prefix
      write $1, ...args
      return

    if typeof $1 isnt 'string'
      write $0, $1, ...args
      return

    write $0 + ' ' + $1, ...args
    return

  methods.warn =
    if !NO_WARNINGS
    then createWriter console.warn
    else -> # no-op

  methods.error =
    createWriter console.error

  if !isQuiet
    methods.write = createWriter console.log

# Warnings and errors are not disabled by --quiet
quiet.warn = methods.warn
quiet.error = methods.error

# Ignore any property mutation.
Object.freeze quiet

createLog = ->
  log = (...args) -> log.write ...args
  Object.assign log, methods

if isQuiet
  log = -> # no-op
  Object.assign log, quiet

else
  log = createLog()

  if DEBUG = env.DEBUG
    if hasFlag('--debug') or /^(\*|1)$/.test DEBUG
      DEBUG = test: -> true
    else
      DEBUG = DEBUG.replace(/\*/g, '.*').replace(/,/g, '|')
      DEBUG = new RegExp '^(' + DEBUG + ')$'

    log.debug = (id) ->
      DEBUG.test(id) and createLog() or quiet

log.debug or= -> quiet
log.create or=
  if isQuiet then -> quiet
  else createLog

module.exports = log
