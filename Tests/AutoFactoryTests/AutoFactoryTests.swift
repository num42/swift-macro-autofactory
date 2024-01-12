import MacroTester
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(AutoFactoryMacros)
  import AutoFactoryMacros

  let testMacros: [String: Macro.Type] = [
    "AutoFactory": AutoFactoryMacro.self
  ]
#endif

final class AutoFactoryTests: XCTestCase {
  func testAutoFactoryInCounterCoordinator() throws {
    testMacro(macros: testMacros)
  }

  func testAutoFactoryInChildViewModel() throws {
    testMacro(macros: testMacros)
  }
}
