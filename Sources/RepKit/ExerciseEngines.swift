//
//  ExerciseEngines.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  The original rep-counting logic (ported from the QuickPose-based Sidequest app
//  onto free Apple Vision landmarks): a hysteresis main counter plus per-side
//  angle-gated counters that must agree, so half-reps and one-sided cheating don't
//  count.
//

import Foundation

protocol ExerciseEngine: AnyObject {
    func update(_ landmarks: PoseLandmarks, at time: TimeInterval) -> RepUpdate
    var count: Int { get }
    func reset()
}

// MARK: - Symmetric rep engine (squat, push-up)

/// Shared logic for two-sided rep exercises with dual-joint anti-cheat validation.
final class SymmetricRepEngine: ExerciseEngine {
    private var main = ThresholdCounter(enter: 0.95, exit: 0.05)
    private var left = ThresholdCounter(enter: 0.95, exit: 0.05)
    private var right = ThresholdCounter(enter: 0.95, exit: 0.05)
    private(set) var count = 0

    /// Angle below which a side counts as "engaged" (knee/elbow bent enough).
    private let gateAngle: Double
    /// Joint angle mapped to 0…1 depth (standingAngle → 0, deepAngle → 1).
    private let standingAngle: Double
    private let deepAngle: Double
    private let formMessage: String
    private let angle: (PoseLandmarks, Side) -> Double?

    init(gateAngle: Double,
         standingAngle: Double,
         deepAngle: Double,
         formMessage: String,
         angle: @escaping (PoseLandmarks, Side) -> Double?) {
        self.gateAngle = gateAngle
        self.standingAngle = standingAngle
        self.deepAngle = deepAngle
        self.formMessage = formMessage
        self.angle = angle
    }

    func update(_ landmarks: PoseLandmarks, at time: TimeInterval) -> RepUpdate {
        guard let leftAngle = angle(landmarks, .left),
              let rightAngle = angle(landmarks, .right) else { return .idle }

        // Depth is driven by the deeper side, so one good side can arm the rep — but
        // the per-side gates below require BOTH sides to have engaged for it to count.
        let depth = PoseMath.normalize(min(leftAngle, rightAngle), from: standingAngle, to: deepAngle)

        // Each side only accumulates depth while it is actually bent past the gate.
        left.count(leftAngle < gateAngle ? depth : 0)
        right.count(rightAngle < gateAngle ? depth : 0)

        guard main.count(depth) else { return .idle }

        // A rep only counts if both sides reached the bottom the same number of times.
        if left.count == main.count && right.count == main.count {
            count = main.count
            return .rep(count: count)
        } else {
            main.reset(); left.reset(); right.reset()
            count = 0
            return .formIssue(formMessage)
        }
    }

    func reset() {
        main.reset(); left.reset(); right.reset()
        count = 0
    }
}

func SquatEngine() -> SymmetricRepEngine {
    SymmetricRepEngine(
        gateAngle: 140,        // knees must bend past 140°
        standingAngle: 160,
        deepAngle: 95,
        formMessage: "Bend both knees fully",
        angle: { $0.kneeAngle($1) }
    )
}

func PushUpEngine() -> SymmetricRepEngine {
    SymmetricRepEngine(
        gateAngle: 150,        // elbows must bend past 150°
        standingAngle: 165,
        deepAngle: 90,
        formMessage: "Lower fully on both arms",
        angle: { $0.elbowAngle($1) }
    )
}

// MARK: - Timed hold engine (plank)

final class PlankEngine: ExerciseEngine {
    private var timer = ThresholdTimer(threshold: 0.2)
    private var lastReported = 0
    private(set) var count = 0   // seconds held

    func update(_ landmarks: PoseLandmarks, at time: TimeInterval) -> RepUpdate {
        guard let hip = landmarks.hipAngle() else { return .idle }
        // Straightness: hip angle near 180° (flat body) → ~1, piked/sagging → ~0.
        let straightness = PoseMath.normalize(hip, from: 140, to: 180)
        let held = timer.time(straightness, at: time)
        let seconds = Int(held)
        if seconds > lastReported {
            lastReported = seconds
            count = seconds
            return .holding(seconds: seconds)
        }
        return .idle
    }

    func reset() {
        timer.reset()
        lastReported = 0
        count = 0
    }
}
