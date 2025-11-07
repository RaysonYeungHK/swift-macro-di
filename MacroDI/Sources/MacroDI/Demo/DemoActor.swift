// If xcode -> Expand Macro doesn't work, then you need to "import MacroDI" explicitly
import MacroDI

class DemoActor {
    /// Demo for @Provides
    protocol Drink {
        var name: String { get }
    }

    protocol Food: Sendable {
        var name: String { get }
    }

    protocol Menu {
    }

    @Provides(ObjectScope.container, Drink.self)
    actor Water: Drink {
        let name: String = "Water"
    }

    @Provides(ObjectScope.container, Drink.self, "sweet")
    actor Coke: Drink {
        let name: String = "Coke"
    }

    @Provides(ObjectScope.container, Drink.self, "coffee", "hasCaffeine")
    actor Coffee: Drink {
        let name: String = "Coffee"
        let hasCaffeine: Bool

        init(hasCaffeine: Bool) {
            self.hasCaffeine = hasCaffeine
        }
    }

    @Provides(ObjectScope.container, Drink.self, nil, "secretLevel")
    actor SecretDrink: Drink {
        let name: String = "secret drink"
        let secretLevel: Int

        init(secretLevel: Int) {
            self.secretLevel = secretLevel
        }
    }

    /// Demo for @AutoInject, @Inject, @InitArg
    @AutoInject
    actor MonMenu: Menu {
    }

    @AutoInject
    actor TueMenu: Menu {
        // Expected Water
        @Inject(Drink.self)
        let drink: Drink
    }

    @AutoInject
    actor WedMenu: Menu {
        // Expected Coke
        @Inject(Drink.self, "sweet")
        let drink: Drink
    }

    @AutoInject
    actor ThuMenu: Menu {
        // Expected Coffee
        @Inject(Drink.self, "coffee", false)
        let drink: Drink
    }

    @AutoInject
    actor FriMenu: Menu {
        // Expected SecretDrink
        @Inject(Drink.self, nil, 10)
        let drink: Drink
    }

    @AutoInject
    actor SatMenu: Menu {
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
    actor SunMenu: Menu {
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
    actor SpecialMenu: Menu {
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
    actor ChefMenu: Menu {
        @Inject(Drink.self, nil, 10000)
        let secretDrink: Drink?

        @InitArg
        let food: Food?

        let price: Int = 100000
    }
}
