# RepKit

[![CI](https://github.com/NazarKozak/RepKit/actions/workflows/ci.yml/badge.svg)](https://github.com/NazarKozak/RepKit/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2012%2B-blue.svg)
![SPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**Count exercise reps on-device, for free — no SDK key, no cloud.**

RepKit turns Apple Vision body-pose landmarks into rep counts and form feedback. It's the open, MIT-licensed alternative to paid pose-fitness SDKs: everything runs on the Neural Engine, nothing leaves the phone, and there's no key to register.

```swift
import RepKit

let detector = RepDetector(exercise: .squat)

// Feed camera frames (e.g. from an AVCaptureSession), on a background queue:
switch detector.process(pixelBuffer) {
case .rep(let count):      print("reps:", count)
case .formIssue(let tip):  print(tip)            // e.g. "Bend both knees fully"
case .holding(let seconds): print("plank:", seconds)
case .idle: break
}
```

## Why RepKit

| | Paid pose SDKs | **RepKit** |
|---|:---:|:---:|
| On-device | ✅ | ✅ |
| SDK key / account required | ❌ (key) | ✅ none |
| Cost | 💸 | free (MIT) |
| Rep counter + form feedback | ✅ | ✅ |
| Anti-cheat (both sides must engage) | ⚠️ | ✅ |
| Extra model download / app size | ⚠️ | none (Apple Vision) |

## What makes the counting good

RepKit isn't a thin wrapper over landmarks — the rep logic is the point:

- **Hysteresis counting** — a rep only counts on a full *rise past `enter`* then *fall past `exit`*; the gap rejects frame jitter so noise can't double-count.
- **Dual-joint anti-cheat** — for symmetric moves (squat, push-up), each side has its own angle-gated counter, and a rep is only credited when **both sides** reached the bottom. Half-reps and one-sided cheating are rejected with a form tip.
- **Angle-gated depth** — reps register only when the relevant joint actually bent past a threshold (e.g. knees < 140°).
- **Timed holds** — planks accumulate seconds while the body stays straight.

## Install

```swift
.package(url: "https://github.com/NazarKozak/RepKit.git", from: "0.1.0")
```

…and add `"RepKit"` to your target. Requires iOS 17+ / macOS 12+.

## Exercises

Built in: `.squat`, `.pushUp`, `.lunge`, `.bicepCurl`, `.shoulderPress`, `.plank`.

### Define your own (DSL)

Every exercise — built-in or custom — is an `ExerciseSpec`: a 0…1 progress signal plus
optional anti-cheat gates. Define one in a few lines:

```swift
let deepSquat = ExerciseSpec.reps(
    name: "Deep squat",
    formTip: "Bend both knees fully",
    gates: [Gate.bent({ $0.kneeAngle($1) }, .left,  below: 120),
            Gate.bent({ $0.kneeAngle($1) }, .right, below: 120)],
    progress: { $0.depth(of: $0.kneeAngle, standing: 160, deep: 80) }
)

let plank = ExerciseSpec.hold(name: "Plank") { pose in
    pose.hipAngle().map { ($0 - 140) / 40 }   // straight body → ~1
}

let detector = RepDetector(spec: deepSquat)
```

## Usage

### From a camera pixel buffer (Apple Vision)

```swift
let detector = RepDetector(exercise: .pushUp)
// In your AVCaptureVideoDataOutput delegate (background queue):
let update = detector.process(sampleBuffer.imageBuffer!, orientation: .right)
```

`process(_:)` runs `VNDetectHumanBodyPoseRequest` synchronously — call it off the main thread.

### From your own landmarks

Already have pose points (Vision, ARKit, a custom model)? Feed them directly:

```swift
let landmarks = PoseLandmarks(points: [
    .leftHip: hip, .leftKnee: knee, .leftAnkle: ankle, /* … */
])
let update = detector.process(landmarks)
```

`RepKit` only uses joint **angles**, so any consistent normalized coordinate space works.

## API

- `RepDetector(exercise:)` — `process(_:) -> RepUpdate`, `count`, `reset()`.
- `RepUpdate` — `.rep(count:)`, `.holding(seconds:)`, `.formIssue(_)`, `.idle`.
- `VisionPoseSource` — standalone Apple Vision → `PoseLandmarks`.
- `ThresholdCounter` / `ThresholdTimer` — the reusable hysteresis primitives.
- `PoseLandmarks` — joint points + angle helpers (`kneeAngle`, `elbowAngle`, `hipAngle`).

## Roadmap

- [x] Squat, push-up, lunge (dual-joint anti-cheat), plank (timed hold)
- [x] Bicep curl, shoulder press
- [x] Apple Vision landmark source, free & on-device
- [x] Hysteresis counter + threshold timer primitives
- [x] Custom-exercise DSL (`ExerciseSpec.reps`/`.hold`)
- [x] SwiftUI demo: live camera, skeleton overlay, rep counter
- [ ] Leg raise, jumping jack, sit-up
- [ ] Rep tempo / range-of-motion analytics

## License

MIT — see [LICENSE](LICENSE).
