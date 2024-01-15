@attached(member, names: arbitrary)
public macro AutoFactory() = #externalMacro(
  module: "AutoFactoryMacros",
  type: "AutoFactoryMacro"
)
