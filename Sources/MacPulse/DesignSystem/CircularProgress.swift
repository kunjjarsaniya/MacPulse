import SwiftUI

// MARK: - Circular Progress Meter

public struct CircularProgressView: View {
    public let progress: Double // 0.0 to 1.0
    public let lineWidth: CGFloat
    public let gradient: LinearGradient
    public let trackColor: Color
    public let size: CGFloat
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 10,
        gradient: LinearGradient = MacPulseTheme.downloadGradient,
        trackColor: Color = Color.white.opacity(0.08),
        size: CGFloat = 90
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.trackColor = trackColor
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(trackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: progress)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
}

public struct MultiSegmentProgressView: View {
    public struct Segment: Identifiable {
        public let id = UUID()
        public let value: Double // relative or normalized
        public let color: Color
        public let title: String
        
        public init(value: Double, color: Color, title: String) {
            self.value = value
            self.color = color
            self.title = title
        }
    }
    
    public let segments: [Segment]
    public let lineWidth: CGFloat
    public let size: CGFloat
    
    public init(segments: [Segment], lineWidth: CGFloat = 12, size: CGFloat = 100) {
        self.segments = segments
        self.lineWidth = lineWidth
        self.size = size
    }
    
    private var total: Double {
        let sum = segments.reduce(0.0) { $0 + $1.value }
        return sum > 0 ? sum : 1.0
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)
            
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                let start = startAngle(for: index)
                let length = (segment.value / total)
                
                Circle()
                    .trim(from: CGFloat(start), to: CGFloat(start + length))
                    .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: segment.value)
            }
        }
        .frame(width: size, height: size)
    }
    
    private func startAngle(for index: Int) -> Double {
        var current: Double = 0
        for i in 0..<index {
            current += segments[i].value / total
        }
        return current
    }
}
