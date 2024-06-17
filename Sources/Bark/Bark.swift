//
//  Bark.swift
//
//
//  Created by Raf Cabezas on 6/6/24.
//

import Foundation

public final class Bark: @unchecked Sendable {

    // MARK: - Types

    public typealias Block = (Any?) async -> Void

    public struct Name: Hashable, Equatable {
        private let value: String
        public init(_ value: String) {
            self.value = value
        }

        public var description: String { value }
    }

    public final class Store: @unchecked Sendable {
        struct Handler {
            let name: Name
            let block: Block
        }

        fileprivate let id = UUID()
        fileprivate var handlers: [Handler] = []
        private let lock = NSLock()

        public init() {}

        func add(_ block: @escaping Block, for name: Name) {
            lock.lock()
            handlers.append(Handler(name: name, block: block))
            lock.unlock()
        }

        func blocks(for name: Name) -> [Block] {
            lock.lock()
            let blocks = handlers.compactMap { $0.name == name ? $0.block : nil }
            lock.unlock()
            return blocks
        }

        func clear() {
            lock.lock()
            handlers.removeAll()
            lock.unlock()
        }
    }

    // MARK: - Properties

    private let lock = NSLock()
    private struct StoreWrapper {
        weak var store: Store?
    }
    private var stores = [StoreWrapper]()

    // MARK: - Lifecycle

    public init() {
        /* No-Op */
    }

    // MARK: - Actions

    public func subscribe(_ name: Name, in store: Store?, block: @escaping Block) {
        guard let store else { return }
        lock.lock()
        store.add(block, for: name)
        if !stores.contains(where: { $0.store?.id == store.id }) {
            stores.append(StoreWrapper(store: store))
        }
        lock.unlock()
    }

    public func unsubscribe(_ store: Store?) {
        guard let store else { return }
        lock.lock()
        store.clear()
        stores.removeAll { $0.store?.id == store.id }
        lock.unlock()
    }

    public func post(_ name: Name, data: Any? = nil) async {
        for block in blocks(for: name) {
            await block(data)
        }
    }

    // MARK: - Helpers

    public func registrationsCount(for name: Name) -> Int {
        blocks(for: name).count
    }

    private func blocks(for name: Name) -> [Block] {
        lock.lock()
        let blocks = stores
            .compactMap { $0.store?.blocks(for: name) }
            .flatMap { $0 }
        lock.unlock()
        return blocks
    }
}
