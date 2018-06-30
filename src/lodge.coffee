colorize = require './colorize'

def = Object.defineProperty

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

NO_COLOR =
  if isCLI and process.stdout.isTTY
    hasFlag('--no-color') or env.NO_COLOR is '1'
  else env.COLOR isnt '1'

NO_WARNINGS =
  hasFlag('--no-warnings') or env.NO_WARNINGS is '1'

TRACE_WARNINGS =
  if !NO_WARNINGS
    hasFlag('--trace-warnings') or env.TRACE_WARNINGS is '1'
  else false


quiet = -> # no-op
quiet.write = -> # no-op

colorize quiet, false


methods =
  warn: null
  error: null
  write: null
  debug: null
  prefix: null
  clear: null

createLog = ->
  log = (...args) -> log.write ...args
  Object.assign log, methods


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

  createWriter = (stream, label) -> (...args) ->
    i = 0
    prefix = getPrefix this, label
    output = ''

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
      arg = args[i++]
      output = join output,
        if typeof arg is 'string'
        then arg else inspect arg

    output and= join prefix, output
    stream.write output + '\n'
    return

  methods.warn =
    if !NO_WARNINGS
    then createWriter process.stdout, quiet.yellow('warn:')
    else quiet.write

  methods.error =
    createWriter process.stderr, quiet.red('error:')

  if !isQuiet
    methods.write = createWriter process.stdout
    methods.clear = ->
      # print line breaks until the screen is empty
      process.stdout.write '\x33[2J'
      # clear the scroll history
      process.stdout.write '\u001b[H\u001b[2J\u001b[3J'
      return

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
    if !$0 = getPrefix this
      write $1, ...args
      return

    if !args.length and $1 is ''
      write $1
      return

    if typeof $1 isnt 'string'
      write $0, $1, ...args
      return

    write $0 + ' ' + $1, ...args
    return

  methods.warn =
    if !NO_WARNINGS
    then createWriter console.warn
    else quiet.write

  methods.error =
    createWriter console.error

  if !isQuiet
    methods.write = createWriter console.log
    methods.clear = console.clear


if isQuiet or !DEBUG = env.DEBUG
  methods.debug = -> quiet
else if hasFlag('--debug') or /^(\*|1)$/.test DEBUG
  methods.debug = createLog
else
  DEBUG = DEBUG.replace(/\*/g, '.*').replace(/,/g, '|')
  DEBUG = new RegExp '^(' + DEBUG + ')$'
  methods.debug = (id) ->
    DEBUG.test(id) and createLog() or quiet


join = (a, b) ->
  if a then a + ' ' + b else b

getPrefix = (self, label) ->
  prefix = self._prefix?() or ''
  if self isnt log and log._prefix
    prefix = join log._prefix(), prefix
  if label
  then join prefix, label
  else prefix

if isQuiet
  methods.prefix = -> this
else
  colorize methods, !NO_COLOR
  methods.prefix = (prefix) ->
    def this, '_prefix',
      value: typeof prefix is 'function' and prefix or -> prefix
      configurable: true


# Warnings and errors are not disabled by --quiet
quiet.warn = methods.warn
quiet.error = methods.error

# Ensure all expected methods exist
quiet.debug = methods.debug
quiet.prefix = methods.prefix
quiet.clear = quiet.write

# Ignore any property mutation.
Object.freeze quiet


if isQuiet
  log = -> # no-op
  Object.assign log, quiet
  log.create = -> quiet
else
  log = createLog()
  log.create = createLog

module.exports = log
