internal import MacroHelper
public import SwiftDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacros

public struct AutoFactoryMacro: MemberMacro {
  public enum MacroDiagnostic: String, DiagnosticMessage {
    case requiresClass = "#AutoFactory requires a class"
    case requiresDependencies = "#AutoFactory requires a nested Dependencies struct"
    case requiresDependenciesInitializer =
      "#AutoFactory requires initializers with a dependencies parameter"

    public var message: String { rawValue }

    public var diagnosticID: MessageID {
      MessageID(domain: "AutoFactory", id: rawValue)
    }

    public var severity: DiagnosticSeverity { .error }
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    /*
     Expansion algorithm (high level):
    
     1. Extract the class name.
     2. Collect all initializers declared directly in the class.
     3. For each initializer, capture its parameter list (name and type).
     4. Find a nested `struct Dependencies` and collect its stored property names. These are treated
        as dependency identifiers to be resolved from a container.
     5. For each initializer, synthesize a `generate(...)` method that forwards all parameters,
        omitting the `dependencies` parameter from the public signature.
     6. Build a `register(in:scope:)` helper that constructs `Dependencies` by calling
        `container.resolve()` for each dependency and registers the resulting `Factory`.
     7. Return a single nested `Factory` class containing the initializer, the generated methods,
        and the `register(in:scope:)` helper.
    
     Assumptions:
     - The declaration is a class and contains a nested `Dependencies` struct with stored properties.
     - Initializers include a parameter named `dependencies` of the appropriate type.
    */

    guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
      let diagnostic = Diagnostic(
        node: Syntax(node),
        message: MacroDiagnostic.requiresClass
      )
      context.diagnose(diagnostic)
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    let initializers =
      classDeclaration
      .memberBlock
      .members
      .compactMap { $0.decl.as(InitializerDeclSyntax.self) }

    let parametersArray = initializers.map {
      $0.signature.parameterClause.parameters
        .map { (name: $0.firstName.text, type: $0.type.description) }
    }

    guard
      parametersArray.allSatisfy({ parameters in
        parameters.contains { $0.name == "dependencies" }
      })
    else {
      let diagnostic = Diagnostic(
        node: Syntax(node),
        message: MacroDiagnostic.requiresDependenciesInitializer
      )
      context.diagnose(diagnostic)
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    // Locate nested `Dependencies` and collect property names (force-unwrap assumes it exists).
    guard
      let dependenciesDeclaration = classDeclaration.memberBlock.members
        .compactMap({ $0.decl.as(StructDeclSyntax.self) })
        .first(where: { $0.name.text == "Dependencies" })
    else {
      let diagnostic = Diagnostic(
        node: Syntax(node),
        message: MacroDiagnostic.requiresDependencies
      )
      context.diagnose(diagnostic)
      throw DiagnosticsError(diagnostics: [diagnostic])
    }

    let dependencyNames = dependenciesDeclaration.memberBlock.members.compactMap {
      $0.decl.as(VariableDeclSyntax.self)?
        .bindings
        .compactMap { $0.pattern.description }
    }
    .reduce([], +)

    let className = classDeclaration.name.description

    let generators = parametersArray.map { parameters in
      let publicParameters =
        parameters
        .filter { $0.name != "dependencies" }

      let signature =
        publicParameters.isEmpty
        ? "public func generate() -> \(className)"
        : """
        public func generate(
          \(publicParameters.map { "\($0.name): \($0.type)" }.joined(separator: ",\n  "))
        ) -> \(className)
        """

      return """
        \(signature) {
          \(className)(
            \(parameters.map { "\($0.name): \($0.name)" }.joined(separator: ",\n    "))
          )
        }
        """
    }

    let generatorsString =
      generators
      .map { $0.indentedBy("  ") }
      .joined(separator: "\n\n")

    // Map each dependency to a `name: container.resolve()` pair used inside `register(...)`.
    let dependenciesString =
      dependencyNames
      .map { $0 + (": container.resolve()") }
      .joined(separator: ",\n")
      .indentedBy("          ")

    let factoryString = """
      public final class Factory {
        public init(dependencies: \(className).Dependencies) {
          self.dependencies = dependencies
        }
        
          \(generatorsString)
        
        let dependencies: \(className).Dependencies
        
        public static func register(
          in container: DependencyContainer,
          scope: ComponentScope = .shared
        ) {
          container.register(scope) {
            try \(className).Factory(
              dependencies: \(className).Dependencies(
      \(dependenciesString)
              )
            )
          }
        }
      }
      """

    // Emit the nested `Factory` class with initializer, `generate(...)` methods, and `register(...)`.
    return [
      DeclSyntax(stringLiteral: factoryString).trimmed
    ]
  }
}
