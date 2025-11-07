import Foundation

// Protocol to expose functions and allow Objective-C runtime to detect implementation
@objc
@MainActor
public protocol DependencyAssembly: AnyObject {
    @MainActor
    static var identifier: String { get }
    @MainActor
    static func assemble()
}

