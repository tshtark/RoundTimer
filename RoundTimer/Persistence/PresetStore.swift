import Foundation

@MainActor
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
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            presets = Self.defaultPresets()
            save()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            presets = try JSONDecoder().decode([TimerPreset].self, from: data)
            if migrateBuiltIns() {
                save()
            }
        } catch {
            // CRITICAL: Do not silently overwrite a corrupt file. The original
            // behaviour replaced presets.json with factory defaults on ANY decode
            // failure — destroying every custom preset the user had saved. Back
            // up the corrupt bytes first so they're at least recoverable from
            // the documents directory if a user reports lost data.
            print("[PresetStore] decode failed: \(error)")
            let timestamp = Int(Date().timeIntervalSince1970)
            let backupURL = fileURL.appendingPathExtension("corrupt-\(timestamp)")
            do {
                try FileManager.default.copyItem(at: fileURL, to: backupURL)
                print("[PresetStore] backed up corrupt file to \(backupURL.lastPathComponent)")
            } catch {
                print("[PresetStore] failed to back up corrupt file: \(error)")
            }
            presets = Self.defaultPresets()
            save()
        }
    }

    /// Brings the loaded preset list in sync with `defaultPresets()`:
    ///
    /// 1. **Upgrade existing built-ins to stable IDs.** V1.0 shipped without
    ///    hardcoded UUIDs for built-ins, so each fresh install assigned random
    ///    IDs. Match by name and reassign the canonical ID (preserving the
    ///    user's `lastUsedAt`) so future versions have a stable identity to
    ///    target.
    /// 2. **Add any built-ins missing from the user's file.** Lets a future
    ///    update ship a new built-in (e.g. a CrossFit WOD) and have it appear
    ///    automatically for upgraders, not just brand-new installs.
    ///
    /// Returns `true` if anything changed and the caller should `save()`.
    private func migrateBuiltIns() -> Bool {
        var changed = false
        let defaults = Self.defaultPresets()

        // 1. Upgrade existing built-ins by matching on name. We only touch
        //    rows that are flagged isBuiltIn so a custom preset that happens
        //    to share a name (e.g. "Tabata") is left alone.
        for index in presets.indices where presets[index].isBuiltIn {
            let existing = presets[index]
            guard let canonical = defaults.first(where: { $0.name == existing.name }),
                  canonical.id != existing.id else { continue }
            presets[index] = TimerPreset(
                id: canonical.id,
                name: existing.name,
                intervals: existing.intervals,
                rounds: existing.rounds,
                warmup: existing.warmup,
                cooldown: existing.cooldown,
                isBuiltIn: true,
                lastUsedAt: existing.lastUsedAt
            )
            changed = true
        }

        // 2. Add any built-ins the user's file doesn't already contain.
        let existingIDs = Set(presets.map(\.id))
        for defaultPreset in defaults where !existingIDs.contains(defaultPreset.id) {
            presets.append(defaultPreset)
            changed = true
        }

        return changed
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

    /// Stable, hardcoded IDs for the V1.0 built-in presets.
    ///
    /// These must NEVER change once shipped — `migrateBuiltIns()` uses them as
    /// the canonical identity for each built-in. Adding a new built-in in a
    /// future version means appending a brand-new UUID below; rotating an
    /// existing one would orphan upgraders' "Recent" badges and double-up the
    /// preset on next launch.
    ///
    /// `?? UUID()` is a defensive belt-and-braces fallback for the (impossible)
    /// case where these literals fail to parse — it satisfies the project rule
    /// against force-unwraps without losing the stable identity for the happy
    /// path. If you ever see "duplicate built-ins" after a typo here, that's
    /// your fingerprint.
    private static let tabataID = UUID(uuidString: "A1B2C3D4-0001-4000-8000-000000000001") ?? UUID()
    private static let boxingID = UUID(uuidString: "A1B2C3D4-0002-4000-8000-000000000002") ?? UUID()
    private static let emomID = UUID(uuidString: "A1B2C3D4-0003-4000-8000-000000000003") ?? UUID()
    private static let amrapID = UUID(uuidString: "A1B2C3D4-0004-4000-8000-000000000004") ?? UUID()
    private static let customID = UUID(uuidString: "A1B2C3D4-0005-4000-8000-000000000005") ?? UUID()

    static func defaultPresets() -> [TimerPreset] {
        [
            TimerPreset(
                id: tabataID,
                name: "Tabata",
                intervals: [
                    TimerInterval(phase: .work, duration: 20),
                    TimerInterval(phase: .rest, duration: 10),
                ],
                rounds: 8,
                isBuiltIn: true
            ),
            TimerPreset(
                id: boxingID,
                name: "Boxing",
                intervals: [
                    TimerInterval(phase: .work, duration: 180),
                    TimerInterval(phase: .rest, duration: 60),
                ],
                rounds: 12,
                isBuiltIn: true
            ),
            TimerPreset(
                id: emomID,
                name: "EMOM",
                intervals: [
                    TimerInterval(phase: .work, duration: 60),
                ],
                rounds: 10,
                isBuiltIn: true
            ),
            TimerPreset(
                id: amrapID,
                name: "AMRAP 10min",
                intervals: [
                    TimerInterval(phase: .work, duration: 600),
                ],
                rounds: 1,
                isBuiltIn: true
            ),
            TimerPreset(
                id: customID,
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
