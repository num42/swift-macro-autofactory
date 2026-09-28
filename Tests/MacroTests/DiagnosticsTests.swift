internal import SwiftSyntaxMacrosGenericTestSupport
internal import Testing

#if canImport(AutoFactoryMacros)
  import AutoFactoryMacros

  @Suite
  struct AutoFactoryDiagnosticsTests {
    @Test func structThrowsError() {
      assertMacroExpansion(
        """
        @AutoFactory
        struct NotAClass {
          struct Dependencies {
            let service: Service
          }

          init(dependencies: Dependencies) {}
        }
        """,
        expandedSource: """
          struct NotAClass {
            struct Dependencies {
              let service: Service
            }

            init(dependencies: Dependencies) {}
          }
          """,
        diagnostics: [
          .init(
            message: AutoFactoryMacro.MacroDiagnostic.requiresClass.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func missingDependenciesStructThrowsError() {
      assertMacroExpansion(
        """
        @AutoFactory
        final class MissingDependencies {
          init(dependencies: Dependencies) {}
        }
        """,
        expandedSource: """
          final class MissingDependencies {
            init(dependencies: Dependencies) {}
          }
          """,
        diagnostics: [
          .init(
            message: AutoFactoryMacro.MacroDiagnostic.requiresDependencies.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }

    @Test func missingDependenciesInitializerThrowsError() {
      assertMacroExpansion(
        """
        @AutoFactory
        final class MissingDependenciesParameter {
          struct Dependencies {
            let service: Service
          }

          init() {}
        }
        """,
        expandedSource: """
          final class MissingDependenciesParameter {
            struct Dependencies {
              let service: Service
            }

            init() {}
          }
          """,
        diagnostics: [
          .init(
            message: AutoFactoryMacro.MacroDiagnostic.requiresDependenciesInitializer.message,
            line: 1,
            column: 1
          )
        ],
        macros: testMacros
      )
    }
  }
#endif
