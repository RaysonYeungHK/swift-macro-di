import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - @AutoInject Macro
// This macro will be a member macro.
// It detects @Inject, @InitArg macros and generate constructor init()
public struct AutoInjectMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // --- Support class, struct, actor ---
        let typeDecl: SyntaxProtocol
        let typeName: String
        let members: MemberBlockItemListSyntax

        if let decl = declaration.as(ClassDeclSyntax.self) {
            typeDecl = decl
            typeName = decl.name.text
            members = decl.memberBlock.members
        } else if let decl = declaration.as(StructDeclSyntax.self) {
            typeDecl = decl
            typeName = decl.name.text
            members = decl.memberBlock.members
        } else if let decl = declaration.as(ActorDeclSyntax.self) {
            typeDecl = decl
            typeName = decl.name.text
            members = decl.memberBlock.members
        } else {
            throw AutoInjectMacroError.unsupportedType
        }

        var parameters: [String] = []
        var assignments: [String] = []

        for member in members {
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                !varDecl.modifiers.contains(where: { $0.name.text == "static" }),
                let binding = varDecl.bindings.first,
                let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                let typeAnnotation = binding.typeAnnotation
            else { continue }

            let name = pattern.identifier.text
            let type = typeAnnotation.type.description.trimmingCharacters(in: .whitespaces)

            let attributes = varDecl.attributes

            // Detect @Inject attribute
            let injectAttr = attributes.first(where: {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "Inject"
            })?.as(AttributeSyntax.self)

            // Detect @InitArg attribute
            let initArgAttr = attributes.first(where: {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "InitArg"
            })?.as(AttributeSyntax.self)

            if let injectAttr,
               case let .argumentList(args) = injectAttr.arguments {
                // --- Case 1: @Inject(...) ---
                // Parse Inject arguments
                var protocolTypeExpr: String?
                var nameExpr: String?
                var extraArgs: [String] = []

                for (i, arg) in args.enumerated() {
                    let text = arg.expression.description.trimmingCharacters(in: CharacterSet.whitespaces)
                    if i == 0 { protocolTypeExpr = text } else if i == 1 { nameExpr = text } else { extraArgs.append(text) }
                }

                let nameClause = (nameExpr == nil || nameExpr == "nil")
                    ? ""
                    : ", name: \(nameExpr!)"

                let argsClause: String
                if extraArgs.isEmpty {
                    argsClause = ""
                } else if extraArgs.count == 1 {
                    argsClause = ", argument: \(extraArgs[0])"
                } else {
                    argsClause = ", arguments: \(extraArgs.joined(separator: ", "))"
                }

                // Example: DependencyInjection.shared.container.resolve(Drink.self, name: "sweet", arguments: size, sugar)
                let resolveExpr =
                    "DependencyInjection.shared.container.resolve(\(protocolTypeExpr ?? type)\(nameClause)\(argsClause))"

                // Optional vs non-optional injection
                if type.hasSuffix("?") {
                    parameters.append("\(name): \(type) = \(resolveExpr)")
                } else {
                    parameters.append("\(name): \(type) = \(resolveExpr)!")
                }
            } else if initArgAttr != nil {
                // --- Case 2: @InitArg ---
                // Not injected → must be passed manually
                parameters.append("\(name): \(type)")
            } else {
                // --- Case 3: Others (ignored) ---
                continue
            }

            assignments.append("self.\(name) = \(name)")
        }

        let paramList = parameters.joined(separator: ",\n        ")
        let assignList = assignments.joined(separator: "\n        ")

        let initDecl: DeclSyntax = """
        public init(
            \(raw: paramList)
        ) {
            \(raw: assignList)
        }
        """

        return [initDecl]
    }

    enum AutoInjectMacroError: CustomStringConvertible, Error {
        case unsupportedType

        var description: String {
            switch self {
            case .unsupportedType:
                return "@AutoInject macro can only be applied to classes, structs, or actors."
            }
        }
    }
}

// MARK: - @Inject Macro
// This macro will be a peer macro.
// It doesn't generate code directly for the property it's attached to, but it creates a synthetic member that the InitInject macro can later inspect.
public struct InjectMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // We don't want @Inject to directly modify the property.
        // Instead, it can generate a "marker" property that the
        // @InitInject class macro can find.
        // For simplicity, we'll assume @InitInject directly inspects @Inject attributes.
        // If we needed to pass more complex data, generating a private static var
        // with the metadata (e.g., protocolType, name) would be an option.
        // For this specific case, the InitInject macro can directly read the Inject attributes.
        return [] // No peer declarations needed for this approach.
    }
}

// MARK: - @InitArg Macro
// This macro will be a peer macro.
// It doesn't generate code directly for the property it's attached to, but it creates a synthetic member that the InitInject macro can later inspect.
public struct InitArgMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // We don't want @InitArg to directly modify the property.
        // Instead, it can generate a "marker" property that the
        // @InitInject class macro can find.
        // For simplicity, we'll assume @InitInject directly inspects @Inject attributes.
        // If we needed to pass more complex data, generating a private static var
        // with the metadata (e.g., protocolType, name) would be an option.
        // For this specific case, the InitInject macro can directly read the Inject attributes.
        return [] // No peer declarations needed for this approach.
    }
}
