# Swift Macro - Dependency Injection (DI)

A macro annotation to speed up implementation of using Swinject for dependency injection.

### Overview

[Swinject](https://github.com/Swinject/Swinject) is commonly used for dependency injection in Swift development.

According to Swinject documentation, there are 2 different steps.

1. Register

```swift
defaultContainer.register(Animal.self) { _ in Cat(name: "Mimi") }
```

2. Resolve

```swift
let animal = defaultContainer.resolve(Animal.self)
```

On top, there was an idea `Assembler` / `Assembly` to further organize implementations of lots of dependencies.

https://ali-akhtar.medium.com/ios-dependency-injection-using-swinject-9c4ceff99e41

However, to maintain `Assembly` and `Assembler`, it is still a nightmare, especially for huge project.

### Idea / Solution

Inspried by Dagger2 / Hilt, using macro / annotation to simplify `register` and `resolve`.

1. `register` with single annotation
   It generates `Assembly` implement

```swift
@Provides(ObjectScope.graph, Animal.self)
class Cat : Animal {
    // Start Generated Code
    class CatAssmembly : Assembly {
        func assemble() {
            Assembler.....register(Animal.self) { Cat() }
                .inObjectScope(ObjectScope.graph)
        }
    }
    // End Generated Code
}
```

2. `resolve` with 2 annotations
   It generates constructor `init()` with default arguments
   
   Constructor injection is used here, instead of property injection.
   P.S. There are lots of discussions online, simply search `property injection vs constructor injection`

```swift
@AutoInject
class Consumer {
    @Inject(Animal.self)
    let animal: Animal
    // Start Generated Code
    init(
        animal: Animal = Assembler.....resolve(Animal.self)
    ) {
        self.animal = animal
    }
    // End Generated Code
}

```

3. Maintain `Assembler` by Objective-C runtime
   
   Since all implement of `Assembly` could be detected by Objective-C runtime, it is not necessary to explicitly maintain `Assembler`
   
   P.S. Even there is a bit overhead for startup time, it is still acceptable and worth to do it.

```swift
class Assembler {
    func init() {
        let assembles = getAssembles()
        for assembly in assemblies {
            assembly.assemble()
        }
    }
}
```

### Additional Advantages

Since `register` and `resolve` are no longer required to implement explicitly, injection of dependency becomes plug-and-play style.

It can achieve my previous [Android Modularization](https://github.com/RaysonYeungHK/Android-Modularization) idea in Swift.

### How to use

1. You can either clone this reporitory to yours or import via SPM

2. For SPM, please checkout [Swift packages | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/swift-packages)

For you code implementation, you just need to import this package and use it

Example:

```swift
import MacroDI

@Provides(ObjectScope.container, Animal.self)
class Cat : Animal {
    .....
}


@AutoInject
class Consumer {
    @Inject(Animal.self)
    let animal: Animal
}
```

### Support Cases

#### Register / Provides

```swift
// Basic Register
//
// register(Drink.self) { _ in
//     Water()
// }.inObjectScope(ObjectScope.container)
@Provides(ObjectScope.container, Drink.self)
class Water: Drink {
    ...
}

// Register with name
//
// register(Drink.self, name: "sweet") { _ in
//     Coke()
// }.inObjectScope(ObjectScope.container)
@Provides(ObjectScope.container, Drink.self, "sweet")
class Coke: Drink {
    ...
}

// Register with name and argument(s)
//
// register(Drink.self, name: "coffee") { (_, hasCaffine) in
//     Coffee(hasCaffeine: hasCaffeine)
// }.inObjectScope(ObjectScope.container)
@Provides(ObjectScope.container, Drink.self, "coffee", "hasCaffine")
class Coffee: Drink {
    let hasCaffeine: Bool
    init (hasCaffeine: Bool) {
        self.hasCaffeine = hasCaffeine
    }
    ...
}

// Register with no name but argument(s)
// 
// register(Drink.self, name: nil) { (_, secretLevel) in
//     SecretDrink(secretLevel: secretLevel)
// }.inObjectScope(ObjectScope.container)
@Provides(ObjectScope.container, Drink.self, nil, "secretLevel")
class SecretDrink: Drink {
    let secretLevel: Int
    init(secretLevel: Int) {
        self.secretLevel = secretLevel
    }
}
```

#### Resolve / Inject

```swift
// Basic Resolve
//
// resolve(Drink.self)
@AutoInject
class LunchMenu {
    @Inject(Drink.self)
    let drink: Drink
}

// Resolve ith name
//
// resolve(Drink.self, name: "sweet")
@AutoInject
class LunchMenu {
    @Inject(Drink.self, "sweet")
    let drink: Drink
}

// Resolve with name and argument(s)
//
// resolve(Drink.self, name: "coffee", argument: false)
@AutoInject
class LunchMenu {
    @Inject(Drink.self, "sweet")
    let drink: Drink
}

// Resolve with name and argument(s)
//
// resolve(Drink.self, argument: 10)
@AutoInject
class LunchMenu {
    @Inject(Drink.self, nil, 10)
    let drink: Drink
}

```

#### Additional cases for resolve / inject

In most of cases, we keep instance properties that cannot be injected, or just for own usage.

`@InitArg` is used to consider those scenarios

```swift
@AutoInject
class LunchMenu {
    @Inject(Drink.self)
    let drink: Drink
    // We want extra argument that not coming from dependency injection
    @InitArg
    let extraCharge: Int
    // We don't want to see this one in the constructor init()
    var sold: Int = 0

    // Start Generated Code
    init(
        drink: Drink = ...resolve(Drink.self),
        extraCharge: Int
    ) {
        self.drink = drink
        self.extraCharge = extraCharge
    }
    // End Generated Code
}
```

#### Combine register and resolve

```swift
@Provides(ObjectScope.container, Menu.self)
@AutoInject
class LunchMenu: Menu {
    @Inject(Drink.self)
    let drink: Drink

    // Start Generated Code
    init(
        drink: Drink = ...resolve(Drink.self)
    ) {
        self.drink = drink
    }

    class LunchMenuAssembly : Assembly {
        func assemble() {
            ...register(Menu.self) { _ in
                LunchMenu()
            }.inObjectScope(ObjectScope.container)
        }
    }
    // End Generated Code
}

```

### Unsupported Case / Known Issue

#### Parent(s) dependency injection

Due to nature of swift language, it is not efficient to trace inheritance of the class during code generation.

For example

```swift
class User {
    let readAccessor: ReadAccessor

    init(readAccessor: ReadAccessor) {
        self.readAccessor = readAccessor
    }
}

@AutoInject
class Editor: User {
    @Inject(WriteAccessor.self)
    let writeAccessor: WriteAccessor

    // Start Generated Code
    init(writeAccessor: WriteAccessor) {
        // Parent class need readAccessor, but we cannot detect it
        // super.init(readAccessor) also need to be called, but it is not generated
        self.writeAccessor = writeAccessor
    }
    // End Generated Code
}
```

### Support type

`class` , `struct` , `actor` are supported.

### Examples

More examples could be found in [Demo](https://github.com/RaysonYeungHK/swift-macro-di/tree/master/MacroDI/Sources/Demo)

### References

[GitHub - Swinject/Swinject: Dependency injection framework for Swift with iOS/macOS/Linux](https://github.com/Swinject/Swinject)

[iOS Dependency Injection Using Swinject](https://ali-akhtar.medium.com/ios-dependency-injection-using-swinject-9c4ceff99e41)

[Hilt](https://dagger.dev/hilt/)
