import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DIPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProvidesMacro.self,
        AutoInjectMacro.self,
        InjectMacro.self,
        InitArgMacro.self
    ]
}
