//
//  PoseLandmarks.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import CoreGraphics
import Foundation

/// A single detected body pose: normalized joint positions plus per-joint confidence.
///
/// Coordinates are normalized (0…1). RepKit only uses angles, so the coordinate
/// origin/orientation does not matter as long as it is consistent within a frame.
public struct PoseLandmarks: Sendable {
    public var points: [Joint: CGPoint]
    public var confidence: [Joint: Double]

    public init(points: [Joint: CGPoint], confidence: [Joint: Double] = [:]) {
        self.points = points
        self.confidence = confidence
    }

    public subscript(_ joint: Joint) -> CGPoint? { points[joint] }
}

public extension PoseLandmarks {
    /// Interior angle (degrees) at `b` between `a`–`b`–`c`, or `nil` if any point is missing.
    func angle(_ a: Joint, _ b: Joint, _ c: Joint) -> Double? {
        guard let pa = points[a], let pb = points[b], let pc = points[c] else { return nil }
        let value = PoseMath.angle(at: pb, from: pa, to: pc)
        return value.isNaN ? nil : value
    }

    /// Knee angle (hip–knee–ankle). ~180° standing, smaller when bent.
    func kneeAngle(_ side: Side) -> Double? {
        switch side {
        case .left: angle(.leftHip, .leftKnee, .leftAnkle)
        case .right: angle(.rightHip, .rightKnee, .rightAnkle)
        }
    }

    /// Elbow angle (shoulder–elbow–wrist). ~180° straight, smaller when bent.
    func elbowAngle(_ side: Side) -> Double? {
        switch side {
        case .left: angle(.leftShoulder, .leftElbow, .leftWrist)
        case .right: angle(.rightShoulder, .rightElbow, .rightWrist)
        }
    }

    /// Hip angle (shoulder–hip–knee), averaged over both sides. ~180° when the body
    /// is straight (a good plank), smaller when piked or sagging.
    func hipAngle() -> Double? {
        let left = angle(.leftShoulder, .leftHip, .leftKnee)
        let right = angle(.rightShoulder, .rightHip, .rightKnee)
        switch (left, right) {
        case let (l?, r?): return (l + r) / 2
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }
}
