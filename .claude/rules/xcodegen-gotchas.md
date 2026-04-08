---
paths:
  - "project.yml"
  - "**/*.plist"
---

# xcodegen & Build System Gotchas

1. **Info.plist keys in project.yml** — Use `INFOPLIST_KEY_` prefix in `settings.base` for plist entries. Bare keys like `NSSupportsLiveActivities: true` become meaningless build settings. Must be `INFOPLIST_KEY_NSSupportsLiveActivities: true`.

2. **Widget extension Info.plist** — `NSExtension.NSExtensionPointIdentifier` must be set via `info.properties` in project.yml (NOT via `INFOPLIST_KEY_*` build settings). Different pattern from the main app.

3. **Shared files between targets** — `TimerPhase.swift`, `SoundEvent.swift`, and `TimerActivityAttributes.swift` are listed in both the app and widget extension sources in `project.yml`. When adding new `SoundEvent` cases, the widget extension must still compile (it has no AudioManager).

4. **iPad orientations required** — `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` must include all 4 orientations for App Store submission, even though the app is iPhone-only.

5. **App icon no alpha** — `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` points to `Assets.xcassets/AppIcon.appiconset/`. The PNG must have no alpha channel or App Store rejects the upload.
