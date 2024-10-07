import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoFactoryMacro: MemberMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    let className = declaration.as(ClassDeclSyntax.self)!.name.description

    let initializers = declaration
      .as(ClassDeclSyntax.self)!
      .memberBlock
      .members
      .compactMap { $0.decl.as(InitializerDeclSyntax.self) }

    let parametersArray = initializers.map {
      $0.signature.parameterClause.parameters
        .map { (name: $0.firstName.text, type: $0.type.description) }
    }

    let dependencyNames = declaration.as(ClassDeclSyntax.self)!.memberBlock.members
      .compactMap {
        $0.decl.as(StructDeclSyntax.self)
      }
      .first {
        $0.name.text == "Dependencies"
      }!
      .memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self)?
        .bindings
        .compactMap { $0.pattern.description }
      }
      .reduce([], +)

    let generators = parametersArray.map { parameters in
      let publicParameters = parameters
        .filter { $0.name != "dependencies" }

      let signature = publicParameters.isEmpty
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

    let dependenciesString =
      dependencyNames.map {
        $0.appending(": container.resolve()")
      }
      .joined(separator: ",\n")
      .indentedBy("          ")

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

@main
struct AutoFactoryPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    AutoFactoryMacro.self
  ]
}

extension String {
  func indentedBy(_ indentation: String) -> String {
    split(separator: "\n").joined(separator: "\n" + indentation)
  }
}
