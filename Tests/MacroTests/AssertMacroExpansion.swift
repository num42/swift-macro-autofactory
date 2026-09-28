internal import SwiftSyntaxMacroExpansion
internal import SwiftSyntaxMacros
internal import SwiftSyntaxMacrosGenericTestSupport
internal import Testing

/// Swift Testing variant of `assertMacroExpansion`.
///
/// The variant from `SwiftSyntaxMacrosTestSupport` reports failures through XCTest,
/// which Swift Testing does not treat as test failures.
func assertMacroExpansion(
  _ originalSource: String,
  expandedSource: String,
  diagnostics: [DiagnosticSpec] = [],
  macros: [String: Macro.Type],
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) {
  SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
    originalSource,
    expandedSource: expandedSource,
    diagnostics: diagnostics,
    macroSpecs: macros.mapValues { MacroSpec(type: $0) },
    failureHandler: { spec in
      Issue.record(
        Comment(rawValue: spec.message),
        sourceLocation: SourceLocation(
          fileID: spec.location.fileID,
          filePath: spec.location.filePath,
          line: spec.location.line,
          column: spec.location.column
        )
      )
    },
    fileID: fileID,
    filePath: filePath,
    line: line,
    column: column
  )
}
