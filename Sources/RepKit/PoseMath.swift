//
//  PoseMath.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import CoreGraphics
import Foundation

/// Small geometry helpers for joint-angle calculations.
enum PoseMath {
    /// The interior angle (degrees, 0…180) at vertex `b` formed by points `a`–`b`–`c`.
    static func angle(at b: CGPoint, from a: CGPoint, to c: CGPoint) -> Double {
        let ba = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let bc = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = Double(ba.dx * bc.dx + ba.dy * bc.dy)
        let magBA = Double((ba.dx * ba.dx + ba.dy * ba.dy).squareRoot())
        let magBC = Double((bc.dx * bc.dx + bc.dy * bc.dy).squareRoot())
        guard magBA > 0, magBC > 0 else { return .nan }
        let cosine = max(-1.0, min(1.0, dot / (magBA * magBC)))
        return acos(cosine) * 180.0 / .pi
    }

    /// Maps `value` from the range `[from, to]` to `[0, 1]`, clamped. `from` may be
    /// greater than `to` (inverse mapping), which is how a shrinking joint angle maps
    /// to increasing "depth".
    static func normalize(_ value: Double, from: Double, to: Double) -> Double {
        guard from != to else { return 0 }
        let t = (value - from) / (to - from)
        return max(0, min(1, t))
    }
}
