# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-07-26

### Added
- **Auto-Update**: Checks for new versions via GitHub Releases API. Menu bar status row + Dashboard modal with download progress, auto-install (replace app + relaunch), and non-mandatory dismissal.
- **Wireless ADB Pairing**: Pair Android 11+ devices over Wi-Fi using QR code or manual pairing code. Auto-discovers services on the local network via mDNS (`WirelessADBRepository`, `WirelessPairingUseCase`).
- **Cross-Platform File Transfer & App Installer**: Drag-and-drop or file-picker-based bulk file push to iOS Simulators and Android Emulators. Auto-installs `.apk` / `.app` bundles. Smart routing for media, documents, and unsupported formats (`PushFileUseCase`, `PushFileViewModel`, `AndroidPushFileRepository`, `IOSSimulatorPushFileRepository`).
- **Push Notifications**: macOS native `UNUserNotificationCenter` notifications for device boot complete, screenshot/recording saved, file transfer result, wireless pairing, and action failures (`NotificationManager`).
- **Screen Mirror**: Real-time Android emulator screen streaming via `minicap` binary (`MinicapManager`).
- **Mini Logcat Viewer**: A dedicated, native macOS window that streams logs in real-time (`adb logcat` / `simctl log`), featuring syntax highlighting, auto-scroll, and live filtering.
- **Factory Reset & Cold Boot**: Wipe simulator data or perform a cold boot on Android emulators instantly without opening your IDE.
- **Quick Media Capture**: Take screenshots or screen recordings of the active device and save them straight to your Desktop with one click.
- **Appearance Toggles**: Instantly switch your running devices between Dark Mode and Light Mode directly from the context menu.
- **Launch at Login**: System service integration via `SMAppService` to auto-start V-Dock on login.
- **Release CI/CD**: Automated GitHub Actions workflow (`release.yml`) that builds an unsigned DMG, generates install guide, and publishes a GitHub Release with auto-generated release notes.
- **ShellExecutor Streaming**: Real-time output streaming via `AsyncStream` for long-running processes (`stream()` method).
- **Quick Look Preview**: Dashboard device list with inline resource usage bars, platform grouping, collapsible sections, and bulk boot/shutdown per platform.

### Changed
- **Menu Bar**: Completely redesigned with device pinning, overflow menu (file push, screenshot, recording), section headers with counts, and inline progress indicators.
- **Dashboard**: Full navigation split view with sidebar (`DashboardSidebarView`), collapsible platform sections, device cards (`DeviceCardView`) with resource bars and quick actions.
- **Settings**: Redesigned with grouped form style, General tab (Launch at Login), Android SDK tab, and About tab with version info and macOS version display.
- **Destructive Alerts**: Replaced SwiftUI `.alert()` with native `NSAlert` for better focus handling on wipe/erase confirmations.
- **Architecture**: Clean Architecture applied throughout — Domain layer with Use Cases and Repository Protocols, Data layer with concrete Repositories and DataSources, Presentation layer with `@Observable` ViewModels.
- **Hybrid Activation Policy**: App launches as `.accessory` (menu bar only, no Dock icon), promotes to `.regular` when Dashboard/Settings windows open, reverts on last window close.

### Fixed
- Stabilized `Cmd+W` and `Cmd+Q` shortcuts across all V-Dock windows via low-level `NSEvent` monitors and `NSWindow.willCloseNotification` observers.
- Resolved memory leaks and zombie window bugs commonly found in SwiftUI Menu Bar extras.
- Window focus: All windows brought to front and activated on open; last window close correctly reverts to accessory mode.
- ADB serial resolution: Properly resolves device serials for multi-device setups.

### Removed
- `DestructiveActionAlert.swift` — replaced by native `NSAlert` confirmations.

## [1.0.0] - Initial Foundation
### Added
- Dashboard and Menu Bar interfaces for quick access to iOS and Android Emulators.
- Boot, Shutdown, and Force Kill device capabilities.
- Real-time CPU & Memory monitoring for active devices.
- Automatic Android SDK path detection and configuration view.
