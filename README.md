# AutoFactory Macro
A Swift macro that generates a nested `Factory` for a class, producing convenient `generate(...)`
methods and a registration helper for dependency injection.

## Overview

Annotate a class with `@AutoFactory` and declare a nested `Dependencies` struct. For each
initializer that accepts `dependencies: Dependencies`, the macro synthesizes a corresponding
`generate(...)` method that forwards non-dependency parameters and injects the dependencies.
It also emits a `register(in:scope:)` helper to integrate with a dependency container.

```swift
import AutoFactory

@AutoFactory
final class CounterCoordinator {
  struct Dependencies {
    let repository: Repository
    let analytics: Analytics
  }

  init(dependencies: Dependencies, startCount: Int) { /* ... */ }
}

let container = DependencyContainer()
CounterCoordinator.Factory.register(in: container)
let factory: CounterCoordinator.Factory = container.resolve()
let coordinator = factory.generate(startCount: 0)

