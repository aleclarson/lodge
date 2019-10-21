type Logger = ILogger & IColored

interface ILogger {
  (...args: any[]): void
  warn(...args: any[]): void
  error(...args: any[]): void
  debug(id: string): Logger
  prefix(prefix: string): this
  stylize(...args: any[]): string
  trace(): void
  clear(): void
}

interface IColored {
  red(str: string): string
  blue(str: string): string
  green(str: string): string
  yellow(str: string): string
  cyan(str: string): string
  pink(str: string): string
  lred(str: string): string
  lblue(str: string): string
  lgreen(str: string): string
  lyellow(str: string): string
  lcyan(str: string): string
  lpink(str: string): string
  white(str: string): string
  silver(str: string): string
  gray(str: string): string
  coal(str: string): string
  black(str: string): string
  bold(str: string): string
}

declare module 'lodge' {
  const log: Logger & {
    cleanStack: (stack: string) => string
  }
  export default log
}
