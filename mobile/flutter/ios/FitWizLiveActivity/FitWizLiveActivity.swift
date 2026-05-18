//
//  ZealovaLiveActivity.swift
//  ZealovaLiveActivity
//
//  Shared attributes + state helpers for the Live Activity. The actual
//  widget body lives in ZealovaLiveActivityLiveActivity.swift.
//

import ActivityKit
import Foundation

// MARK: - ActivityAttributes
//
// Struct name MUST remain exactly `LiveActivitiesAppAttributes` — the
// `live_activities` pub.dev package hardcodes this name when routing
// ActivityKit updates. Renaming breaks the display.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public struct ContentState: Codable, Hashable {}
    var id = UUID()
}

// MARK: - Workout state read from App Group UserDefaults
//
// The Dart-side LiveActivityService writes a Map<String, dynamic> via the
// package; the package persists it in UserDefaults(suite: group.zealova.liveactivity).
// We read it back here on every SwiftUI re-render.
struct WorkoutLiveActivityState {
    let workoutName: String
    let currentExercise: String
    let currentExerciseIndex: Int
    let totalExercises: Int
    let currentSet: Int
    let totalSets: Int
    let isResting: Bool
    let restEndsAt: Date?
    let isPaused: Bool
    let startedAt: Date
    let pausedDurationSeconds: Int

    /// Wall-clock anchor for the native elapsed-time clock; shifts forward
    /// by total paused seconds so `Text(timerInterval:)` shows the correct
    /// active-workout elapsed time.
    var effectiveStartedAt: Date {
        startedAt.addingTimeInterval(TimeInterval(pausedDurationSeconds))
    }

    /// Fractional progress through the workout based on current exercise index.
    var progressFraction: Double {
        guard totalExercises > 0 else { return 0 }
        let clamped = max(1, min(currentExerciseIndex, totalExercises))
        return Double(clamped - 1) / Double(totalExercises)
    }

    static func current(
        appGroupId: String = "group.zealova.liveactivity"
    ) -> WorkoutLiveActivityState? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return nil
        }
        guard let name = defaults.string(forKey: "workoutName"),
              let currentExercise = defaults.string(forKey: "currentExercise") else {
            return nil
        }
        let currentExerciseIndex = defaults.integer(forKey: "currentExerciseIndex")
        let totalExercises = defaults.integer(forKey: "totalExercises")
        let currentSet = defaults.integer(forKey: "currentSet")
        let totalSets = defaults.integer(forKey: "totalSets")
        let isResting = (defaults.string(forKey: "isResting") ?? "false") == "true"
        let isPaused = (defaults.string(forKey: "isPaused") ?? "false") == "true"
        let startedAtMs = defaults.integer(forKey: "startedAtEpochMs")
        let restEndsAtMs = defaults.integer(forKey: "restEndsAtEpochMs")
        let pausedDurationSeconds = defaults.integer(forKey: "pausedDurationSeconds")

        let startedAt = startedAtMs > 0
            ? Date(timeIntervalSince1970: Double(startedAtMs) / 1000)
            : Date()
        let restEndsAt = restEndsAtMs > 0
            ? Date(timeIntervalSince1970: Double(restEndsAtMs) / 1000)
            : nil

        return WorkoutLiveActivityState(
            workoutName: name,
            currentExercise: currentExercise,
            currentExerciseIndex: currentExerciseIndex,
            totalExercises: totalExercises,
            currentSet: currentSet,
            totalSets: totalSets,
            isResting: isResting,
            restEndsAt: restEndsAt,
            isPaused: isPaused,
            startedAt: startedAt,
            pausedDurationSeconds: pausedDurationSeconds
        )
    }
}

// MARK: - Activity kind discriminator
//
// The single `live_activities` App Group payload is shared between the
// workout and fasting surfaces. The Dart side writes an `activityKind` key
// ("workout" — implicit/absent — or "fasting"); the widget branches on it.
enum LiveActivityKind {
    case workout
    case fasting

    static func current(
        appGroupId: String = "group.zealova.liveactivity"
    ) -> LiveActivityKind {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return .workout
        }
        return defaults.string(forKey: "activityKind") == "fasting"
            ? .fasting
            : .workout
    }
}

// MARK: - Fasting state read from App Group UserDefaults
//
// Mirrors `FastingActivityState.toPackagePayload()` on the Dart side.
struct FastingLiveActivityState {
    let protocolName: String
    let stageName: String
    let stageDescription: String
    let startedAt: Date
    let goalEndsAt: Date
    let goalDurationMinutes: Int
    let isPaused: Bool
    let pausedSeconds: Int

    /// Wall-clock anchor for the native elapsed clock — shifts forward by
    /// total paused seconds so `Text(timerInterval:)` shows pause-aware
    /// elapsed fasting time.
    var effectiveStartedAt: Date {
        startedAt.addingTimeInterval(TimeInterval(pausedSeconds))
    }

    /// The goal time shifted by paused seconds (matches the elapsed anchor).
    var effectiveGoalEndsAt: Date {
        goalEndsAt.addingTimeInterval(TimeInterval(pausedSeconds))
    }

    /// Fractional progress through the fast (0...1).
    var progressFraction: Double {
        guard goalDurationMinutes > 0 else { return 0 }
        let elapsed = Date.now.timeIntervalSince(effectiveStartedAt)
        let goal = Double(goalDurationMinutes) * 60.0
        return min(1.0, max(0.0, elapsed / goal))
    }

    static func current(
        appGroupId: String = "group.zealova.liveactivity"
    ) -> FastingLiveActivityState? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return nil
        }
        guard let stageName = defaults.string(forKey: "fastStageName") else {
            return nil
        }
        let protocolName = defaults.string(forKey: "fastProtocolName") ?? "Fast"
        let stageDescription =
            defaults.string(forKey: "fastStageDescription") ?? ""
        let startedAtMs = defaults.integer(forKey: "fastStartedAtEpochMs")
        let goalEndsAtMs = defaults.integer(forKey: "fastGoalEndsAtEpochMs")
        let goalDurationMinutes =
            defaults.integer(forKey: "fastGoalDurationMinutes")
        let isPaused =
            (defaults.string(forKey: "fastIsPaused") ?? "false") == "true"
        let pausedSeconds = defaults.integer(forKey: "fastPausedSeconds")

        let startedAt = startedAtMs > 0
            ? Date(timeIntervalSince1970: Double(startedAtMs) / 1000)
            : Date()
        let goalEndsAt = goalEndsAtMs > 0
            ? Date(timeIntervalSince1970: Double(goalEndsAtMs) / 1000)
            : startedAt.addingTimeInterval(Double(goalDurationMinutes) * 60)

        return FastingLiveActivityState(
            protocolName: protocolName,
            stageName: stageName,
            stageDescription: stageDescription,
            startedAt: startedAt,
            goalEndsAt: goalEndsAt,
            goalDurationMinutes: goalDurationMinutes,
            isPaused: isPaused,
            pausedSeconds: pausedSeconds
        )
    }
}
