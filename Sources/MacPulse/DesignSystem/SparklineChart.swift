import SwiftUI

// MARK: - Live Sparkline Chart

public struct SparklineChart: View {
    public let data: [Double]
    public let gradient: LinearGradient
    public let lineColor: Color
    public let showFill: Bool
    public let strokeWidth: CGFloat
    
    public init(
        data: [Double],
        gradient: LinearGradient = MacPulseTheme.downloadGradient,
        lineColor: Color = MacPulseTheme.accentCyan,
        showFill: Bool = true,
        strokeWidth: CGFloat = 2.0
    ) {
        self.data = data
        self.gradient = gradient
        self.lineColor = lineColor
        self.showFill = showFill
        self.strokeWidth = strokeWidth
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let points = normalizedPoints(size: geometry.size)
            
            ZStack {
                if showFill && points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        path.addLine(to: points[0])
                        
                        for i in 1..<points.count {
                            let p0 = points[i - 1]
                            let p1 = points[i]
                            let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                            let control1 = CGPoint(x: (p0.x + midPoint.x) / 2, y: p0.y)
                            let control2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
                            
                            path.addCurve(to: p1, control1: control1, control2: control2)
                        }
                        
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.35), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                if points.count > 1 {
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let p0 = points[i - 1]
                            let p1 = points[i]
                            let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                            let control1 = CGPoint(x: (p0.x + midPoint.x) / 2, y: p0.y)
                            let control2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
                            
                            path.addCurve(to: p1, control1: control1, control2: control2)
                        }
                    }
                    .stroke(gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    
                    // Current latest point dot
                    if let last = points.last {
                        Circle()
                            .fill(lineColor)
                            .frame(width: 6, height: 6)
                            .position(last)
                            .shadow(color: lineColor.opacity(0.8), radius: 4)
                    }
                }
            }
        }
    }
    
    private func normalizedPoints(size: CGSize) -> [CGPoint] {
        guard data.count > 1 else { return [] }
        let maxVal = max(data.max() ?? 1.0, 1.0)
        let minVal = 0.0
        let range = maxVal - minVal
        
        let stepX = size.width / CGFloat(data.count - 1)
        
        return data.enumerated().map { index, val in
            let clampedVal = max(0.0, val)
            let ratio = range > 0 ? (clampedVal - minVal) / range : 0
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(ratio) * (size.height * 0.85) + (size.height * 0.08))
            return CGPoint(x: x, y: y)
        }
    }
}
