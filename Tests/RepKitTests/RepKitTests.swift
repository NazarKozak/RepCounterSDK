//
//  RepKitTests.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import Testing
import CoreGraphics
@testable import RepKit

// MARK: - Synthetic poses (only the joints each test needs)

private func legPose(leftKnee: Double, rightKnee: Double) -> PoseLandmarks {
    // Build hip/knee/ankle so the knee interior angle equals the requested value.
    // Standing (180°) is a straight vertical leg; smaller angles swing the ankle out.
    func leg(originX: CGFloat, angle: Double) -> [(Joint, CGPoint)] {
        let hipJoint: Joint = originX < 0 ? .leftHip : .rightHip
        let kneeJoint: Joint = originX < 0 ? .leftKnee : .rightKnee
        let ankleJoint: Joint = originX < 0 ? .leftAnkle : .rightAnkle
        let knee = CGPoint(x: originX, y: 1)
        let hip = CGPoint(x: originX, y: 2) // straight up from knee (knee→hip = (0, 1))
        // Place the ankle so the interior hip–knee–ankle angle equals `angle`:
        // a vector `angle` degrees off the upward (hip) direction, rotating toward +x.
        let rad = angle * .pi / 180
        let ankle = CGPoint(x: originX + CGFloat(sin(rad)), y: 1 + CGFloat(cos(rad)))
        return [(hipJoint, hip), (kneeJoint, knee), (ankleJoint, ankle)]
    }
    var points: [Joint: CGPoint] = [:]
    for (j, p) in leg(originX: -1, angle: leftKnee) { points[j] = p }
    for (j, p) in leg(originX: 1, angle: rightKnee) { points[j] = p }
    return PoseLandmarks(points: points)
}

// MARK: - Geometry

@Suite("PoseMath")
struct PoseMathTests {
    @Test("Straight line is 180°, right angle is 90°")
    func angles() {
        let straight = PoseMath.angle(at: .init(x: 0, y: 1), from: .init(x: 0, y: 2), to: .init(x: 0, y: 0))
        #expect(abs(straight - 180) < 0.001)
        let right = PoseMath.angle(at: .init(x: 0, y: 0), from: .init(x: 0, y: 1), to: .init(x: 1, y: 0))
        #expect(abs(right - 90) < 0.001)
    }

    @Test("normalize clamps and supports inverse ranges")
    func normalize() {
        #expect(PoseMath.normalize(95, from: 160, to: 95) == 1)
        #expect(PoseMath.normalize(160, from: 160, to: 95) == 0)
        #expect(PoseMath.normalize(80, from: 160, to: 95) == 1)  // past deep → clamped to 1
        #expect(PoseMath.normalize(200, from: 160, to: 95) == 0) // past standing → clamped to 0
    }
}

// MARK: - Counter

@Suite("ThresholdCounter")
struct ThresholdCounterTests {
    @Test("Counts one rep per full rise-and-return")
    func oneRep() {
        var c = ThresholdCounter(enter: 0.95, exit: 0.05)
        #expect(c.count(0.0) == false)
        #expect(c.count(1.0) == false) // armed
        #expect(c.count(0.0) == true)  // rep
        #expect(c.count == 1)
    }

    @Test("Jitter near the enter threshold doesn't double count")
    func noDoubleCount() {
        var c = ThresholdCounter(enter: 0.95, exit: 0.05)
        c.count(1.0); c.count(0.96); c.count(0.97) // stays armed, no return below exit
        #expect(c.count == 0)
    }
}

// MARK: - Squat engine end-to-end

@Suite("Squat detection")
struct SquatTests {
    @Test("A clean two-knee squat counts one rep")
    func cleanRep() {
        let detector = RepDetector(exercise: .squat)
        _ = detector.process(legPose(leftKnee: 180, rightKnee: 180)) // standing
        _ = detector.process(legPose(leftKnee: 90, rightKnee: 90))   // deep, both knees
        let result = detector.process(legPose(leftKnee: 180, rightKnee: 180)) // up
        #expect(result == .rep(count: 1))
        #expect(detector.count == 1)
    }

    @Test("One-sided squat is rejected as a form issue")
    func oneSidedCheat() {
        let detector = RepDetector(exercise: .squat)
        _ = detector.process(legPose(leftKnee: 180, rightKnee: 180))
        _ = detector.process(legPose(leftKnee: 90, rightKnee: 175))  // only left bends
        let result = detector.process(legPose(leftKnee: 180, rightKnee: 180))
        #expect(result == .formIssue("Bend both knees fully"))
        #expect(detector.count == 0)
    }
}
