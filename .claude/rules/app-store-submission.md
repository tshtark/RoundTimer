---
paths:
  - "project.yml"
  - "docs/ship-summary.md"
---

# App Store Submission Requirements

Lessons learned from V1.0 submission (April 8, 2026).

## Before archiving
- App icon PNG must have NO alpha channel (flatten with PIL or sips onto opaque background)
- iPad orientations must be declared even for iPhone-only apps: all 4 orientations in `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`
- Export compliance: select "None of the algorithms" (app uses zero encryption, zero network)
- Content rights: "Does not contain third-party content"

## Screenshots
- iPhone: 1284x2778 (6.7" display) or 1242x2688 (6.5" display)
- iPad: 2048x2732 (required even for iPhone-only apps — resize iPhone screenshots with black letterboxing)
- Minimum 3 screenshots per device class

## Archive and upload command
```bash
xcodebuild archive -project RoundTimer.xcodeproj -scheme RoundTimer \
  -destination 'generic/platform=iOS' -archivePath /tmp/RoundTimer.xcarchive \
  -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath /tmp/RoundTimer.xcarchive \
  -exportOptionsPlist /tmp/ExportOptions.plist -exportPath /tmp/RoundTimerExport \
  -allowProvisioningUpdates
```

ExportOptions.plist needs: `method: app-store-connect`, `teamID: JVZFL2WCHV`, `destination: upload`.

## App Store Connect
- URL: https://appstoreconnect.apple.com/apps/6761851794
- Privacy: "Data Not Collected"
- Age rating: 4+ (no mature content)
- Privacy policy: https://tshtark.github.io/RoundTimer/privacy-policy.html
