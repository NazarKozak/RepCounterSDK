# Changelog

All notable changes to RepKit are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow SemVer.

## [0.2.0] - 2026-06-06

### Added
- Exercises: `.lunge`, `.bicepCurl`, `.shoulderPress`.
- Custom-exercise DSL — `ExerciseSpec.reps`/`.hold` with a progress signal and
  optional anti-cheat `Gate`s; `RepDetector(spec:)`. All built-ins now compile to
  a spec interpreted by one engine.
- `PoseLandmarks.depth(of:standing:deep:)` helper.
- `RepKitDemo` Xcode project — live camera, skeleton overlay, exercise picker,
  rep counter and form tips.

## [0.1.0] - 2026-06-05

Initial public release.

### Added
- `RepDetector` — counts reps / tracks holds for an `Exercise` from poses or, on
  Apple platforms, a camera pixel buffer.
- `VisionPoseSource` — free on-device body-pose landmarks via Apple Vision
  (`VNDetectHumanBodyPoseRequest`), no SDK key.
- Exercises: `.squat`, `.pushUp` (hysteresis main counter + dual-joint anti-cheat
  validation), `.plank` (timed hold).
- `ThresholdCounter` (hysteresis) and `ThresholdTimer` primitives.
- `PoseLandmarks` with joint-angle helpers (`kneeAngle`, `elbowAngle`, `hipAngle`).
- Tests for the angle math, counter hysteresis, and the squat anti-cheat path.
