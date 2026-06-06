//
//  RepDetector.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import Foundation
import QuartzCore
#if canImport(Vision)
import CoreVideo
import CoreGraphics
#endif

/// Counts reps / tracks holds for an ``Exercise`` from a stream of poses.
///
/// Feed it landmarks (from any source) or, on Apple platforms, a camera pixel
/// buffer it will run through ``VisionPoseSource``.
///
/// ```swift
/// let detector = RepDetector(exercise: .squat)
/// for await frame in camera.frames {
///     switch detector.process(frame) {        // CVPixelBuffer
///     case .rep(let n):       print("reps:", n)
///     case .formIssue(let m): print(m)
///     default: break
///     }
/// }
/// ```
///
/// Not thread-safe: feed frames from a single queue.
public final class RepDetector: @unchecked Sendable {
    public let exercise: Exercise
    private let engine: any ExerciseEngine

    public init(exercise: Exercise) {
        self.exercise = exercise
        self.engine = exercise.makeEngine()
    }

    /// Running rep count (or seconds held for timed exercises).
    public var count: Int { engine.count }

    public func reset() { engine.reset() }

    /// Feeds a detected pose. `time` is used by timed exercises (plank).
    @discardableResult
    public func process(_ landmarks: PoseLandmarks, at time: TimeInterval = CACurrentMediaTime()) -> RepUpdate {
        engine.update(landmarks, at: time)
    }

    #if canImport(Vision)
    private let vision = VisionPoseSource()

    /// Runs Vision body-pose detection on `pixelBuffer`, then updates the detector.
    /// Runs synchronously — call from a background/camera queue, not the main thread.
    @discardableResult
    public func process(_ pixelBuffer: CVPixelBuffer,
                        orientation: CGImagePropertyOrientation = .up,
                        at time: TimeInterval = CACurrentMediaTime()) -> RepUpdate {
        guard let landmarks = vision.landmarks(in: pixelBuffer, orientation: orientation) else { return .idle }
        return process(landmarks, at: time)
    }
    #endif
}
