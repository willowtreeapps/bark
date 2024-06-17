# Bark
Simple message broadcasting library (similar to NotificationCenter in spirit). It's designed to help you manage a group of dependencies in a container, and easily resolve them when needed, thus helping make your project more modular, testable, and maintainable.

Tree bark won't bark. But `bark` will, and it will allow you to broadcast information across your app in a structured concurrent way.

## Why Bark
With `bark`, you can register subscriptions that require a concurrency context, and be assured at the point of use that the subscription was
run when the `await` to the associated post completes. 

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
    .package(url: "https://github.com/willowtreeapps/bark.git", from: "1.0.0")
]
```

## Usage
Bark allows for structured concurrent message broadcasting. Here's an example from its tests:

### Registration

```swift
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
Grove was created by @rafcabezas at [WillowTree, Inc](https://willowtreeapps.com).

## License
Grove is available under the [MIT license](https://opensource.org/licenses/MIT).
