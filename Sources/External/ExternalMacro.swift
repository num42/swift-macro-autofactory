@attached(member, names: named(Factory))
public macro AutoFactory() =
  #externalMacro(
    module: "AutoFactoryMacros",
    type: "AutoFactoryMacro"
  )
