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

## ✨ Highlight Features & How to Use

### 🚀 Menu Bar Mastery

V-Dock lives quietly in your macOS Menu Bar. Click the V-Dock icon to reveal all your iOS Simulators and Android Emulators.

- **One-Click Boot & Shutdown:** Click the power icon next to any device to boot or terminate it instantly.
- **Pin Favorite Devices:** Right-click a device and select "Pin" so your daily drivers always stay at the very top.

<img src="assets/menubar.png" width="600" alt="Menu Bar Mastery">

---

### 🛠 Context Actions (Right-Click Menu)

Right-click any **active** device to unlock a suite of powerful developer tools right from the Menu Bar:

#### 1. 🛠 Mini Logcat / Console Viewer

Stream device logs directly into a beautiful, native macOS window without opening Android Studio or Xcode.

- **How to use:** Right-click an active device ➔ **Show Logcat**.
- **Features:** Real-time streaming, syntax highlighting (Errors/Warnings), auto-scrolling, and live search filtering.

<img src="assets/logcat.png" width="600" alt="Mini Logcat Viewer">

#### 2. 📸 Quick Media Capture

Need to share a bug or UI preview with your team? Capture it instantly.

- **How to use:** Right-click an active device ➔ **Take Screenshot** or **Record Screen**.
- **Result:** The media file is automatically captured and saved directly to your Mac's Desktop.

<img src="assets/screenshot.png" width="600" alt="Media Capture">

#### 3. 🌙 Appearance Toggles

Test your app's UI in both dark and light themes effortlessly.

- **How to use:** Right-click an active device ➔ **Appearance** ➔ **Dark Mode** or **Light Mode**.
- **Result:** The emulator/simulator instantly forces the OS-level theme change.

<img src="assets/mode%20toggles.png" width="600" alt="Appearance Toggle">

#### 4. 🧹 Factory Reset & Cold Boot

Start fresh without digging through deeply nested simulator settings or Xcode's device manager.

- **How to use:** Right-click an _inactive_ device ➔ **Erase Data** (iOS) or **Cold Boot** (Android).

<img src="assets/contextmenu-cold-boot.png" width="600" alt="Factory Reset">

---

### 🥷 Under The Hood

- **Stealth Hybrid Mode:** V-Dock runs completely hidden in the background as a Menu Bar accessory (`.accessory`). However, when you open the full Dashboard, it dynamically promotes itself to a regular macOS app (`.regular`) complete with a Dock icon and global keyboard shortcuts.
- **Native Shortcuts:** Deep macOS integration with raw `NSEvent` interceptors guarantees that shortcuts like `Cmd + Q`, `Cmd + W`, and `Cmd + ,` work flawlessly.
- **Background Execution:** Utilizes Swift Concurrency (`Task.detached`) for non-blocking shell executions (e.g., `simctl` commands), keeping the UI buttery smooth.

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
