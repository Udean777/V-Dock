# Contributing to V-Dock

First off, thank you for considering contributing to V-Dock! It's people like you that make V-Dock such a great tool for the mobile developer community.

## 🧠 Core Philosophy & Architecture

V-Dock is built with **Clean Architecture** and strict **SOLID Principles**. Before submitting code, please ensure your changes adhere to these architectural boundaries:

1.  **Presentation Layer (`/Presentation`)**: SwiftUI Views and ViewModels (`AppState.swift`). Must not contain direct shell commands or business logic parsing.
2.  **Domain Layer (`/Domain`)**: Use Cases (`*UseCase.swift`) and Repository Protocols (`*Protocol.swift`). This is the pure business logic layer.
3.  **Data Layer (`/Data`)**: Concrete Repositories (`SimulatorRepository.swift`, etc.) and Data Sources (`ShellExecutor.swift`). This layer handles direct OS and shell interactions.

_Always inject dependencies via `DependencyContainer.swift`!_

## 🛠 Local Development Setup

1.  **Fork** the repository on GitHub.
2.  **Clone** your fork locally:
    ```bash
    git clone https://github.com/YOUR_USERNAME/V-Dock.git
    ```
3.  Open `V-Dock.xcodeproj` in **Xcode 15.0** or newer.
4.  Ensure your macOS is running version 14.0 or newer.
5.  Select the `V-Dock` scheme and hit `Cmd + R` to build and run.

## 📝 Pull Request Process

1.  **Create a Feature Branch**: Always create a new branch for your feature or bug fix.
    ```bash
    git checkout -b feature/your-amazing-feature
    ```
2.  **Write Clean Code**: Ensure your Swift code is clean, readable, and properly indented. We prefer explicit types and avoiding force-unwraps (`!`) unless absolutely necessary.
3.  **Commit Messages**: We follow [Conventional Commits](https://www.conventionalcommits.org/):
    - `feat: add network throttling toggle`
    - `fix: resolve memory leak in LogcatView`
    - `docs: update README with new screenshots`
4.  **Push and Open a PR**: Push to your fork and open a Pull Request against the `main` branch of the original V-Dock repository. Include a clear description of the problem you are solving and how you solved it.

## 🐛 Reporting Bugs

If you find a bug, please create an issue on GitHub with:

- A clear, descriptive title.
- Your macOS version and Xcode version.
- Step-by-step instructions on how to reproduce the bug.
- (If applicable) The crash log or error output.

---

_By contributing to V-Dock, you agree that your contributions will be licensed under its MIT License._
