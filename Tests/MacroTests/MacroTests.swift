internal import MacroTester
internal import SwiftSyntaxMacros
internal import SwiftSyntaxMacrosTestSupport
internal import Testing

#if canImport(AutoFactoryMacros)
  import AutoFactoryMacros

  let testMacros: [String: Macro.Type] = [
    "AutoFactory": AutoFactoryMacro.self
  ]

  @Suite
  struct AutoFactoryMacroTests {
    @Test func autoFactoryInCounterCoordinator() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func autoFactoryInChildViewModel() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
