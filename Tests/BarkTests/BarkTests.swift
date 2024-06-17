//
//  BarkTests.swift
//  Unit Tests
//
//  Created by Raf Cabezas on 6/7/24.
//

import Bark
import SwiftUI
import XCTest

final class BarkTests: XCTestCase {
    @MainActor
    let bark = Bark()

    @MainActor
    override func setUp() async throws {}

    @MainActor
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

    @MainActor
    func testPostsOfTwoSubscriptions() async throws {
        // Given
        let subscriptions = Bark.Store()
        var testNotification1PostCount = 0
        var testNotification2PostCount = 0
        bark.subscribe(.testNotification1, in: subscriptions) { _ in
            testNotification1PostCount += 1
        }
        bark.subscribe(.testNotification2, in: subscriptions) { _ in
            testNotification2PostCount += 1
        }

        // When
        await bark.post(.testNotification1)
        await bark.post(.testNotification1)
        await bark.post(.testNotification2)
        await bark.post(.testNotification2)
        await bark.post(.testNotification2)
        await bark.post(.testNotification1)
        await bark.post(.testNotification2)

        // Then
        XCTAssertEqual(testNotification1PostCount, 3)
        XCTAssertEqual(testNotification2PostCount, 4)
    }

    @MainActor
    func testUnsubscribe() async throws {
        // Given
        let subscriptions = Bark.Store()
        var testNotification1PostCount = 0
        bark.subscribe(.testNotification1, in: subscriptions) { _ in
            testNotification1PostCount += 1
        }

        // When
        bark.unsubscribe(subscriptions)
        await bark.post(.testNotification1)
        await bark.post(.testNotification1)

        // Then
        XCTAssertEqual(testNotification1PostCount, 0)
    }

    @MainActor
    func testThatGivenTwoSubscriptionsBothHandleThePost() async throws {
        // Given
        let subscriptions = Bark.Store()
        var testNotification1PostCount = 0
        var testNotification1SecondaryPostCount = 0
        bark.subscribe(.testNotification1, in: subscriptions) { _ in
            testNotification1PostCount += 1
        }
        bark.subscribe(.testNotification1, in: subscriptions) { _ in
            testNotification1SecondaryPostCount += 1
        }

        // When
        await bark.post(.testNotification1)
        await bark.post(.testNotification1)

        // Then
        XCTAssertEqual(testNotification1PostCount, 2)
        XCTAssertEqual(testNotification1SecondaryPostCount, 2)
    }

    @MainActor
    func testThatGivenSubscriptionsInDifferentObjectsTheyAllGetNotified() async {
        // Given
        var object1Counter = 0
        var object2Counter = 0
        var object3Counter = 0
        let object1CounterBinding = Binding(get: { object1Counter }, set: { object1Counter = $0 })
        let object2CounterBinding = Binding(get: { object2Counter }, set: { object2Counter = $0 })
        let object3CounterBinding = Binding(get: { object3Counter }, set: { object3Counter = $0 })
        let object1 = await BarkTestClass(bark: bark, notification: .testNotification1, counter: object1CounterBinding)
        object1.subscribe()
        let object2 = await BarkTestClass(bark: bark, notification: .testNotification1, counter: object2CounterBinding)
        object2.subscribe()
        let object3 = await BarkTestClass(bark: bark, notification: .testNotification1, counter: object3CounterBinding)
        object3.subscribe()

        // When
        await bark.post(.testNotification1)
        await bark.post(.testNotification1)

        // Then
        XCTAssertEqual(object1Counter, 2)
        XCTAssertEqual(object2Counter, 2)
        XCTAssertEqual(object3Counter, 2)
    }

    // Test object going out of scope causes subscription to be removed
    @MainActor
    func testThatGivenAnObjectGoesOutOfScopeTheSubscriptionIsRemoved() async {
        // Given
        var counter = 0
        let counterBinding = Binding(get: { counter }, set: { counter = $0 })
        var object: BarkTestClass? = await BarkTestClass(bark: bark, notification: .testNotification1, counter: counterBinding)
        object?.subscribe()

        // When
        await bark.post(.testNotification1)
        XCTAssertEqual(counter, 1)
        let registrationCount = bark.registrationsCount(for: .testNotification1)
        XCTAssertEqual(registrationCount, 1)
        // When the object goes out of scope
        object = nil
        await Task.yield()

        // Then posting again has no effect and it removes the registration
        await bark.post(.testNotification1)
        XCTAssertEqual(counter, 1)
        let registrationCount2 = bark.registrationsCount(for: .testNotification1)
        XCTAssertEqual(registrationCount2, 0)
    }
}

private extension Bark.Name {
    static let testNotification1 = Bark.Name("testNotification1")
    static let testNotification2 = Bark.Name("testNotification2")
}

@MainActor
private final class BarkTestClass {
    private let bark: Bark
    private let notificationName: Bark.Name
    private let subscriptions = Bark.Store()
    @Binding private var counter: Int

    @MainActor
    init(bark: Bark, notification: Bark.Name, counter: Binding<Int>) async {
        self.bark = bark
        self._counter = counter
        self.notificationName = notification
        self._counter = counter
    }

    func subscribe() {
        bark.subscribe(notificationName, in: subscriptions) { [weak self] _ in
            self?.counter += 1
        }
    }
}
