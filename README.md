# MacPulse — Native macOS Dynamic Island & System Pulse

[![Platform: macOS 14+](https://img.shields.io/badge/Platform-macOS%2014%2B%20(Sonoma%20%7C%20Sequoia)-000000?style=flat-square&logo=apple&logoColor=white)](https://apple.com/macos)
[![Swift: 6.0](https://img.shields.io/badge/Swift-6.0%20Ready-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Architecture: Universal](https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%26%20Intel)-6f42c1?style=flat-square)](#)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0%20(100%25%20Native%20Apple%20APIs)-2ea44f?style=flat-square)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](#)

> **MacPulse** is a lightweight, high-performance native macOS status and productivity utility built exclusively with SwiftUI, AppKit, Combine, and low-level Darwin Mach kernel APIs. Designed around the Apple MacBook notch geometry, MacPulse integrates an interactive **Dynamic Island**, real-time hardware telemetry, dedicated Spotify media controls, focus timers, clipboard history, quick scratchpad notes, and instant camera mirroring into an ultra-fluid glassmorphic experience.

---

## 📸 Highlights & Showcase

- **Docked Apple Notch Architecture**: Perfectly docked to the top edge of your display with authentic concave curved notch ears (`NotchShape`), specular hairline illumination, and macOS popover blur materials.
- **Dedicated Spotify Media Player**: Clean, elegant playback card featuring high-resolution album artwork, live dancing equalizer waveform visualizers, track/artist/album typography, smooth playback controls, and an instant Spotify launch fallback.
- **Interactive Fluid Physics**: Authentic iOS Dynamic Island motion design with jelly stretch/squash spring physics, interactive vertical swipe-to-dismiss upward, pull-to-expand downward, and horizontal trackpad swipe tab navigation.
- **Precision Focus & Repeating Reminders**: Dedicated 5-minute continuous repeating reminder with system chime alert, duration-preset countdown timer, and millisecond-accurate stopwatch with lap splits.
- **Quick System & Productivity Hub**: Live Mach kernel CPU core loads, wired/compressed/active RAM metrics, battery health/thermals, local clipboard history, quick scratchpad notes, volume & brightness HUD overlays, and instant AVFoundation camera mirror.
- **Launch at Login**: Robust dual-engine startup via macOS `SMAppService.mainApp` with seamless `NSAppleScript` System Events fallback for development environments.

---

## 🎯 Core Features

### 1. 🏝️ Top-Docked Dynamic Island
- **Flushed Top-Edge Anchoring**: Securely pinned directly to the screen's top bezel (`midX`, `screen.frame.maxY - targetSize.height`). No floating capsules or detached bars.
- **Curved Ear Notch Chassis**: Smooth concave Bézier curves that seamlessly extend the physical MacBook display notch or menu bar into an elegant interactive surface.
- **Compact Pill (236 × 26 pt)**:
  - Daily cumulative network transfer (e.g. `12.4 GB`).
  - Real-time CPU and RAM percentage metrics.
  - Thermal indicator (°C) or active timer countdown badge.
  - One-click instant expansion powered by `FirstMouseHostingView`.
- **Expanded Dynamic Shelf (520 × 148 pt)**:
  - 5 segmented tabs: **Home**, **Stats**, **Timer**, **Clipboard**, and **Notes**.
  - Specular rim light gradient (0.6 pt hairline).
  - Top action controls for display brightness, system volume HUD, clock stamp, and shelf collapse.

### 2. 🎵 Spotify Media Deck
- **Automatic Playback Detection**: Connects to the local Spotify macOS application via AppleScript and Distributed Notifications.
- **Live Dancing Audio Visualizer**: 4-bar dynamic audio equalizer with randomized rhythmic wave physics active during playback.
- **Album Artwork Glow**: Displays current track artwork with rounded corners and an official Spotify brand badge overlay.
- **One-Touch Controls**: Smooth Previous, Play/Pause, and Next buttons with tactile haptic feedback.
- **Quick Action Buttons**: Fast-access buttons for "Quit All Apps" and "GPT", plus a one-click **Camera Mirror** trigger.

### 3. ⏱️ Focus Timers & 5-Minute Repeating Reminders
- **5-Minute Continuous Reminder**: Designed for habit tracking and regular breaks. Continuously chimes the macOS system alert sound until acknowledged with a single click.
- **Visual Countdown Timer**: Circular progress ring with customizable minutes slider and rapid presets (`1m`, `5m`, `10m`, `15m`, `25m`, `30m`, `45m`, `60m`).
- **Precision Stopwatch**: Millisecond resolution with lap tracking, delta splits, and visual highlight badges for fastest and slowest laps.

### 4. ⚡ Low-Level System Telemetry
- **Mach Kernel CPU**: Samples Darwin `host_statistics` with `HOST_CPU_LOAD_INFO` to measure accurate user, system, and idle usage across physical and efficiency cores.
- **64-bit Virtual Memory**: Reads `HOST_VM_INFO64` for exact breakdowns of wired, active, compressed, and free memory against total RAM capacity.
- **IOKit Power & Thermals**: Inspects `AppleSmartBattery` and `IOPowerSources` for cycle counts, battery health percentage, temperature, and power supply states.
- **Network Bandwidth & History**: Polls BSD `getifaddrs` for real-time upload/download speeds and records daily historical statistics stored in local JSON format.

### 5. 📋 Productivity Extensions
- **Clipboard History**: Monitors local pasteboard events and maintains an accessible list of recent clippings with one-tap copy-back.
- **Scratchpad Notes**: Quick-capture notepad stored automatically in application storage.
- **AVFoundation Camera Mirror**: Instant webcam feed preview positioned inside the Dynamic Island for quick hair/mic checks before video calls.
- **Hardware HUD Overlays**: Custom brightness and volume sliders integrated into the notch chassis.

---

## 🗂️ Project Architecture & Structure

MacPulse follows a modular custom architecture with strict separation of concerns, zero external framework dependencies, and Swift 6 concurrency safety:

```
MacPulse/
├── MacPulse.app/               # Compiled, code-signed macOS application bundle
├── Package.swift               # Swift Package Manager definition
├── Sources/
│   └── MacPulse/
│       ├── App/                # Application entry point, AppDelegate, MenuBarManager
│       ├── DesignSystem/       # MacPulseTheme, Typography, Colors, Dimensions, Animations
│       ├── Modules/
│       │   ├── Media/          # MediaManager (Spotify AppleScript integration & cover art)
│       │   ├── Network/        # NetworkMonitorService, BSD getifaddrs, Usage stores
│       │   ├── System/         # SystemMonitorService, Mach kernel CPU/RAM, IOKit battery
│       │   ├── Timer/          # TimerService (5m repeating reminder, countdown, stopwatch)
│       │   ├── Clipboard/      # ClipboardManager (Local pasteboard monitor)
│       │   ├── Notes/          # NotesManager (Atomic local scratchpad persistence)
│       │   ├── HardwareHUD/    # HardwareControlManager (Display brightness & audio volume)
│       │   ├── CameraMirror/   # CameraMirrorService (AVFoundation webcam capture)
│       │   └── Dashboard/      # Main desktop dashboard views & settings
│       ├── Widgets/
│       │   ├── NotchShape.swift                # Concave ear notch geometry shape
│       │   ├── DynamicIslandModels.swift       # Enums, tabs, transitions, and alert types
│       │   ├── DynamicIslandPanel.swift        # NSPanel floating window & FirstMouseHostingView
│       │   ├── DynamicIslandController.swift   # MainActor state engine, HUD, gestures & alerts
│       │   ├── DynamicIslandRootView.swift     # Root SwiftUI island layout & drag gestures
│       │   ├── DynamicIslandHomeView.swift     # Spotify player & quick launcher shelf
│       │   ├── DynamicIslandStatsView.swift    # Multi-metric hardware telemetry shelf
│       │   ├── DynamicIslandTimerView.swift    # 5m reminder, countdown & stopwatch shelf
│       │   ├── DynamicIslandClipboardView.swift# Clipboard history shelf
│       │   ├── DynamicIslandNotesView.swift    # Quick notes shelf
│       │   ├── DynamicIslandHUDControlView.swift# Hardware volume & brightness HUD
│       │   ├── DynamicIslandAlertView.swift    # Animated alert notification banner
│       │   ├── DynamicIslandMirrorView.swift   # AVFoundation camera mirror preview
│       │   ├── DesktopWidgetWindow.swift       # Movable desktop HUD widget window
│       │   ├── WiFiDesktopWidget.swift         # Standalone desktop Wi-Fi usage widget
│       │   └── MenuBarPopoverView.swift        # Menu bar drop-down popover
│       └── Services/
│           ├── LaunchAtLoginService.swift      # Dual-engine SMAppService / AppleScript
│           └── HapticFeedback.swift            # NSHapticFeedbackManager helper
├── Resources/
│   ├── Info.plist              # Bundle metadata, permissions, and LSUIElement config
│   └── AppIcon.icns            # Retina multi-resolution macOS application icon
└── scripts/
    ├── build_app.sh            # Automated release build, bundle packager & code signer
    ├── generate_icon.swift     # Standalone AppIcon CoreGraphics generator
    └── test_runner.swift       # Verification test suite runner
```

---

## 🛠️ Building & Packaging

### System Requirements
- **OS**: macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- **Compiler**: Swift 5.9+ or Swift 6.0 (Xcode 15+ or Swift Command Line Tools)
- **Architecture**: Universal (Apple Silicon M1/M2/M3/M4 & Intel x86_64)

### Build the `.app` Bundle
To build an optimized release binary, assemble the `.app` bundle, link assets, and apply ad-hoc code signing:

```bash
chmod +x ./scripts/build_app.sh
./scripts/build_app.sh release
```

The compiled application will be generated at:
```bash
./MacPulse.app
```

### Install & Run
```bash
# Copy to user Applications
cp -R MacPulse.app /Applications/

# Launch MacPulse
open /Applications/MacPulse.app
```

---

## ⌨️ Gestures & Keyboard Shortcuts

| Gesture / Input | Scope | Action |
| :--- | :--- | :--- |
| **Click Notch Pill** | Compact State | Expands Dynamic Island shelf |
| **Swipe Up** | Expanded Shelf | Interactive squash-and-stretch dismissal |
| **Swipe Down** | Compact State | Pull-down to restore/expand |
| **Scroll / Swipe Left** | Expanded Shelf | Transition to next tab (collapses on last) |
| **Scroll / Swipe Right** | Expanded Shelf | Transition to previous tab (collapses on first) |
| **Click Outside** | Expanded Shelf | Closes shelf smoothly |

---

## 🏷️ GitHub Topics & Keywords

To help developers and users discover MacPulse, this repository is tagged with:

`macos` · `swiftui` · `swift` · `dynamic-island` · `macbook-notch` · `system-monitor` · `spotify-widget` · `appkit` · `native-macos` · `network-monitor` · `macos-utility` · `glassmorphism` · `mach-kernel` · `hardware-monitor` · `focus-timer` · `clipboard-manager` · `avfoundation` · `camera-mirror`

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.
