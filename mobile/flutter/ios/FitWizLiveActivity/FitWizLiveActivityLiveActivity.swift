//
//  FitWizLiveActivityLiveActivity.swift
//  FitWizLiveActivity
//
//  The active-workout Live Activity.
//  Renders Lock Screen / Banner (all iPhones) + Dynamic Island
//  (compact / minimal / expanded) on iPhone 14 Pro+.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct FitWizLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { _ in
            // ── Lock Screen / Banner ──────────────────────────────────
            WorkoutLockScreenView(state: WorkoutLiveActivityState.current())
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { _ in
            let state = WorkoutLiveActivityState.current()

            return DynamicIsland {
                // ── Expanded ─────────────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label {
                            Text(state?.currentExercise ?? "Workout")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "dumbbell.fill")
                                .foregroundStyle(.orange)
                        }
                        if let s = state {
                            Text("Set \(s.currentSet)/\(s.totalSets)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let s = state, s.isResting, let restEnds = s.restEndsAt {
                        Text(timerInterval: Date.now...restEnds, countsDown: true)
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.red)
                            .frame(width: 78, alignment: .trailing)
                    } else if let s = state {
                        Text(s.effectiveStartedAt, style: .timer)
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(s.isPaused ? .gray : .white)
                            .frame(width: 78, alignment: .trailing)
                    } else {
                        Text("--:--").font(.title2.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if let s = state {
                        Text(s.workoutName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        if let s = state {
                            ProgressView(value: s.progressFraction)
                                .tint(.orange)
                            HStack {
                                Text(
                                    s.isPaused
                                    ? "⏸ Paused"
                                    : (s.isResting ? "Resting" : "In Progress")
                                )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                Spacer()
                                Text("Ex \(s.currentExerciseIndex)/\(s.totalExercises)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                if let s = state, s.isResting, let restEnds = s.restEndsAt {
                    Text(timerInterval: Date.now...restEnds, countsDown: true)
                        .monospacedDigit()
                        .foregroundStyle(.red)
                        .frame(width: 42)
                } else if let s = state {
                    Text(s.effectiveStartedAt, style: .timer)
                        .monospacedDigit()
                        .foregroundStyle(s.isPaused ? .gray : .primary)
                        .frame(width: 42)
                } else {
                    Text("--:--").monospacedDigit()
                }
            } minimal: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.orange)
            }
            .widgetURL(URL(string: "fitwiz://active-workout"))
            .keylineTint(.orange)
        }
    }
}

// MARK: - Lock Screen / Banner

private struct WorkoutLockScreenView: View {
    let state: WorkoutLiveActivityState?

    var body: some View {
        if let s = state {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Text(s.workoutName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    statusBadge(for: s)
                }

                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.currentExercise)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                        Text(
                            "Set \(s.currentSet)/\(s.totalSets)  ·  Exercise \(s.currentExerciseIndex)/\(s.totalExercises)"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if s.isResting, let restEnds = s.restEndsAt {
                        Text(timerInterval: Date.now...restEnds, countsDown: true)
                            .font(.largeTitle.weight(.bold).monospacedDigit())
                            .foregroundStyle(.red)
                    } else {
                        Text(s.effectiveStartedAt, style: .timer)
                            .font(.largeTitle.weight(.bold).monospacedDigit())
                            .foregroundStyle(s.isPaused ? .gray : .white)
                    }
                }

                ProgressView(value: s.progressFraction)
                    .tint(.orange)
            }
            .padding(16)
        } else {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.orange)
                Text("Workout in progress")
                    .font(.headline)
                Spacer()
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func statusBadge(for s: WorkoutLiveActivityState) -> some View {
        let (label, color): (String, Color) = {
            if s.isPaused { return ("Paused", .gray) }
            if s.isResting { return ("Resting", .red) }
            return ("Active", .green)
        }()
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }
}
