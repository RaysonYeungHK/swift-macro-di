import SwiftCompilerPlugin
import SwiftSyntaxMacros
import Swinject

// Macro to register implementation to Swinject
@attached(member, names: arbitrary)
public macro Provides(
    _ scope: ObjectScope = ObjectScope.graph,
    _ protocolType: Any.Type,
    _ name: String? = nil,
    _ arguements: String...
) = #externalMacro(
    module: "MacroDIPlugin",
    type: "ProvidesMacro"
)

// Macro to generate constructor init() function with pre-defined dependency and necessary arguments
@attached(member, names: named(init))
public macro AutoInject() = #externalMacro(
    module: "MacroDIPlugin",
    type: "AutoInjectMacro"
)

// Macro to indicate dependency maybe found by Swinject
@attached(peer, names: arbitrary)
public macro Inject(
    _ protocolType: Any.Type,
    _ name: String? = nil,
    _ arguments: Any...
) = #externalMacro(
    module: "MacroDIPlugin",
    type: "InjectMacro",
)

// Macro to indicate property is needed as argument of constructor init()
@attached(peer, names: arbitrary)
public macro InitArg() = #externalMacro(
    module: "MacroDIPlugin",
    type: "InitArgMacro",
)
