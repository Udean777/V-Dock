<div align="center">
  <img src="assets/logo.png" width="100" alt="V-Dock Logo">
  <h1>V-Dock</h1>
  <p><strong>The Ultimate macOS Control Center for Mobile Developers</strong></p>

[![SwiftUI](https://img.shields.io/badge/SwiftUI-Blue?logo=swift&logoColor=white&style=for-the-badge)](https://developer.apple.com/xcode/swiftui/)
[![macOS](https://img.shields.io/badge/macOS-14.0+-black?logo=apple&logoColor=white&style=for-the-badge)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-brightgreen?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)]()

</div>

<br/>

V-Dock is a lightning-fast, native macOS Menu Bar utility designed to streamline the workflow of iOS and Android developers. Manage, boot, and terminate your iOS Simulators and Android Emulators instantly without ever opening Xcode or Android Studio.

<div align="center">
  <!-- TODO: Drop your beautiful app screenshots here! -->
  <!-- <img src="screenshots/dashboard.png" width="45%" alt="V-Dock Dashboard"> -->
  <!-- <img src="screenshots/menubar.png" width="45%" alt="V-Dock Menu Bar"> -->
</div>

---

## ✨ Features

- 🚀 **One-Click Boot & Shutdown:** Start or stop any iOS Simulator or Android Emulator instantly from your Menu Bar.
- 📌 **Pin Favorite Devices:** Pin your most frequently used devices directly to the top of the Menu Bar for zero-friction access.
- 🧹 **Factory Reset & Cold Boot:** Wipe simulator data or perform a cold boot on Android emulators instantly without opening your IDE.
- 📸 **Quick Media Capture:** Take screenshots or screen recordings of the active device and save them straight to your Desktop with one click.
- 🌙 **Appearance Toggles:** Instantly switch your running devices between Dark Mode and Light Mode directly from the context menu.
- 🛠 **Mini Logcat Viewer:** A dedicated, native macOS window that streams logs in real-time (`adb logcat` / `simctl log`), featuring syntax highlighting, auto-scroll, and live filtering.
- 🥷 **Stealth Hybrid Mode:** V-Dock runs completely hidden in the background as a Menu Bar accessory. However, when you open the full Dashboard, it dynamically promotes itself to a regular macOS app complete with a Dock icon and global keyboard shortcuts.
- 🎨 **Glassmorphism UI:** Built entirely in modern SwiftUI featuring a stunning, responsive, and translucent macOS HIG-compliant design.
- 💎 **Cohesive Identity:** Custom AppKit iconography resizing ensures your branding stays pixel-perfect across the Menu Bar, Dock, and Settings pages.
- ⌨️ **Native Shortcuts:** Deep macOS integration with raw `NSEvent` interceptors guarantees that shortcuts like `Cmd + Q`, `Cmd + W`, and `Cmd + ,` work flawlessly exactly when you expect them to.
- ⚡ **Background Execution:** Utilizes Swift Concurrency (`Task.detached`) for non-blocking shell executions (e.g., `simctl` commands), keeping the UI buttery smooth.

---

## 🏗 Architecture

V-Dock is built using **Clean Architecture** principles to separate concerns, making the codebase highly testable and maintainable:

### 1. Presentation Layer

Contains all SwiftUI Views. We heavily utilize custom `NSWindow` and `NSHostingView` instances instead of standard SwiftUI `WindowGroup` to completely bypass macOS state restoration bugs and maintain absolute control over the app's lifecycle.
_Key files: `MenuBarView.swift`, `DashboardView.swift`, `SettingsView.swift`_

### 2. Domain Layer

The core business logic and state management. The `AppState` class acts as the single source of truth (`@Observable`), managing device lists, statuses, and pinned configurations.
_Key files: `AppState.swift`, `Device.swift`_

### 3. Data Layer

Handles interactions with the outside world, specifically executing shell commands (`simctl`, `emulator`) to control the mobile environments asynchronously.
_Key files: `ShellExecutor.swift`_

---

## 🛠 Advanced Technical Implementation

- **Defeating Zombie Windows:** V-Dock implements the "Holy Trinity" of state restoration blocking (`ApplePersistenceIgnoreState`, `NSQuitAlwaysKeepsWindows`, and low-level AppDelegate overrides) to ensure windows never reopen unexpectedly on launch.
- **Dynamic Activation Policy:** V-Dock effortlessly switches between `NSApp.setActivationPolicy(.accessory)` and `.regular`. It hides from your Dock when you just want a menu bar widget, but acts like a full app when the Dashboard is open.
- **NSEvent Monitors:** Bypasses SwiftUI's fragile menu system by hooking directly into macOS's lowest-level keyboard event monitors to guarantee shortcut reliability.

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Android Studio / Android SDK (Optional, for Android Emulator support)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/V-Dock.git
   ```
2. Open `V-Dock.xcodeproj` in Xcode.
3. Build and Run (`Cmd + R`).

### Configuration

If you use Android Emulators, open V-Dock Settings (`Cmd + ,`) and specify your Android SDK path (typically `/Users/YOUR_USERNAME/Library/Android/sdk`).

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check [issues page](https://github.com/yourusername/V-Dock/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

<div align="center">
  <p>Built with ❤️ for Community</p>
</div>
