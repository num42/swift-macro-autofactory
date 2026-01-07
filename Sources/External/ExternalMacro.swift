/// A type-attached member macro that generates a nested `Factory` for the annotated class.
///
/// Use `@AutoFactory` on a class that declares a nested `Dependencies` struct and initializers that
/// accept a parameter named `dependencies` of that type. For each initializer, the macro generates a
/// corresponding `generate(...)` method on `ClassName.Factory` that forwards non-dependency parameters
/// and injects dependencies. The macro also generates a `register(in:scope:)` helper to integrate with
/// a dependency container by resolving each dependency from the container.
///
/// Requirements
/// - The declaration must be a `class`.
/// - The class must declare `struct Dependencies` whose stored properties list all dependencies to resolve.
/// - Each initializer to expose must include a parameter named `dependencies: ClassName.Dependencies`.
/// - Your project must provide `DependencyContainer`, `ComponentScope`, and `container.resolve()` APIs.
///
/// Example
/// ```swift
/// @AutoFactory
/// final class CounterCoordinator {
///   struct Dependencies {
///     let repository: Repository
///     let analytics: Analytics
///   }
///
///   init(dependencies: Dependencies, startCount: Int) { /* ... */ }
/// }
///
/// // Register once in your composition root
/// let container = DependencyContainer()
/// CounterCoordinator.Factory.register(in: container)
///
/// // Resolve the factory and build instances
/// let factory: CounterCoordinator.Factory = container.resolve()
/// let coordinator = factory.generate(startCount: 0)
/// ```
///
/// Generated API (simplified)
/// ```swift
/// public final class CounterCoordinator {
///   public final class Factory {
///     public init(dependencies: Dependencies)
///     public func generate(startCount: Int) -> CounterCoordinator
///     public static func register(in container: DependencyContainer,
///                                 scope: ComponentScope = .shared)
///   }
/// }
/// ```
///
/// Notes
/// - One `generate` overload is created for each initializer found on the class.
/// - The `dependencies` parameter is omitted from `generate` signatures and supplied automatically.
@attached(member, names: arbitrary)
public macro AutoFactory() =
  #externalMacro(
    module: "AutoFactoryMacros",
    type: "AutoFactoryMacro"
  )

