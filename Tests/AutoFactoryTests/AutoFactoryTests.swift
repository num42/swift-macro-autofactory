import MacroTester
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(AutoFactoryMacros)
  import AutoFactoryMacros

  let testMacros: [String: Macro.Type] = [
    "AutoFactory": AutoFactoryMacro.self
  ]

  @Suite struct AutoFactoryTests {
    @Test func autoFactoryInCounterCoordinator() {
      MacroTester.testMacro(macros: testMacros)
    }

    @Test func autoFactoryInChildViewModel() {
      MacroTester.testMacro(macros: testMacros)
    }
  }
#endif
