internal import SwiftCompilerPlugin
internal import SwiftSyntaxMacros

@main
struct AutoFactoryPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    AutoFactoryMacro.self
  ]
}
