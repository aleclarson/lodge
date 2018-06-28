# lodge v0.0.3

```js
const log = require('lodge');

// simplest case
log('hello world');

// multiple arguments
log('hello', 'world');

// non-strings are pretty-printed
log('object:', { hello: 'world' });

// first argument can be a format string
log('string: %s, integer: %i, float: %f, object: %O', 'foo', 1.1, 1.1, { hello: 'world' });

// ansi colors included
log(log.red('CODE RED'));

// warnings
log.warn('be careful');

// print to stderr
log.error('oh crap');

// namespaces
const log2 = log.debug('foo');

// must set DEBUG=1 or DEBUG=foo to see this
log2('something useful in debugging');

// DEBUG=1 is not required to see warnings/errors
log2.warn('foo is deprecated');
```

The built-in `console` functions are used when the global `window` variable exists. Otherwise, functions with similar behavior are used with the `process.stdout` or `process.stderr` streams.

### Environment variables

Use `QUIET=1` to disable all messages. The `--quiet` CLI flag also works.

The `DEBUG` environment variable is flexible. `DEBUG=1` enables all debug logs. The asterisk (`*`) allows for globbing. For example, `a*` matches both `abc` and `acb` but not `cba`. The comma (`,`) lets you specify multiple globs. The `--debug` CLI flag is identical to `DEBUG=1`.

Use `NO_COLOR=1` to disable ANSI colors. The `--no-color` CLI flag also works.

Use `NO_WARNINGS=1` to disable warning messages. The `--no-warnings` CLI flag also works.

Use `TRACE_WARNINGS=1` to attach a stack trace to each warning.

For browser environments, you can set these properties on the `window` object before importing this library.

### Colors

The following ANSI colors are available: (256 color spectrum)
- red
- blue
- green
- yellow
- cyan
- pink
- white
- silver
- gray
- coal
- black

The non-grayscale colors all have light variants available as `lred`, `lblue`, `lgreen`, etc.

### Prefixes

You can set the `prefix` method of the main logger (or a namespace) if you want to prepend a string to every message.

```js
const foo = log.debug('foo');
foo.prefix = () => `[${new Date().toISOString()}] foo:`

foo('test') // => '[2018-06-28T20:03:48.892Z] foo: test'
```

