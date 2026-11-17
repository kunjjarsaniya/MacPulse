import SwiftUI

public struct DashboardView: View {
    @State private var selectedTab: NavigationTab = .all
    @State private var showSettings: Bool = false
    public let onToggleWidget: () -> Void
    
    public init(onToggleWidget: @escaping () -> Void) {
        self.onToggleWidget = onToggleWidget
    }
    
    public var body: some View {
        ZStack {
            // Background dark ambient gradient
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.08, blue: 0.11),
                    Color(red: 0.04, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header
                HeaderView(showSettings: $showSettings, onToggleWidget: onToggleWidget)
                
                // Main Content Area with Sidebar
                HStack(spacing: 0) {
                    SidebarView(selectedTab: $selectedTab)
                    
                    // Main Scrollable Area
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .all:
                                NetworkMonitorCard()
                                SystemMonitorCard()
                                TimerCard()
                            case .network:
                                NetworkMonitorCard()
                            case .system:
                                SystemMonitorCard()
                            case .timer:
                                TimerCard()
                            }
                        }
                        .padding(24)
                    }
                }
            }
            
            // Settings Modal Sheet
            if showSettings {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showSettings = false
                    }
                
                SettingsView(isPresented: $showSettings)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showSettings)
    }
}
