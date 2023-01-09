//
//  WebPerformanceReporter.swift
//  
//
//  Created by Steven Sherry on 1/6/23.
//

/// A type to handle web performance metrics reporting from web applications
/// embedded in a ``PortalUIView`` or ``PortalView``
public struct WebPerformanceReporter {
    /// This closure will be called when the [First Contentful Paint](https://developer.mozilla.org/en-US/docs/Glossary/First_contentful_paint) metric is made available.
    /// The first `String` parameter will be the ``Portal/name`` and the second `Double` parameter will be the duration in milliseconds
    public var onFirstContentfulPaint: (_ portalName: String, _ duration: Double) -> Void

    /// Creates an instance of ``WebPerformanceReporter``
    /// - Parameter onFirstContentfulPaint: A closure that handles the First Contentful Paint metric.
    public init(_ onFirstContentfulPaint: @escaping (_ portalName: String, _ duration: Double) -> Void) {
        self.onFirstContentfulPaint = onFirstContentfulPaint
    }
}
