//
//  Exercise.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import Foundation

/// The exercises RepKit can detect out of the box.
public enum Exercise: Sendable, CaseIterable {
    case squat
    case pushUp
    case plank

    /// Whether the exercise counts reps or accumulates a held duration.
    public var isTimed: Bool { self == .plank }

    func makeEngine() -> any ExerciseEngine {
        switch self {
        case .squat: SquatEngine()
        case .pushUp: PushUpEngine()
        case .plank: PlankEngine()
        }
    }
}

/// The result of feeding one pose to a ``RepDetector``.
public enum RepUpdate: Sendable, Equatable {
    /// Nothing notable this frame.
    case idle
    /// A rep just completed; `count` is the running total.
    case rep(count: Int)
    /// A held exercise crossed another whole second; `seconds` is the total held.
    case holding(seconds: Int)
    /// A rep attempt was rejected for poor form (e.g. didn't go deep enough on both sides).
    case formIssue(String)
}
