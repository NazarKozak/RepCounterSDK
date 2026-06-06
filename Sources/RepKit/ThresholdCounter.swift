//
//  ThresholdCounter.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  Hysteresis rep counter. A rep = the signal rising past `enter` (e.g. a deep
//  squat) and then falling back past `exit` (standing). The gap between the two
//  thresholds rejects frame jitter, so noise near one value can't double-count.
//

import Foundation

/// Counts full rise-and-return cycles of a 0…1 signal with hysteresis.
public struct ThresholdCounter: Sendable {
    public let enter: Double
    public let exit: Double
    private var armed = false
    public private(set) var count = 0

    public init(enter: Double = 0.95, exit: Double = 0.05) {
        self.enter = enter
        self.exit = exit
    }

    /// Feeds the next signal value. Returns `true` exactly on the frame a rep completes.
    @discardableResult
    public mutating func count(_ value: Double) -> Bool {
        if !armed {
            if value >= enter { armed = true }   // reached the "down" position
            return false
        } else if value <= exit {
            armed = false                        // returned to the "up" position → one rep
            count += 1
            return true
        }
        return false
    }

    public mutating func reset() {
        armed = false
        count = 0
    }
}
