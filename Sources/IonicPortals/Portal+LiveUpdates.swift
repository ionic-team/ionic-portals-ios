import Foundation
import IonicLiveUpdates
import LiveUpdateProvider

extension Portal {
    /// Error thrown if a ``liveUpdateConfig`` is not present on a ``Portal`` when ``sync()`` is called.
    public struct LiveUpdateNotConfigured: Error {}

    /// Syncs the live update provider if configured.
    /// - Returns: The result of the synchronization operation.
    /// - Throws: ``LiveUpdateNotConfigured`` if no live update provider is configured.
    ///   Any errors thrown from the live update provider will be propagated.
    public func sync() async throws -> any SyncResult {
        switch liveUpdateProvider {
        case .ionic(let manager, let config):
            return IonicSyncResult(try await manager.sync(appId: config.appId))
        case .custom(let manager):
            return try await manager.sync()
        case .none:
            throw LiveUpdateNotConfigured()
        }
    }

    /// Synchronizes the ``liveUpdateConfig``s of the provided ``Portal``s in parallel
    /// - Parameter portals: The ``Portal``s to ``sync()``
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
    
    /// The directory of the latest synced web application assets for this portal.
    /// Returns `nil` if no live update provider is configured or no sync has occurred.
    public var latestAppDirectory: URL? {
        switch liveUpdateProvider {
        case .ionic(let manager, let config):
            return manager.latestAppDirectory(for: config.appId)
        case .custom(let manager):
            return manager.latestAppDirectory
        case .none:
            return nil
        }
    }
}

/// The result of a sync operation performed by the Ionic live update provider.
/// Contains the outcome of the sync and the underlying `LiveUpdateManager.SyncResult` for ionic-specific details.
public struct IonicSyncResult: SyncResult {
    public let didUpdate: Bool
    public let ionicSyncResult: LiveUpdateManager.SyncResult
    
    public init(_ ionicSyncResult: LiveUpdateManager.SyncResult) {
        self.didUpdate = ionicSyncResult.source != .cache(latestAppDirectoryChanged: false)
        self.ionicSyncResult = ionicSyncResult
    }
}



extension Array where Element == Portal {
    /// Synchronizes the ``Portal/liveUpdateConfig`` for the elements in the array
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
}

/// Alias for a parallel sequence of Live Update synchronization results
public typealias ParallelLiveUpdateSyncGroup = ParallelAsyncSequence<Result<any SyncResult, any Error>>

extension ParallelLiveUpdateSyncGroup {
    init(_ portals: [Portal]) {
        work = portals.map { portal in
            { await Result(catching: portal.sync) }
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
