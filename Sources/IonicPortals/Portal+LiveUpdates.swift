import Foundation
import IonicLiveUpdates
import LiveUpdateProvider

extension Portal {
    /// The live update provider for a ``Portal``.
    public enum LiveUpdateProvider {
        /// Uses Ionic Live Updates to sync and locate the latest web application assets.
        ///
        /// Portals configured with this case are synchronized with ``Portal/sync()``.
        case ionic(
            /// The `LiveUpdateManager` responsible for locating the latest source for the web application.
            liveUpdateManager: LiveUpdateManager = .shared,
            /// The `LiveUpdate` configuration used to determine the location of updated application assets.
            liveUpdateConfig: LiveUpdate)

        /// Uses an external live update provider to sync and locate the latest web application assets.
        ///
        /// Portals configured with this case are synchronized with ``Portal/syncProvider()``.
        case provider(liveUpdateManager: any LiveUpdateManaging)
    }

    /// Error thrown when a portal is not configured with the live update provider type required by the sync method.
    public struct LiveUpdateNotConfigured: Error {}

    /// Syncs a portal configured with ``Portal/LiveUpdateProvider/ionic(liveUpdateManager:liveUpdateConfig:)``.
    ///
    /// Use this method for Ionic Live Updates. To sync a portal configured with
    /// ``Portal/LiveUpdateProvider/provider(liveUpdateManager:)``, call ``syncProvider()``.
    /// - Returns: The Ionic Live Updates synchronization result.
    /// - Throws: ``LiveUpdateNotConfigured`` if the portal is not configured with the Ionic Live Updates provider.
    ///   Any errors thrown from Ionic Live Updates will be propagated.
    public func sync() async throws -> LiveUpdateManager.SyncResult {
        guard case .ionic(let manager, let config) = liveUpdateProvider else {
            throw LiveUpdateNotConfigured()
        }

        return try await manager.sync(appId: config.appId)
    }

    /// Syncs a portal configured with ``Portal/LiveUpdateProvider/provider(liveUpdateManager:)``.
    ///
    /// Use this method for external live update providers. To sync a portal configured with
    /// ``Portal/LiveUpdateProvider/ionic(liveUpdateManager:liveUpdateConfig:)``, call ``sync()``.
    /// - Returns: The external provider's synchronization result.
    /// - Throws: ``LiveUpdateNotConfigured`` if the portal is not configured with an external live update provider.
    ///   Any errors thrown from the live update provider will be propagated.
    public func syncProvider() async throws -> any SyncResult {
        guard case .provider(let manager) = liveUpdateProvider else {
            throw LiveUpdateNotConfigured()
        }

        return try await manager.sync()
    }

    /// Synchronizes portals configured with Ionic Live Updates in parallel.
    ///
    /// Each portal must be configured with
    /// ``Portal/LiveUpdateProvider/ionic(liveUpdateManager:liveUpdateConfig:)``.
    /// Use ``syncProvider(_:)`` for portals configured with external live update providers.
    /// - Parameter portals: The ``Portal``s to synchronize with ``Portal/sync()``
    /// - Returns: A ``ParallelLiveUpdateSyncGroup`` of the results of each call to ``Portal/sync()``
    ///
    /// Usage
    /// ```swift
    /// let portals = [portal1, portal2, portal3]
    /// for await result in Portals.sync(portals) {
    ///     // do something with result
    /// }
    /// ```
    public static func sync(_ portals: [Portal]) -> ParallelLiveUpdateSyncGroup {
        .init(portals)
    }

    /// Synchronizes portals configured with external live update providers in parallel.
    ///
    /// Each portal must be configured with ``Portal/LiveUpdateProvider/provider(liveUpdateManager:)``.
    /// Use ``sync(_:)`` for portals configured with Ionic Live Updates.
    /// - Parameter portals: The ``Portal``s to synchronize with ``Portal/syncProvider()``
    /// - Returns: A ``ParallelLiveUpdateProviderSyncGroup`` of the results of each call to ``Portal/syncProvider()``
    public static func syncProvider(_ portals: [Portal]) -> ParallelLiveUpdateProviderSyncGroup {
        .init(portals)
    }
    
    /// The directory of the latest synced web application assets for this portal.
    /// Returns `nil` if no live update provider is configured or no sync has occurred.
    public var latestAppDirectory: URL? {
        switch liveUpdateProvider {
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
    /// Synchronizes portals configured with Ionic Live Updates in parallel.
    ///
    /// Each portal must be configured with
    /// ``Portal/LiveUpdateProvider/ionic(liveUpdateManager:liveUpdateConfig:)``.
    /// Use ``syncProvider()`` for portals configured with external live update providers.
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

    /// Synchronizes portals configured with external live update providers in parallel.
    ///
    /// Each portal must be configured with ``Portal/LiveUpdateProvider/provider(liveUpdateManager:)``.
    /// Use ``sync()`` for portals configured with Ionic Live Updates.
    /// - Returns: A ``ParallelLiveUpdateProviderSyncGroup`` of the results of each call to ``Portal/syncProvider()``
    public func syncProvider() -> ParallelLiveUpdateProviderSyncGroup {
        .init(self)
    }
}

/// Alias for a parallel sequence of Ionic Live Updates synchronization results
public typealias ParallelLiveUpdateSyncGroup = ParallelAsyncSequence<Result<LiveUpdateManager.SyncResult, any Error>>

/// Alias for a parallel sequence of external Live Update provider synchronization results
public typealias ParallelLiveUpdateProviderSyncGroup = ParallelAsyncSequence<Result<any SyncResult, any Error>>

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
