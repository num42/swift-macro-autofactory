import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implements the `@AutoFactory` macro: a type-attached member macro that synthesizes a nested
/// `Factory` type for the annotated class.
///
/// When applied to a class that defines a nested `Dependencies` struct and initializers that
/// include a `dependencies` parameter of that type, the macro:
/// - Generates one `generate(...)` method per initializer that forwards all non-`dependencies`
///   parameters and supplies the `dependencies` automatically.
/// - Emits a static `register(in:scope:)` helper that constructs and registers a `Factory` in a
///   dependency container by resolving each property of `Dependencies` via `container.resolve()`.
///
/// Preconditions
/// - The declaration must be a `class`.
/// - The class must declare `struct Dependencies` with stored properties for each dependency.
/// - Each initializer that should be exposed must include a parameter named
///   `dependencies: ClassName.Dependencies`.
///
/// Notes
/// - This implementation currently assumes these preconditions and uses force-unwraps; misuse
///   will result in a trap during expansion. Future improvements can replace these with proper
///   diagnostics emitted via `MacroExpansionContext`.
///
/// See also: The public `AutoFactory` macro declaration in `ExternalMacro.swift`.
public struct AutoFactoryMacro: MemberMacro {
  /// Expands `@AutoFactory` for the given declaration by synthesizing a nested `Factory` class.
  ///
  /// - Parameters:
  ///   - node: The attribute that triggered expansion. Not used directly.
  ///   - declaration: The declaration annotated with `@AutoFactory`. Expected to be a `ClassDeclSyntax`.
  ///   - protocols: Protocols the type is conforming to. Not used.
  ///   - context: The macro expansion context. Not used at the moment.
  /// - Returns: An array containing a single `DeclSyntax` that represents the nested `Factory` class.
  /// - Throws: Currently does not throw intentionally, but the signature reserves the right to throw
  ///   once diagnostics are introduced.
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

    let className = declaration.as(ClassDeclSyntax.self)!.name.description

    let initializers =
      declaration
      .as(ClassDeclSyntax.self)!
      .memberBlock
      .members
      .compactMap { $0.decl.as(InitializerDeclSyntax.self) }

    let parametersArray = initializers.map {
      $0.signature.parameterClause.parameters
        .map { (name: $0.firstName.text, type: $0.type.description) }
    }

    // Locate nested `Dependencies` and collect property names (force-unwrap assumes it exists).
    let dependencyNames = declaration.as(ClassDeclSyntax.self)!.memberBlock.members
      .compactMap {
        $0.decl.as(StructDeclSyntax.self)
      }
      .first {
        $0.name.text == "Dependencies"
      }!
      .memberBlock.members.compactMap {
        $0.decl.as(VariableDeclSyntax.self)?
          .bindings
          .compactMap { $0.pattern.description }
      }
      .reduce([], +)

    let generators = parametersArray.map { parameters in
      let publicParameters =
        parameters
        .filter { $0.name != "dependencies" }

      let signature =
        publicParameters.isEmpty
        ? "public func generate() -> \(className)"
        : """
        public func generate(
          \(publicParameters.map { "\($0.name): \($0.type)" }.joined(separator: ",\n    "))
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

    let generatorsString = generators.map { $0.indentedBy("    ") }
      .joined(separator: "\n\n")

    // Map each dependency to a `name: container.resolve()` pair used inside `register(...)`.
    let dependenciesString =
      dependencyNames.map {
        $0 + (": container.resolve()")
      }
      .joined(separator: ",\n")
      .indentedBy("          ")

    // Emit the nested `Factory` class with initializer, `generate(...)` methods, and `register(...)`.
    return [
      DeclSyntax(
        extendedGraphemeClusterLiteral: """
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
      )
    ]
  }
}
