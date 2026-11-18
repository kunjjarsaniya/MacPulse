import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Hallmark Dynamic Island Root View (Apple-Engineered Architecture)

public struct HallmarkDynamicIslandRootView: View {
    @ObservedObject private var controller = DynamicIslandController.shared
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var history = NetworkHistoryStore.shared
    @ObservedObject private var timer = TimerService.shared
    
    @State private var isHovering: Bool = false
    @State private var currentTimeString: String = ""
    @State private var dragOffsetY: CGFloat = 0
    @State private var dragOffsetX: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var jellyScale: CGSize = CGSize(width: 1.0, height: 1.0)
    @Namespace private var tabAnimationNamespace
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        return df
    }()
    
    private let clockTimer = Foundation.Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private var isExpanded: Bool {
        controller.isExpanded
    }
    
    private var isAnyTimerRunning: Bool {
        timer.reminderState == .running || timer.countdownState == .running || timer.stopwatchState == .running
    }
    
    private var currentNotchShape: NotchShape {
        let topEar: CGFloat
        let bottomRadius: CGFloat
        if controller.activeAlert != nil {
            topEar = MacPulseRadius.topEarHUD
            bottomRadius = MacPulseRadius.bottomCornerHUD
        } else if controller.activeHUD != nil {
            topEar = MacPulseRadius.topEarHUD
            bottomRadius = MacPulseRadius.bottomCornerHUD
        } else if isExpanded {
            // Adaptive corner radii during vertical swipe-to-dismiss gesture
            if dragOffsetY < 0 {
                let factor = min(1.0, max(0.0, -dragOffsetY / 60.0))
                topEar = MacPulseRadius.topEarExpanded - (factor * (MacPulseRadius.topEarExpanded - MacPulseRadius.topEarCompact))
                bottomRadius = MacPulseRadius.bottomCornerExpanded - (factor * (MacPulseRadius.bottomCornerExpanded - MacPulseRadius.bottomCornerCompact))
            } else {
                topEar = MacPulseRadius.topEarExpanded
                bottomRadius = MacPulseRadius.bottomCornerExpanded
            }
        } else {
            topEar = MacPulseRadius.topEarCompact
            bottomRadius = MacPulseRadius.bottomCornerCompact
        }
        return NotchShape(topCornerRadius: topEar, bottomCornerRadius: bottomRadius)
    }
    
    // Swipe-aware dynamic blur & dimming feedback during gesture
    private var swipeAwareBackgroundOpacity: Double {
        if isExpanded && dragOffsetY < 0 {
            let progress = min(1.0, max(0.0, -dragOffsetY / 100.0))
            return 0.96 - (progress * 0.20)
        }
        return 0.96
    }
    
    private var swipeAwareBlurOpacity: Double {
        if isExpanded && dragOffsetY < 0 {
            let progress = min(1.0, max(0.0, -dragOffsetY / 100.0))
            return 1.0 - (progress * 0.30)
        }
        return 1.0
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Unified Apple Curved Notch Chassis (Zero Drop Shadow, Curved Ears)
            currentNotchShape
                .fill(MacPulseColors.islandBackground.opacity(swipeAwareBackgroundOpacity))
                .background(
                    VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                        .clipShape(currentNotchShape)
                        .opacity(swipeAwareBlurOpacity)
                )
                .overlay(
                    // Subtle Specular Hairline Rim Light (0.6pt)
                    currentNotchShape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovering || isExpanded || controller.activeHUD != nil || controller.activeAlert != nil ? 0.22 : 0.12),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.6
                        )
                )
            
            // Content Switcher with Synchronized Content Interpolation
            if let alert = controller.activeAlert {
                DynamicIslandAlertView(alert: alert)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.90, anchor: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.85, anchor: .top).combined(with: .opacity)
                        )
                    )
            } else if let hud = controller.activeHUD {
                DynamicIslandHUDControlView(hudType: hud)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.85, anchor: .top).combined(with: .opacity)
                        )
                    )
            } else if isExpanded {
                expandedShelfContent
                    .offset(y: dragOffsetY < 0 ? dragOffsetY * 0.25 : 0)
                    .opacity(dragOffsetY < 0 ? max(0.15, 1.0 + (dragOffsetY / 90.0)) : 1.0)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.82, anchor: .top)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: -10)),
                            removal: .scale(scale: 0.80, anchor: .top)
                                .combined(with: .opacity)
                                .combined(with: .offset(y: -12))
                        )
                    )
            } else {
                compactPillBar
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.88, anchor: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.75, anchor: .top).combined(with: .opacity)
                        )
                    )
            }
            
            // Floating Toast Notification Pill
            if controller.showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: controller.toastIcon.isEmpty ? "checkmark.circle.fill" : controller.toastIcon)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                        Text(controller.toastMessage)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        if !controller.toastSubtitle.isEmpty {
                            Text("• \(controller.toastSubtitle)")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.65))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.96))
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.22), lineWidth: 0.7)
                            )
                            .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)
                    )
                    .padding(.bottom, 6)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(
            width: controller.activeAlert != nil
                ? MacPulseDimensions.alertIslandSize.width
                : (controller.activeHUD != nil
                    ? MacPulseDimensions.hudIslandSize.width
                    : (isExpanded
                        ? MacPulseDimensions.expandedIslandSize.width
                        : (controller.activeLiveActivityText != nil ? MacPulseDimensions.compactLiveActivitySize.width : MacPulseDimensions.compactIslandSize.width))),
            height: controller.activeAlert != nil
                ? MacPulseDimensions.alertIslandSize.height
                : (controller.activeHUD != nil
                    ? MacPulseDimensions.hudIslandSize.height
                    : (isExpanded ? MacPulseDimensions.expandedIslandSize.height : MacPulseDimensions.compactIslandSize.height))
        )
        .clipShape(currentNotchShape)
        .offset(y: dragOffsetY)
        .scaleEffect(jellyScale, anchor: .top)
        .opacity(isExpanded && dragOffsetY < 0 ? max(0.70, 1.0 + (dragOffsetY / 120.0)) : 1.0)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .animation(MacPulseAnimations.islandSpring, value: controller.showToast)
        .animation(MacPulseAnimations.islandSpring, value: controller.activeAlert)
        .animation(MacPulseAnimations.islandSpring, value: controller.activeHUD)
        .animation(isExpanded ? MacPulseAnimations.dynamicIslandExpand : MacPulseAnimations.dynamicIslandCollapse, value: isExpanded)
        .animation(MacPulseAnimations.islandSpring, value: controller.activeLiveActivityText)
        .animation(MacPulseAnimations.snappySpring, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            updateClock()
        }
        .onReceive(clockTimer) { _ in
            updateClock()
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let transY = value.translation.height
        let transX = value.translation.width
        
        if isExpanded {
            if transY < 0 {
                // Interactive vertical swipe-to-dismiss upward
                isDragging = true
                let dragProgress = min(1.0, max(0.0, -transY / 140.0))
                dragOffsetY = transY * 0.45
                // Squash vertically, stretch horizontally (True iOS Jelly Physics)
                let squashY = max(0.82, 1.0 - (dragProgress * 0.18))
                let stretchX = min(1.08, 1.0 + (dragProgress * 0.08))
                jellyScale = CGSize(width: stretchX, height: squashY)
            } else if transY > 0 {
                // Pull-down over-drag rubber-band
                isDragging = true
                dragOffsetY = transY * 0.25
                let stretchY = min(1.10, 1.0 + (transY / 280.0))
                let squashX = max(0.96, 1.0 - (transY / 500.0))
                jellyScale = CGSize(width: squashX, height: stretchY)
            } else if abs(transX) > abs(transY) {
                // Horizontal drag feedback
                isDragging = true
                dragOffsetX = transX * 0.25
            }
        } else {
            // Collapsed: interactive pull-down-to-restore/expand
            if transY > 0 {
                isDragging = true
                dragOffsetY = transY * 0.45
                let stretchY = min(1.24, 1.0 + (transY / 150.0))
                let squashX = max(0.94, 1.0 - (transY / 450.0))
                jellyScale = CGSize(width: squashX, height: stretchY)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let transX = value.translation.width
        let transY = value.translation.height
        let velocityY = value.predictedEndTranslation.height - transY
        let velocityX = value.predictedEndTranslation.width - transX
        
        if isExpanded {
            if abs(transY) > abs(transX) {
                // Vertical Swipe Up to Dismiss
                if transY < -24 || velocityY < -80 {
                    HapticFeedback.playSoft()
                    collapse()
                }
            } else {
                // Horizontal Drag: Tab Navigation & Scroll-to-Dismiss at Edges
                if abs(transX) > 24 || abs(velocityX) > 75 {
                    let all = MacPulseShelfTab.allCases
                    if transX < 0 {
                        // Dragged Left -> Next tab, or dismiss if on last tab
                        if controller.activeTab == all.last {
                            HapticFeedback.playSoft()
                            collapse()
                        } else {
                            controller.selectNextTab()
                        }
                    } else {
                        // Dragged Right -> Previous tab, or dismiss if on first tab
                        if controller.activeTab == all.first {
                            HapticFeedback.playSoft()
                            collapse()
                        } else {
                            controller.selectPreviousTab()
                        }
                    }
                }
            }
        } else {
            // Collapsed: Pull Down to Restore
            if transY > 16 || velocityY > 75 {
                expand()
            }
        }
        
        // Elastic rebound to rest with authentic iOS jelly physics
        withAnimation(MacPulseAnimations.jellySpring) {
            dragOffsetY = 0
            dragOffsetX = 0
            isDragging = false
            jellyScale = CGSize(width: 1.0, height: 1.0)
        }
    }
    
    private func updateClock() {
        currentTimeString = Self.timeFormatter.string(from: Date())
    }
    
    private func expand() {
        HapticFeedback.playSoft()
        controller.expand()
    }
    
    private func collapse() {
        HapticFeedback.playSoft()
        controller.collapse()
    }
    
    // MARK: - 1. Compact Dynamic Island Pill (236 x 26 — Flush Screen-Top Anchor)
    private var compactPillBar: some View {
        Group {
            if let liveText = controller.activeLiveActivityText {
                HStack(spacing: MacPulseSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.90))
                    Text(liveText)
                        .font(MacPulseTypography.footnoteRounded)
                        .foregroundColor(MacPulseColors.textPrimary)
                }
                .frame(height: MacPulseDimensions.compactIslandSize.height)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                HStack(spacing: 0) {
                    Spacer(minLength: 2)
                    
                    // 1. Wi-Fi Usage
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                        
                        let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                        Text(NetworkUnitFormatter.formatBytes(todayTotal))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(MacPulseColors.textPrimary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Translucent Separator Dot
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 2.5, height: 2.5)
                    
                    Spacer(minLength: 4)
                    
                    // 2. Hardware Vitals (CPU & RAM)
                    HStack(spacing: 7) {
                        HStack(spacing: 2.5) {
                            Image(systemName: "cpu")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(MacPulseColors.textTertiary)
                            Text("\(Int(sys.cpu.usagePercentage))%")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textPrimary)
                        }
                        
                        HStack(spacing: 2.5) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(MacPulseColors.textTertiary)
                            Text("\(Int(sys.ram.usagePercentage))%")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Translucent Separator Dot
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 2.5, height: 2.5)
                    
                    Spacer(minLength: 4)
                    
                    // 3. Status Metric: Active Timer OR Thermals
                    Group {
                        if isAnyTimerRunning {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.90))
                                Text(activeTimerFormattedString)
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.white.opacity(0.16)))
                        } else {
                            let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                            Text("\(Int(temp))°C")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 2)
                }
                .frame(height: MacPulseDimensions.compactIslandSize.height)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - 2. Expanded Shelf Content
    private var expandedShelfContent: some View {
        VStack(spacing: MacPulseSpacing.md) {
            // Top Navigation & Utility Bar
            HStack(spacing: MacPulseSpacing.sm) {
                // Segmented Capsule Tab Switcher
                HStack(spacing: MacPulseSpacing.xxs) {
                    ForEach(MacPulseShelfTab.allCases) { tab in
                        Button {
                            controller.selectTab(tab)
                        } label: {
                            HStack(spacing: MacPulseSpacing.xs) {
                                Image(systemName: tab.icon)
                                    .font(MacPulseTypography.caption2)
                                Text(tab.rawValue)
                                    .font(controller.activeTab == tab ? MacPulseTypography.captionSemibold : MacPulseTypography.caption)
                            }
                            .foregroundColor(controller.activeTab == tab ? .white : MacPulseColors.textSecondary)
                            .padding(.horizontal, 7.5)
                            .padding(.vertical, 3.5)
                            .background {
                                if controller.activeTab == tab {
                                    Capsule()
                                        .fill(MacPulseColors.activeTabPill)
                                        .matchedGeometryEffect(id: "activeTabCapsule", in: tabAnimationNamespace)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2.5)
                .background(Capsule().fill(MacPulseColors.pillBackground))
                
                Spacer()
                
                // Clock Stamp
                Text(currentTimeString)
                    .font(MacPulseTypography.footnoteMedium)
                    .foregroundColor(MacPulseColors.textTertiary)
                    .padding(.trailing, 2)
                
                // Brightness Control Action
                IslandIconButton(
                    icon: "sun.max.fill",
                    iconSize: 10,
                    iconWeight: .medium,
                    foregroundColor: controller.activeHUD == .brightness ? .white : MacPulseColors.textSecondary,
                    backgroundColor: controller.activeHUD == .brightness ? Color.white.opacity(0.20) : Color.white.opacity(0.08),
                    tooltip: "Display Brightness"
                ) {
                    withAnimation(MacPulseAnimations.islandSpring) {
                        controller.toggleHUD(.brightness)
                    }
                }
                
                // Sound / Volume Control Action
                IslandIconButton(
                    icon: "speaker.wave.2.fill",
                    iconSize: 10,
                    iconWeight: .medium,
                    foregroundColor: controller.activeHUD == .volume ? .white : MacPulseColors.textSecondary,
                    backgroundColor: controller.activeHUD == .volume ? Color.white.opacity(0.20) : Color.white.opacity(0.08),
                    tooltip: "Sound Volume"
                ) {
                    withAnimation(MacPulseAnimations.islandSpring) {
                        controller.toggleHUD(.volume)
                    }
                }
                
                // Collapse Action
                IslandIconButton(
                    icon: "chevron.up",
                    iconSize: 9,
                    iconWeight: .bold,
                    foregroundColor: MacPulseColors.textPrimary,
                    backgroundColor: Color.white.opacity(0.10),
                    tooltip: "Collapse Shelf"
                ) {
                    collapse()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 9)
            
            // Dynamic Body Section (Content Canvas)
            ZStack {
                if controller.showCameraMirror {
                    DynamicIslandMirrorView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    currentTabView
                        .id(controller.activeTab)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: controller.navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
                                removal: .move(edge: controller.navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
                            )
                        )
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { gesture in
                        guard controller.isExpanded, controller.activeHUD == nil, !controller.showCameraMirror else { return }
                        let transX = gesture.translation.width
                        let transY = gesture.translation.height
                        guard abs(transX) > abs(transY) * 1.35 else { return }
                        let all = MacPulseShelfTab.allCases
                        if transX < -30 {
                            if controller.activeTab == all.last {
                                HapticFeedback.playSoft()
                                controller.collapse()
                            } else {
                                controller.selectNextTab()
                            }
                        } else if transX > 30 {
                            if controller.activeTab == all.first {
                                HapticFeedback.playSoft()
                                controller.collapse()
                            } else {
                                controller.selectPreviousTab()
                            }
                        }
                    }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var currentTabView: some View {
        switch controller.activeTab {
        case .stats:
            DynamicIslandStatsView()
        case .home:
            DynamicIslandHomeView()
        case .timer:
            DynamicIslandTimerView()
        case .clipboard:
            DynamicIslandClipboardView()
        case .notes:
            DynamicIslandNotesView()
        }
    }
    
    private var activeTimerFormattedString: String {
        if timer.reminderState == .running {
            let mins = Int(timer.reminderRemaining) / 60
            let secs = Int(timer.reminderRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
        } else if timer.countdownState == .running {
            let mins = Int(timer.countdownRemaining) / 60
            let secs = Int(timer.countdownRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
        } else if timer.stopwatchState == .running {
            let totalSeconds = Int(timer.stopwatchElapsed)
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            return String(format: "%02d:%02d", mins, secs)
        }
        return "00:00"
    }
}
