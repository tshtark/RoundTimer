import SwiftUI

struct HistoryView: View {
    var store: WorkoutHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Workouts Yet")
                            .font(.headline)
                        Text("Complete a workout and it will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.records) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.presetName)
                                        .font(.system(.title3, design: .rounded, weight: .semibold))
                                    HStack(spacing: 12) {
                                        Label(record.formattedDate, systemImage: "calendar")
                                        Label(record.formattedTime, systemImage: "clock")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(record.formattedDuration)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(TimerPhase.work.color)
                                    Text("\(record.roundsCompleted) \(record.roundsCompleted == 1 ? "round" : "rounds")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                if !store.records.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) {
                            showingClearConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog("Clear all workout history?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    store.clearAll()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    HistoryView(store: WorkoutHistoryStore())
}
