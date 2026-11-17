# MacPulse — Premium Native macOS Dashboard

MacPulse is a native macOS application engineered in Swift and SwiftUI with AppKit integration. It provides a real-time command dashboard delivering network telemetry, hardware diagnostics, and focus timers within an Apple-inspired glassmorphic aesthetic.

![MacPulse Banner](https://img.shields.io/badge/Platform-macOS%2014%2B-blue?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206-orange?style=flat-square&logo=swift)
![Architecture](https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%26%20Intel)-purple?style=flat-square)
![License](https://img.shields.io/badge/Status-Production%20Ready-green?style=flat-square)

---

## 🌟 Modules & Features

### 1. 📶 Wi-Fi & Network Usage Monitor
- **Real-Time Bandwidth**: Live download and upload speed meters with dual high-frequency sparkline curves.
- **Daily Cumulative Statistics**: Tracks exact MB / GB received and sent today with automatic midnight rollover.
- **Persistent Historical Analytics**: 7-day and 14-day stacked bar charts comparing upload vs download consumption.
- **Dynamic Interface Detection**: Automatically resolves active default routes (`en0`, `en1`, etc.) or lets you lock onto Wi-Fi, Ethernet, or All interfaces.
- **Sleep & Wake Resilient**: Observes `NSWorkspace.didWakeNotification` to recalibrate delta baselines and eliminate artificial bandwidth spikes on wake.
- **Atomic Local Persistence**: Stores records in `~/Library/Application Support/MacPulse/network_history.json`.

### 2. ⚡ System Hardware Monitor
- **Mach Kernel CPU Telemetry**: Utilizes Mach `host_statistics` with `HOST_CPU_LOAD_INFO` to compute real-time user, system, and idle loads across all physical/efficiency/performance cores.
- **Virtual Memory (RAM)**: Samples `host_statistics64` with `HOST_VM_INFO64` to provide an exact breakdown of active, wired, compressed, and free memory against total physical RAM.
- **Disk Storage**: Real-time volume capacity analysis for macOS system and data APFS containers.
- **Power & Battery Health**: Direct `IOKit` `AppleSmartBattery` & `IOPowerSources` integration reading charge %, power source (AC/Battery), cycle count, health %, condition ("Normal" / "Service Recommended"), and temperature.
- **Uptime Telemetry**: Live boot-time tracker formatting uptime into Days, Hours, and Minutes.

### 3. ⏱ Productivity & Focus Timers
- **Stopwatch**: Millisecond-accurate stopwatch with interactive lap tracking, delta splits, and fastest/slowest lap highlighting.
- **Countdown Timer**: Duration picker with quick one-click presets (1m, 5m, 10m, 15m, 25m, 30m, 45m, 60m), animated progress ring, and system sound/notification on completion.
- **Pomodoro Timer**: Three structured phases (Focus 25m, Short Break 5m, Long Break 15m), completed session tallies, optional auto-advance, and audio chime alerts.

### 4. 🪟 Standalone Wi-Fi Widget, Apple Dynamic Island & Menu Bar Extra
- **Standalone Wi-Fi Data Widget**: Pixel-perfect native replica of the dark macOS desktop widget:
  - Circular bright blue Wi-Fi badge + `WI-FI DATA USAGE`.
  - Vibrant green square badge with downward arrow `↓` + big bold downloaded GB (e.g. `340.73 GB`).
  - Subtle divider line.
  - Purple square badge with upward arrow `↑` + big bold uploaded GB (e.g. `163.83 GB`).
  - Bottom row with refresh icon `⟳` and live timestamp (`16/11/2026, 3:32 PM`).
  - Interactive: Click to toggle between **Today's Total GB** and **Live Speed (MB/s)**; right-click context menu to reset or manage.
- **Apple Dynamic Island (Timers & System Health)**:
  - Anchored at the top center of the screen (under notch/menu bar) on the `.statusBar` floating window level.
  - **Compact State (Pill)**: Sleek black capsule showing active timer countdown (flame/timer icon) on the left and live CPU/Battery on the right.
  - **Expanded State (Island Hub)**: Expands fluidly with Apple spring physics into an interactive dual-wing hub:
    - **Left Wing**: Full timer controls (circular progress meter, digital countdown, Start/Pause/Reset/Skip).
    - **Right Wing**: Hardware vitals (CPU load %, RAM usage %, Battery %, core count, uptime).
- **Floating HUD Desktop Widget**: Movable glass HUD window with Compact Pill and Expanded Card layouts.
- **Menu Bar Extra**: Status bar item (`waveform.path.ecg`) with a drop-down glass popover for quick glances without opening the main window.
- **Launch at Login**: Native macOS `SMAppService.mainApp` integration.

---

## 🎨 Design Philosophy
- **Glassmorphism**: Built using macOS native materials (`.ultraThinMaterial`, `NSVisualEffectView`) with dark obsidian depth gradients.
- **Vibrancy & Glow**: Apple-inspired accent palettes (Cyan `#00C7BE`, Electric Blue `#0A84FF`, Orange `#FF9F0A`, Mint `#30D158`, Purple `#AF52DE`).
- **Smooth Animations**: Spring transitions (`.spring(response: 0.3, dampingFraction: 0.8)`), interactive card hover states, and smooth Bézier curve sparklines.

---

## 🚀 Building & Installing

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Apple Swift Command Line Tools or Xcode

### Build the Installable `.app` Bundle
Run the packaging script from the repository root:
```bash
./scripts/build_app.sh
```
This will compile the release binary, assemble the `.app` bundle structure, embed the Retina `AppIcon.icns`, and apply ad-hoc code signing.

The resulting bundle will be located at:
```bash
./MacPulse.app
```

To install it into your Applications directory:
```bash
cp -R MacPulse.app /Applications/
```

To launch MacPulse immediately:
```bash
open ./MacPulse.app
```

---

## 🧪 Verification & Testing
Run the verification test suite:
```bash
swift scripts/test_runner.swift
```

---

## 📂 Project Architecture

```
MacPulse/
├── MacPulse.app/               # Compiled, signed, installable macOS application
├── Package.swift               # Swift Package Manager manifest
├── Sources/
│   └── MacPulse/
│       ├── App/                # App entry point, AppDelegate, Menu Bar status item
│       ├── DesignSystem/       # Theme, GlassCard, CircularProgress, SparklineChart
│       ├── Modules/
│       │   ├── Network/        # BSD getifaddrs, NWPathMonitor, usage history
│       │   ├── System/         # Mach kernel CPU, RAM, Disk, IOPowerSources
│       │   ├── Timer/          # Stopwatch, Countdown, Pomodoro state machine
│       │   └── Dashboard/      # Unified dashboard, header, sidebar, settings
│       ├── Widgets/            # Floating HUD widget & Menu Bar popover
│       └── Services/           # StorageManager, NotificationManager, LaunchAtLogin
├── Resources/
│   ├── Info.plist              # Bundle metadata
│   └── AppIcon.icns            # Multi-resolution Retina macOS application icon
└── scripts/
    ├── build_app.sh            # Automated release build & packaging script
    ├── generate_icon.swift     # CoreGraphics icon generator
    └── test_runner.swift       # Real-world verification test harness
```
