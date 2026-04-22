//
//  FitWizLiveActivity.swift
//  FitWizLiveActivity
//
//  Shared attributes + state helpers for the Live Activity. The actual
//  widget body lives in FitWizLiveActivityLiveActivity.swift.
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
// package; the package persists it in UserDefaults(suite: group.fitwiz.liveactivity).
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
        appGroupId: String = "group.fitwiz.liveactivity"
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
