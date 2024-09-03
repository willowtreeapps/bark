# Bark
Simple, but powerful, message broadcasting library (similar to NotificationCenter in spirit).

Tree bark won't bark. But `bark` will!, and it will help you broadcast information across your app in a structured concurrent way.

## Why Bark
With `bark`, you can register subscriptions that require a concurrency context, and be assured at the point of use that the subscription was run when the `await` to the associated post completes. 

This allows you to reason about the order in which tasks associated with subscriptions execute. Making it easier to write testable and understandable code.

## Features
- **Lightweight and Focused** - Specifically responsible for dealing with message broadcasting.
- **Swift-native Design** - Bark feels natural and intuitive for Swift developers.
- **Thread-safe**
- **Simple** - Very simple syntax

## Installation
Bark is available through the Swift Package Manager. To install it, simply add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/willowtreeapps/bark.git", from: "1.0.2")
]
```

## Usage
Bark allows for structured concurrent message broadcasting. Here's an example from its tests:

### Registration

```swift
// Bark instance: I recommend registering into dependency injection and resolving it 
// where you need it.
// Consider [Grove](https://github.com/willowtreeapps/grove) for this purpose!
//
// You normally want a single instance of Bark for your app, but you can define 
// different instances that deal with different parts of the app.
// The instance is similar in purpose to NotificationCenter instance.
// If not using dependency injection, you can use `Bark.shared`. This is equivalent
// to NotificationCenter.default.
let bark = Bark()

func testPostsOfASingleSubscription() async throws {
    // Given
    let subscriptions = Bark.Store()
    var testNotification1PostCount = 0

    func increaseTheCounter() async {
        testNotification1PostCount += 1
    }

    bark.subscribe(.testNotification1, in: subscriptions) { _ in
        await increaseTheCounter()
    }

    // When
    await bark.post(.testNotification1)
    await bark.post(.testNotification1)

    // Then
    XCTAssertEqual(testNotification1PostCount, 2)
}
```

## Contributing
Contributions are immensely appreciated. Feel free to submit pull requests or to create issues to discuss any potential bugs or improvements.

## Author
Bark was created by @rafcabezas at [WillowTree, Inc](https://willowtreeapps.com).

## License
Bark is available under the [MIT license](LICENSE).
