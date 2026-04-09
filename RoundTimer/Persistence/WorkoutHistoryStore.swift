import Foundation

@MainActor
@Observable
class WorkoutHistoryStore {
    private(set) var records: [WorkoutRecord] = []
    private let fileURL: URL
    /// True if the most recent load failed to decode. We refuse to overwrite
    /// the corrupt file via `save()` so the user's data is recoverable.
    private var loadFailed: Bool = false

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("workout_history.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            loadFailed = false
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder().decode([WorkoutRecord].self, from: data)
            loadFailed = false
        } catch {
            print("[WorkoutHistoryStore] decode failed: \(error)")
            // Back up the corrupt file so it isn't silently lost when the user
            // completes another workout (which would overwrite the same path).
            let timestamp = Int(Date().timeIntervalSince1970)
            let backupURL = fileURL.appendingPathExtension("corrupt-\(timestamp)")
            do {
                try FileManager.default.copyItem(at: fileURL, to: backupURL)
                print("[WorkoutHistoryStore] backed up corrupt file to \(backupURL.lastPathComponent)")
            } catch {
                print("[WorkoutHistoryStore] failed to back up corrupt file: \(error)")
            }
            loadFailed = true
        }
    }

    func save() {
        guard !loadFailed else {
            print("[WorkoutHistoryStore] refusing to save: previous load failed; corrupt file preserved")
            return
        }
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save workout history: \(error)")
        }
    }

    func add(_ record: WorkoutRecord) {
        records.insert(record, at: 0)
        save()
    }

    func clearAll() {
        records = []
        try? FileManager.default.removeItem(at: fileURL)
    }
}
