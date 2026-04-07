import Foundation

@Observable
class WorkoutHistoryStore {
    private(set) var records: [WorkoutRecord] = []
    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("workout_history.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder().decode([WorkoutRecord].self, from: data)
        } catch {
            print("Failed to load workout history: \(error)")
        }
    }

    func save() {
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
