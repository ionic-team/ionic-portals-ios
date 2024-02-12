import IonicLiveUpdates

extension Portal {
    /// Error thrown if a ``liveUpdateConfig`` is not present on a ``Portal`` when ``sync()`` is called.
    public struct LiveUpdateNotConfigured: Error {}

    /// Syncs the ``liveUpdateConfig`` if present
    /// - Returns: The result of the synchronization operation
    /// - Throws: If the portal has no ``liveUpdateConfig``, a ``LiveUpdateNotConfigured`` error will be thrown.
    ///   Any errors thrown from ``liveUpdateManager`` will be propogated.
    public func sync() async throws -> LiveUpdateManager.SyncResult {
        if let liveUpdateConfig {
            return try await liveUpdateManager.sync(appId: liveUpdateConfig.appId)
        } else {
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
public typealias ParallelLiveUpdateSyncGroup = ParallelAsyncSequence<Result<LiveUpdateManager.SyncResult, any Error>>

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
