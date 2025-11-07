// If xcode -> Expand Macro doesn't work, then you need to "import MacroDI" explicitly
import MacroDI

class ClassDemo {
    /// Demo for @Provides
    protocol Drink {
        var name: String { get }
    }

    protocol Food {
        var name: String { get }
    }

    protocol Menu {
    }

    @Provides(ObjectScope.container, Drink.self)
    struct Water: Drink {
        let name: String = "Water"
    }

    @Provides(ObjectScope.container, Drink.self, "sweet")
    struct Coke: Drink {
        let name: String = "Coke"
    }

    @Provides(ObjectScope.container, Drink.self, "coffee", "hasCaffeine")
    struct Coffee: Drink {
        let name: String = "Coffee"
        let hasCaffeine: Bool

        init(hasCaffeine: Bool) {
            self.hasCaffeine = hasCaffeine
        }
    }

    @Provides(ObjectScope.container, Drink.self, nil, "secretLevel")
    struct SecretDrink: Drink {
        let name: String = "secret drink"
        let secretLevel: Int

        init(secretLevel: Int) {
            self.secretLevel = secretLevel
        }
    }

    /// Demo for @AutoInject, @Inject, @InitArg
    @AutoInject
    struct MonMenu: Menu {
    }

    @AutoInject
    struct TueMenu: Menu {
        // Expected Water
        @Inject(Drink.self)
        let drink: Drink
    }

    @AutoInject
    struct WedMenu: Menu {
        // Expected Coke
        @Inject(Drink.self, "sweet")
        let drink: Drink
    }

    @AutoInject
    struct ThuMenu: Menu {
        // Expected Coffee
        @Inject(Drink.self, "coffee", false)
        let drink: Drink
    }

    @AutoInject
    struct FriMenu: Menu {
        // Expected SecretDrink
        @Inject(Drink.self, nil, 10)
        let drink: Drink
    }

    @AutoInject
    struct SatMenu: Menu {
        // Expected Coffee
        @Inject(Drink.self, "coffee", false)
        let drink: Drink
        // Expected Coke
        @Inject(Drink.self, "sweet")
        let sweetDrink: Drink
        // Expected SecretDrink
        @Inject(Drink.self, nil, 10)
        let secretDrink: Drink?
    }

    @AutoInject
    struct SunMenu: Menu {
        // Expected Coffee
        @Inject(Drink.self, "coffee", false)
        let drink: Drink
        // Expected Coke
        @Inject(Drink.self, "sweet")
        let sweetDrink: Drink
        // Expected SecretDrink
        @Inject(Drink.self, nil, 10)
        let secretDrink: Drink?
        // Expected argument for init()
        @InitArg
        let food: Food?
    }

    @AutoInject
    struct SpecialMenu: Menu {
        // Expected Coffee
        @Inject(Drink.self, "coffee", false)
        let drink: Drink
        // Expected Coke
        @Inject(Drink.self, "sweet")
        let sweetDrink: Drink
        // Expected SecretDrink
        @Inject(Drink.self, nil, 10)
        let secretDrink: Drink?
        // Expected argument for init()
        @InitArg
        let food: Food?

        // Expected non argument for init()
        let currentSales: Int = 0
    }

    /// Demo for mixing @Provides, @AutoInject, @Inject and @InitArg
    @AutoInject
    @Provides(ObjectScope.container, Menu.self, nil, "food")
    struct ChefMenu: Menu {
        @Inject(Drink.self, nil, 10000)
        let secretDrink: Drink?

        @InitArg
        let food: Food?

        let price: Int = 100000
    }
}
