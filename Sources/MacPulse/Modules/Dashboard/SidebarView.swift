import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case all = "Dashboard"
    case network = "Wi-Fi & Network"
    case system = "System Monitor"
    case timer = "Timers & Focus"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .network: return "wifi"
        case .system: return "cpu"
        case .timer: return "timer"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .all: return MacPulseTheme.accentCyan
        case .network: return MacPulseTheme.accentCyan
        case .system: return MacPulseTheme.accentOrange
        case .timer: return MacPulseTheme.accentPurple
        }
    }
}

public struct SidebarView: View {
    @Binding public var selectedTab: NavigationTab
    
    public init(selectedTab: Binding<NavigationTab>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MODULES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(MacPulseTheme.textTertiary)
                .padding(.horizontal, 14)
                .padding(.top, 16)
                .padding(.bottom, 4)
            
            ForEach(NavigationTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? tab.accentColor : MacPulseTheme.textSecondary)
                            .frame(width: 20)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : MacPulseTheme.textSecondary)
                        
                        Spacer()
                        
                        if isSelected {
                            Circle()
                                .fill(tab.accentColor)
                                .frame(width: 5, height: 5)
                                .shadow(color: tab.accentColor, radius: 3)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Footer status info
            VStack(alignment: .leading, spacing: 6) {
                Divider().background(MacPulseTheme.borderSubtle)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MacPulse v1.0")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                        Text("Apple Silicon & Intel Native")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseTheme.textTertiary)
                    }
                    Spacer()
                    Circle()
                        .fill(MacPulseTheme.accentGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: MacPulseTheme.accentGreen.opacity(0.8), radius: 3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 210)
        .background(
            Color.black.opacity(0.3)
                .overlay(
                    Rectangle()
                        .fill(MacPulseTheme.borderSubtle)
                        .frame(width: 1),
                    alignment: .trailing
                )
        )
    }
}
