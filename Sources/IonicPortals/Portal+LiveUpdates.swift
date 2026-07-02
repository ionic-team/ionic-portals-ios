import Foundation
import IonicLiveUpdates
import LiveUpdateProvider

extension Portal {
    /// Error thrown if the required live update source is not present on a ``Portal`` when syncing.
    public struct LiveUpdateNotConfigured: Error {}

    /// Syncs the Ionic Live Updates source if present.
    /// - Returns: The result of the synchronization operation.
    /// - Throws: If the portal has no Ionic Live Updates source, a ``LiveUpdateNotConfigured`` error will be thrown.
    ///   Any errors thrown from Ionic Live Updates will be propagated.
    public func sync() async throws -> LiveUpdateManager.SyncResult {
        guard case .ionic(let manager, let config) = liveUpdateSource else {
            throw LiveUpdateNotConfigured()
        }

        return try await manager.sync(appId: config.appId)
    }

    /// Syncs the external live update provider source if present.
    /// - Returns: The result of the synchronization operation, or `nil` when no update is available.
    /// - Throws: If the portal has no external live update provider source, a ``LiveUpdateNotConfigured`` error will be thrown.
    ///   Any errors thrown from the live update provider will be propagated.
    public func syncProvider() async throws -> (any ProviderSyncResult)? {
        guard case .provider(let manager) = liveUpdateSource else {
            throw LiveUpdateNotConfigured()
        }

        return try await manager.sync()
    }

    /// Synchronizes the Ionic Live Updates sources of the provided ``Portal``s in parallel.
    /// - Parameter portals: The ``Portal``s to synchronize with ``Portal/sync()``
    /// - Returns: A ``ParallelLiveUpdateSyncGroup`` of the results of each call to ``Portal/sync()``
    ///
    /// Usage
    /// ```swift
    /// let portals = [portal1, portal2, portal3]
    /// for await result in Portal.sync(portals) {
    ///     // do something with result
    /// }
    /// ```
    public static func sync(_ portals: [Portal]) -> ParallelLiveUpdateSyncGroup {
        .init(portals)
    }

    /// Synchronizes the external live update provider sources of the provided ``Portal``s in parallel.
    /// - Parameter portals: The ``Portal``s to synchronize with ``Portal/syncProvider()``
    /// - Returns: A ``ParallelLiveUpdateProviderSyncGroup`` of the results of each call to ``Portal/syncProvider()``
    public static func syncProvider(_ portals: [Portal]) -> ParallelLiveUpdateProviderSyncGroup {
        .init(portals)
    }

    /// The directory of the latest synced web application assets for this portal, if present.
    public var latestAppDirectory: URL? {
        switch liveUpdateSource {
        case .ionic(let manager, let config):
            return manager.latestAppDirectory(for: config.appId)
        case .provider(let manager):
            return manager.latestAppDirectory
        case .none:
            return nil
        }
    }
}

extension Array where Element == Portal {
    /// Synchronizes the Ionic Live Updates sources for the elements in the array.
    /// - Returns: A ``ParallelLiveUpdateSyncGroup`` of the results of each call to ``Portal/sync()``
    ///
    /// Usage
    /// ```swift
    /// let portals = [portal1, portal2, portal3]
    /// for await result in portals.sync() {
    ///     // do something with result
    /// }
    /// ```
    public func sync() -> ParallelLiveUpdateSyncGroup {
        .init(self)
    }

    /// Synchronizes the external live update provider sources for the elements in the array.
    /// - Returns: A ``ParallelLiveUpdateProviderSyncGroup`` of the results of each call to ``Portal/syncProvider()``
    public func syncProvider() -> ParallelLiveUpdateProviderSyncGroup {
        .init(self)
    }
}

/// Alias for a parallel sequence of Ionic Live Updates synchronization results
public typealias ParallelLiveUpdateSyncGroup = ParallelAsyncSequence<Result<LiveUpdateManager.SyncResult, any Error>>

/// Alias for a parallel sequence of external live update provider synchronization results.
public typealias ParallelLiveUpdateProviderSyncGroup = ParallelAsyncSequence<Result<(any ProviderSyncResult)?, any Error>>

extension ParallelLiveUpdateSyncGroup {
    init(_ portals: [Portal]) {
        work = portals.map { portal in
            { await Result(catching: portal.sync) }
        }
    }
}

extension ParallelLiveUpdateProviderSyncGroup {
    init(_ portals: [Portal]) {
        work = portals.map { portal in
            { await Result(catching: portal.syncProvider) }
        }
    }
}

/// A sequence that executes its tasks in parallel and yields their results as they complete
public struct ParallelAsyncSequence<T>: AsyncSequence {
    public typealias Element = Iterator.Element
    private var work: [() async -> T]

    init(work: [() async -> T]) {
        self.work = work
    }

    /// Creates an asynchronous iterator for this sequence
    public func makeAsyncIterator() -> Iterator {
        Iterator(work)
    }
}

extension ParallelAsyncSequence {
    /// An iterator that executes its tasks in parallel and yields their results as they complete
    public struct Iterator: AsyncIteratorProtocol {
        private let storage: Storage
        private let tasks: [Task<Void, Never>]
        private var currentIndex = 0

        fileprivate init(_ work: [() async -> T]) {
            let storage = Storage(anticipatedSize: work.count)
            self.storage = storage
            tasks = work.map { run in
                Task { [storage] in
                    await storage.append(await run())
                }
            }
        }

        /// Advances the iterator and returns the next value, or `nil` if there are no more values
        mutating public func next() async -> T? {
            defer { currentIndex += 1 }
            guard currentIndex < tasks.endIndex else { return nil }

            while currentIndex >= (await storage.results.count) {
                await Task.yield()
                if Task.isCancelled {
                    for task in tasks {
                        task.cancel()
                    }
                    return nil
                }
            }

            return await storage.results[currentIndex]
        }
    }

    private actor Storage {
        var results: [T]

        init(anticipatedSize: Int) {
            results = []
            results.reserveCapacity(anticipatedSize)
        }

        func append(_ element: T) {
            results.append(element)
        }
    }
}

extension Result {
    init(catching body: @escaping () async throws -> Success) async where Failure == any Error {
        do {
            let result = try await body()
            self = .success(result)
        } catch {
            self = .failure(error)
        }
    }
}
