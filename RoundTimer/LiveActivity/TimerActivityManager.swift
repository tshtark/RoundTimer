import ActivityKit
import Foundation

@MainActor
class TimerActivityManager {
    static let shared = TimerActivityManager()

    private var activityId: String?

    func start(presetName: String, totalRounds: Int, phase: TimerPhase, intervalEndDate: Date, currentRound: Int, intervalName: String? = nil) {
        let authInfo = ActivityAuthorizationInfo()
        print("[LiveActivity] areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        print("[LiveActivity] frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")
        guard authInfo.areActivitiesEnabled else {
            print("[LiveActivity] Activities NOT enabled — skipping")
            return
        }

        let attributes = TimerActivityAttributes(
            presetName: presetName,
            totalRounds: totalRounds
        )

        let state = TimerActivityAttributes.ContentState(
            phase: phase.rawValue,
            phaseColorHex: phase.colorHex,
            currentRound: currentRound,
            intervalEndDate: intervalEndDate,
            intervalName: intervalName,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: intervalEndDate),
                pushType: nil
            )
            activityId = activity.id
            print("[LiveActivity] Started successfully, id: \(activity.id)")
        } catch {
            print("[LiveActivity] FAILED to start: \(error)")
        }
    }

    func update(phase: TimerPhase, currentRound: Int, intervalEndDate: Date, intervalName: String?, isPaused: Bool) {
        guard let activityId = activityId,
              let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId })
        else {
            print("[LiveActivity] update skipped: no tracked activity")
            return
        }

        let state = TimerActivityAttributes.ContentState(
            phase: phase.rawValue,
            phaseColorHex: phase.colorHex,
            currentRound: currentRound,
            intervalEndDate: intervalEndDate,
            intervalName: intervalName,
            isPaused: isPaused
        )

        let content = ActivityContent(state: state, staleDate: isPaused ? nil : intervalEndDate)
        nonisolated(unsafe) let unsafeActivity = activity
        Task {
            await unsafeActivity.update(content)
            print("[LiveActivity] Updated id: \(activityId) phase: \(phase.rawValue) paused: \(isPaused)")
        }
    }

    func end() {
        guard let activityId = activityId,
              let activity = Activity<TimerActivityAttributes>.activities.first(where: { $0.id == activityId })
        else {
            print("[LiveActivity] end skipped: no tracked activity")
            self.activityId = nil
            return
        }

        let finalState = TimerActivityAttributes.ContentState(
            phase: "complete",
            phaseColorHex: "#34C759",
            currentRound: 0,
            intervalEndDate: Date(),
            intervalName: nil,
            isPaused: false
        )

        let content = ActivityContent(state: finalState, staleDate: nil)
        nonisolated(unsafe) let unsafeActivity = activity
        let endingId = activityId
        Task {
            await unsafeActivity.end(content, dismissalPolicy: .default)
            print("[LiveActivity] Ended id: \(endingId)")
        }
        self.activityId = nil
    }

    /// Ends all Live Activities that aren't tracked by the current session.
    /// Call on app launch to clean up stale activities from a previous session (e.g., app was killed).
    func cleanupStaleActivities() {
        let activities = Activity<TimerActivityAttributes>.activities
        guard !activities.isEmpty else { return }

        // If we have a tracked activity that's still running, keep it
        let trackedId = activityId

        for activity in activities {
            if activity.id == trackedId { continue }
            print("[LiveActivity] Cleaning up stale activity: \(activity.id)")
            nonisolated(unsafe) let unsafeActivity = activity
            Task { await unsafeActivity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
