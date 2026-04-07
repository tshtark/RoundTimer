import Foundation

@Observable
class PresetStore {
    private(set) var presets: [TimerPreset] = []
    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documents.appendingPathComponent("presets.json")
        load()
    }

    func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode([TimerPreset].self, from: data)
                presets = decoded
            } catch {
                presets = Self.defaultPresets()
                save()
            }
        } else {
            presets = Self.defaultPresets()
            save()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save presets: \(error)")
        }
    }

    func add(_ preset: TimerPreset) {
        presets.append(preset)
        save()
    }

    func update(_ preset: TimerPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            save()
        }
    }

    func delete(_ preset: TimerPreset) {
        guard !preset.isBuiltIn else { return }
        presets.removeAll { $0.id == preset.id }
        save()
    }

    func markUsed(_ preset: TimerPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index].lastUsedAt = Date()
            save()
        }
    }

    // MARK: - Factory Templates

    static func defaultPresets() -> [TimerPreset] {
        [
            TimerPreset(
                name: "Tabata",
                intervals: [
                    TimerInterval(phase: .work, duration: 20),
                    TimerInterval(phase: .rest, duration: 10),
                ],
                rounds: 8,
                isBuiltIn: true
            ),
            TimerPreset(
                name: "Boxing",
                intervals: [
                    TimerInterval(phase: .work, duration: 180),
                    TimerInterval(phase: .rest, duration: 60),
                ],
                rounds: 12,
                isBuiltIn: true
            ),
            TimerPreset(
                name: "EMOM",
                intervals: [
                    TimerInterval(phase: .work, duration: 60),
                ],
                rounds: 10,
                isBuiltIn: true
            ),
            TimerPreset(
                name: "AMRAP 10min",
                intervals: [
                    TimerInterval(phase: .work, duration: 600),
                ],
                rounds: 1,
                isBuiltIn: true
            ),
            TimerPreset(
                name: "Custom",
                intervals: [
                    TimerInterval(phase: .work, duration: 30),
                    TimerInterval(phase: .rest, duration: 15),
                ],
                rounds: 5,
                warmup: 10,
                cooldown: 10,
                isBuiltIn: true
            ),
        ]
    }
}
