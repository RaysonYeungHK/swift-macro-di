import Foundation
import ObjectiveC

public class DependencyInjection: @unchecked Sendable {
    public static let shared = DependencyInjection()
    public let container = Container()

    @MainActor public func initialize() {
        let assemblies = allDependencyAssemblies()
        for assembly in assemblies {
            #if DEBUG
            print("Processing \(assembly.identifier)")
            #endif
            assembly.assemble()
        }
    }
    
    /// Using objective-c runtime to gather all implement of protocol DependencyAssembly
    /// We don't need to manually add implementation one by one
    func allDependencyAssemblies() -> [DependencyAssembly.Type] {
        var count: UInt32 = 0
        guard let classList = objc_copyClassList(&count) else { return [] }
        defer { free(UnsafeMutableRawPointer(classList)) } // proper free

        var result: [DependencyAssembly.Type] = []
        
        let classes = UnsafeBufferPointer(start: classList, count: Int(count))
        
        for cls in classes {
            if class_conformsToProtocol(cls, DependencyAssembly.self),
                let typedClass = cls as? DependencyAssembly.Type {
                result.append(typedClass)
            }
        }

        return result
    }
}
