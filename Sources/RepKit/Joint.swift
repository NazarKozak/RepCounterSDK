//
//  Joint.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//

import Foundation

/// Body side, for symmetric exercises.
public enum Side: Sendable, Hashable {
    case left
    case right
}

/// The body joints RepKit reasons about (a subset of Vision's body-pose points).
public enum Joint: Sendable, Hashable {
    case nose
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle
}
