//
//  ThresholdTimer.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  Accumulates wall-clock time while a signal stays above a threshold — used for
//  held poses like a plank.
//

import Foundation

/// Sums elapsed time across the frames where `value > threshold`.
public struct ThresholdTimer: Sendable {
    public let threshold: Double
    public private(set) var accumulated: TimeInterval = 0
    private var lastTimestamp: TimeInterval?

    public init(threshold: Double = 0.2) {
        self.threshold = threshold
    }

    /// Advances the timer to `now`, adding the elapsed interval when `value` is held.
    @discardableResult
    public mutating func time(_ value: Double, at now: TimeInterval) -> TimeInterval {
        defer { lastTimestamp = now }
        guard let last = lastTimestamp else { return accumulated }
        if value > threshold {
            accumulated += max(0, now - last)
        }
        return accumulated
    }

    public mutating func reset() {
        accumulated = 0
        lastTimestamp = nil
    }
}
