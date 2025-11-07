import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Swinject

// MARK: - @Provides Macro
// This macro will be a member macro.
// It generates an inner class which implements DependencyAssembly protocol to inject itself to Swinject
public struct ProvidesMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let typeName: String
        switch declaration {
        case let decl as ClassDeclSyntax:
            typeName = decl.name.text
        case let decl as StructDeclSyntax:
            typeName = decl.name.text
        case let decl as ActorDeclSyntax:
            typeName = decl.name.text
        default:
            throw ProvidesMacroError.unsupportedType
        }

        // --- Parse macro arguments ---
        guard let args = node.arguments,
              case let .argumentList(argList) = args else {
            throw ProvidesMacroError.invalidArgument
        }

        var scopeExpr: ExprSyntax = "ObjectScope.graph"
        var protocolExpr: ExprSyntax?
        var nameExpr: ExprSyntax?
        var argExprs: [ExprSyntax] = []

        for (index, arg) in argList.enumerated() {
            let expr = arg.expression
            switch index {
            case 0:
                if expr.description.contains("ObjectScope") {
                    scopeExpr = expr
                } else {
                    throw ProvidesMacroError.invalidArgument
                }
            case 1:
                if expr.description.hasSuffix(".self") {
                    protocolExpr = expr
                } else {
                    throw ProvidesMacroError.invalidArgument
                }
            case 2:
                // Accept any expression for name (string literal, function call, nil, etc.)
                if expr.is(NilLiteralExprSyntax.self) {
                    // name = nil → no registration name
                    nameExpr = nil
                } else {
                    nameExpr = expr
                }
            default:
                // Accept any expression for extra arguments
                argExprs.append(expr)
            }
        }

        guard let proto = protocolExpr else {
            throw ProvidesMacroError.invalidArgument
        }

        let assemblyName = "\(typeName)Assembly"
        let nameClause = nameExpr != nil ? ", name: \(nameExpr!)" : ""

        // --- Build closure parameters and initializer call ---
        let closureParams: String
        let initCall: String

        if argExprs.isEmpty {
            closureParams = "_"
            initCall = "\(typeName)()"
        } else {
            // Convert string literals to identifiers
            let paramNames = argExprs.compactMap { expr -> String? in
                guard let literal = expr.as(StringLiteralExprSyntax.self),
                      let firstSegment = literal.segments.first?.description else { return nil }
                return firstSegment.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }

            closureParams = "(_," + paramNames.joined(separator: ", ") + ")"
            initCall = "\(typeName)(" + paramNames.map { "\($0): \($0)" }.joined(separator: ", ") + ")"
        }

        // --- Generate assembly class ---
        let generatedClass: DeclSyntax = """
        public class \(raw: assemblyName): DependencyAssembly {
            public static let identifier: String = "\(raw: assemblyName)"

            public static func assemble() {
                let container = DependencyInjection.shared.container
                container.register(\(proto)\(raw: nameClause)) { \(raw: closureParams) in
                    \(raw: initCall)
                }.inObjectScope(\(scopeExpr))
            }
        }
        """

        return [generatedClass]
    }

    enum ProvidesMacroError: CustomStringConvertible, Error {
        case invalidArgument
        case unsupportedType

        var description: String {
            switch self {
            case .invalidArgument:
                return "@Provides macro requires ObjectScope, protocol type, optional name, and optional extra arguments as expressions."
            case .unsupportedType:
                return "@Provides macro can only be applied to classes, structs, or actors."
            }
        }
    }
}
