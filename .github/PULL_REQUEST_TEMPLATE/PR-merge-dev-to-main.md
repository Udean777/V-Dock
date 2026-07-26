# feat: cross-platform file transfer & app installer, push notifications, ADB serial, remove deprecated features, refactor all views, and consolidate CI/CD (v1.1.0)

## Description

Comprehensive update from dev to main. Introduces cross-platform file transfer with drag-and-drop app installation, macOS push notifications, and ADB serial resolution. Removes incomplete features (screen mirroring, network sniffer/proxy). Refactors all 14+ view layouts for consistency. Consolidates CI/CD into a single version-gated release workflow. Version bumped from 1.0 to 1.1.0.

---

**Commits (7):**

| Commit | Description |
|--------|-------------|
| `e860282` | feat(file-transfer): implement cross-platform drag-and-drop bulk file push |
| `1056265` | feat: add cross-platform app installer, push notifications, and ADB serial resolution; remove deprecated features |
| `287b21c` | refactor(views): clean up all view layouts, rename QRScannerView, add release CI/CD, update docs, and bump to v1.1.0 |
| `79f912e` | fix(release): add permissions and GITHUB_TOKEN for GitHub Release action |
| `96d4f3b` | refactor(release): update release workflow to improve DMG creation and installation guide |

**Diff:** 48 files changed, 1480 insertions, 1865 deletions

---

### New Features

- **Cross-Platform File Transfer & App Installer** — Drag & drop files or `.apk`/`.app` onto device cards. Auto-installs apps, smart-routes media to Photos and documents to Files.
- **Push Notifications** — Native macOS notifications for device boot, screenshot/recording, file transfer, and wireless pairing events via `NotificationManager`.
- **ADB Serial Resolution** — `adbSerial(for:)` maps AVD names to ADB transport serials (`emulator-5554`), fixing multi-device screenshot/recording/toggle.
- **Physical Device Detection** — `isPhysical` flag on `Device` for platform-appropriate UI.

### Removed Features

- **Screen Mirroring** — Removed `ScreenMirrorView`, `ScreenMirrorUseCase`, `ScreenMirrorProtocol`, `AndroidScreenMirror`, `ScrcpyStreamManager`.
- **Network Sniffer / Proxy** — Removed `NetworkSnifferView`, `NetworkSnifferUseCase`, `NetworkProxyUseCase`, `LocalProxyServer`, `NetworkTraffic`, and related protocols.
- **DestructiveActionAlert** — Replaced with native SwiftUI `.alert`.
- **Cleanup** — Deleted `scripts/setup_minicap.sh`, `IMPLEMENTATION_PLAN_DEVTOOLS.md`, `IMPLEMENTATION_PLAN_NETWORK_SNIFFER.md`, `build-dmg.yml`.

### View Layout Refactoring (14 files)

All Presentation views reorganized for consistency:

| View | Key Changes |
|------|-------------|
| **MenuBarView** | Device actions → overflow menu (`⋯`), generic `SectionHeader<Trailing>`, context menu unified, footer compact |
| **DashboardView** | `platformSection()` → `PlatformSection` subview, reusable `errorBanner()` |
| **DeviceCardView** | Context menu unified iOS/Android |
| **PairDeviceView** | Redundant buttons removed, `doneView` layout improved |
| **LogcatView** | `.task` replaces `onAppear`/`onDisappear` |
| **MenuBarLabel** | Computed property replaces `@State` + `onChange` |
| **DashboardSidebarView** | `bootAll`/`shutdownAll` → `bulkAction(_:)` |
| **ResourceBarView** | Reusable `MetricRow`, CPU uses own fraction |
| **StatusBadgeView** | Computed properties made `private` |
| **SettingsSDKView** | Extracted `sdkPathBinding` computed property |
| **SettingsGeneralView** | Removed duplicate About section |
| **SettingsView** | Removed unused `SettingsTab` enum |
| **SettingsAboutView** | Consolidated text |
| **QRScannerView** | Renamed to `QRCodeDisplayView` |

### CI/CD Consolidation

- **Deleted** `build-dmg.yml` (old workflow, ran on every push)
- **Enhanced** `release.yml`:
  - Only builds + releases when `MARKETING_VERSION` changes in `project.pbxproj`
  - Uses `create-dmg` for polished DMG with drag-drop install UI
  - Includes `INSTALL_GUIDE.txt` for unsigned app Gatekeeper bypass
  - Publishes official GitHub Release with auto-generated release notes
  - Also supports manual `workflow_dispatch` trigger

### Documentation

- Updated README: removed screen mirroring section, added overflow menu and notification docs, renumbered context actions, added experimental warning for auto app installation.

### Version

`MARKETING_VERSION` bumped from `1.0` to `1.1.0` (Debug + Release).

---

## Breaking Changes

- Screen mirroring and network sniffer/proxy features are **removed**. Code referencing `ScreenMirrorUseCase`, `ScreenMirrorView`, `NetworkSnifferView`, `NetworkProxyUseCase`, or `LocalProxyServer` will not compile.
- `build-dmg.yml` removed — replaced by consolidated `release.yml`.

---

## Type of change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [x] New feature (non-breaking change which adds functionality)
- [x] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [x] This change requires a documentation update

## Architectural Compliance

- [x] My code follows the Clean Architecture layers (Presentation, Domain, Data)
- [x] I have avoided adding raw shell commands to SwiftUI Views
- [x] I have used the Dependency Container for injections

## Checklist:

- [x] My code follows the style guidelines of this project
- [x] I have performed a self-review of my code
- [x] I have commented my code, particularly in hard-to-understand areas
- [x] I have made corresponding changes to the documentation
- [x] My changes generate no new Xcode warnings
- [x] I have tested that my features work on both macOS 14+ and the latest Xcode version
