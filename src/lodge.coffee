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


undef = -> # no-op
muted = -> quiet

quiet = -> # no-op
colorize quiet, !NO_COLOR


methods =
  warn: null
  error: null
  write: null
  debug: null
  prefix: null
  stylize: null
  clear: null
  trace: null

createLog = ->
  log = (...args) -> log.write ...args
  def log, '_parent', value: this if !isTop this
  Object.assign log, methods

methods.create = createLog

methods.trace = do ->
  home = null
  if isCLI then do ->
    mappedChars = '.': '\\.', '\\': '\\\\'
    home = require('os').homedir() + require('path').sep
    home = home.replace /[\.\\]/g, (ch) -> mappedChars[ch]
    home = new RegExp '\\(' + home, 'g'
  return (framesToPop = 0) ->
    stack = log.cleanStack Error().stack.slice(6)
    stack = stack.split('\n').slice(1 + framesToPop).join('\n')
    home and stack = stack.replace home, '(~/'
    @gray stack

# Vararg string formatter
methods.stylize = (...args) ->
  output = ''
  i = 0

  if typeof args[0] is 'string'
    input = args[i++]
    offset = 0
    pattern = /%[dfisO]/g
    while match = pattern.exec input
      arg = args[i++]
      output += input.slice(offset, match.index) + embed arg, match[0]
      offset = match.index + 2
    output += input.slice offset

  while i < args.length
    arg = args[i++]
    output = join output,
      if typeof arg is 'string'
      then arg else inspect arg

  return output

embed = (arg, type) ->
  switch type
    when '%s' then String arg
    when '%O' then inspect arg
    when '%d', '%f' then Number arg
    when '%i' then parseInt arg
    else arg


if isCLI
  isTop = (arg) -> arg is global

  # Format a non-string
  inspect = do ->
    util = require 'util'
    opts = colors: !NO_COLOR, depth: 1
    (arg) -> util.inspect arg, opts

  createWriter = (stream, label) -> (...args) ->
    prefix = getPrefix this, label
    output = log.stylize ...args
    if output = join prefix, output + '\n'
      stream.write output
      return

  methods.warn =
    if !NO_WARNINGS
    then createWriter process.stdout, quiet.yellow('warn:')
    else undef

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
      @trace 1

else
  isTop = (arg) -> arg is window

  inspect = do ->
    {toString} = Object::
    return (arg) ->
      str = toString.call arg
      switch str.slice(8, -1).toLowerCase()

        when 'null' then 'null'
        when 'undefined' then 'undefined'
        when 'array' then JSON.stringify(arg)

        when 'object'
          ctr = arg.constructor
          if !ctr or ctr is Object
          then JSON.stringify(arg, null, 2)
          else str

        when 'regexp' then arg.toString()
        when 'date' then arg.toISOString()
        else str

  createWriter = (stream, label) ->
    if typeof stream is 'function'
      stream = write: stream

    return ($1, ...args) ->

      if typeof $1 isnt 'string'
        args.unshift $1
        $1 = ''

      if $0 = getPrefix this, label
        $1 = $0 + ' ' + $1

      if @_debugId
        $1 = '%c' + @_debugId + '%c ' + $1
        args.unshift @_debugStyle, ''

      stream.write $1, ...args
      return

  methods.warn =
    if !NO_WARNINGS
    then createWriter console.warn
    else undef

  methods.error =
    createWriter console.error

  if !isQuiet
    methods.write = createWriter console.log
    methods.clear = console.clear


if isQuiet or !(DEBUG = env.DEBUG)
  methods.debug = (id) ->
    inst = createLog.call(this).prefix log.coal(id)
    inst.write = undef
    inst

else if hasFlag('--debug') or /^(\*|1)$/.test DEBUG
  methods.debug = (id) ->
    createLog.call(this).prefix log.coal(id)

else do ->
  DEBUG = DEBUG.replace(/\*/g, '.*').replace(/,/g, '|')
  DEBUG = new RegExp '^(' + DEBUG + ')$'
  methods.debug =

    if isCLI then (id) ->
      inst = createLog.call(this).prefix log.coal(id)
      inst.write = undef if !DEBUG.test(id)
      inst

    else do ->
      themes = [
        {text: '#2923EB', bkg: '#E2E1F5'}  # blue
        {text: '#D61160', bkg: '#EDDAE2'}  # red
        {text: '#8A8AE5', bkg: '#1B1B4C'}  # dark blue
        {text: '#67E591', bkg: '#0C4652'}  # dark green
      ]
      return (id) ->
        inst = createLog.call(this)
        inst.write = undef if !DEBUG.test(id)
        theme = themes[Math.floor Math.random() * themes.length]
        def inst, '_debugId', value: id
        def inst, '_debugStyle', value: """
          color: #{theme.text}; background: #{theme.bkg}; \
          border-radius: 3px; padding: 2px;
        """

join = (a, b) ->
  if !a then b or ''
  else if !b then a
  else a + ' ' + b

getPrefix = (self, label) ->

  if prefix = self._prefix
    prefix = prefix()

  if parent = self._parent
    prefix = getPrefix parent, prefix

  if label and prefix
  then join prefix, label
  else label or prefix or ''

if isQuiet
  methods.prefix = -> this
else
  colorize methods, !NO_COLOR
  methods.prefix = (prefix) ->
    def this, '_prefix',
      value: typeof prefix is 'function' and prefix or -> prefix
      configurable: true


# Ensure all expected methods exist.
# Warnings and errors are not disabled by --quiet
Object.assign quiet, methods

# Quiet overrides
quiet.write = undef
quiet.prefix = muted
quiet.clear = undef

# Ignore any property mutation.
Object.freeze quiet


if isQuiet
  log = -> # no-op
  Object.assign log, quiet
else
  log = createLog()


if isCLI then try
  cleanStack = require 'clean-stack'

# override this to customize log.trace() output
log.cleanStack = cleanStack or (stack) -> stack


Object.defineProperty log, 'default', value: log
module.exports = log
