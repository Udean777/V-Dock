# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Mini Logcat Viewer**: A dedicated, native macOS window that streams logs in real-time (`adb logcat` / `simctl log`), featuring syntax highlighting, auto-scroll, and live filtering.
- **Factory Reset & Cold Boot**: Wipe simulator data or perform a cold boot on Android emulators instantly without opening your IDE.
- **Quick Media Capture**: Take screenshots or screen recordings of the active device and save them straight to your Desktop with one click.
- **Appearance Toggles**: Instantly switch your running devices between Dark Mode and Light Mode directly from the context menu.
- **Advanced Architecture**: Integrated Clean Architecture for modular and scalable iOS/macOS development.
- **Hybrid Menu Bar App**: Dynamically switches between `.accessory` and `.regular` application states to hide the Dock icon unless the Dashboard is open.

### Fixed
- Stabilized `Cmd+W` and `Cmd+Q` shortcuts across all V-Dock windows via low-level `NSEvent` monitors and `NSWindow.willCloseNotification` observers.
- Resolved memory leaks and zombie window bugs commonly found in SwiftUI Menu Bar extras.

## [1.0.0] - Initial Foundation
### Added
- Dashboard and Menu Bar interfaces for quick access to iOS and Android Emulators.
- Boot, Shutdown, and Force Kill device capabilities.
- Real-time CPU & Memory monitoring for active devices.
- Automatic Android SDK path detection and configuration view.
