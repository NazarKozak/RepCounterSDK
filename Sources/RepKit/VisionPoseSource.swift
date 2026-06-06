//
//  VisionPoseSource.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  Free, on-device body-pose landmarks via Apple's Vision framework
//  (VNDetectHumanBodyPoseRequest). No SDK key, no cloud.
//

#if canImport(Vision)
import Vision
import CoreVideo
import CoreGraphics

/// Extracts ``PoseLandmarks`` from an image using `VNDetectHumanBodyPoseRequest`.
public struct VisionPoseSource: Sendable {
    /// Joints below this confidence are dropped.
    public let minimumConfidence: Float

    public init(minimumConfidence: Float = 0.1) {
        self.minimumConfidence = minimumConfidence
    }

    /// Detects the most prominent body in a pixel buffer.
    public func landmarks(in pixelBuffer: CVPixelBuffer,
                          orientation: CGImagePropertyOrientation = .up) -> PoseLandmarks? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        try? handler.perform([request])
        guard let observation = request.results?.first else { return nil }
        return map(observation)
    }

    private func map(_ observation: VNHumanBodyPoseObservation) -> PoseLandmarks? {
        guard let recognized = try? observation.recognizedPoints(.all) else { return nil }
        var points: [Joint: CGPoint] = [:]
        var confidence: [Joint: Double] = [:]
        for (joint, name) in Self.mapping {
            guard let point = recognized[name], point.confidence >= minimumConfidence else { continue }
            points[joint] = point.location
            confidence[joint] = Double(point.confidence)
        }
        return points.isEmpty ? nil : PoseLandmarks(points: points, confidence: confidence)
    }

    private static let mapping: [Joint: VNHumanBodyPoseObservation.JointName] = [
        .nose: .nose,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle
    ]
}
#endif
