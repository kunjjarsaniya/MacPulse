import AppKit
import CoreGraphics

func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    
    // Background squircle rounded rect
    let cornerRadius = size * 0.2237 // Apple standard icon continuous corner radius
    let inset = size * 0.05
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    
    // Deep dark glass background gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
        NSColor(red: 0.03, green: 0.04, blue: 0.07, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    
    // Glowing ambient radial orb
    let orbColors = [
        NSColor(red: 0.0, green: 0.85, blue: 0.80, alpha: 0.35).cgColor,
        NSColor(red: 0.0, green: 0.50, blue: 1.0, alpha: 0.15).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ] as CFArray
    let orbGradient = CGGradient(colorsSpace: colorSpace, colors: orbColors, locations: [0.0, 0.5, 1.0])!
    ctx.drawRadialGradient(
        orbGradient,
        startCenter: CGPoint(x: size * 0.5, y: size * 0.5),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.5, y: size * 0.5),
        endRadius: size * 0.45,
        options: []
    )
    
    // Subtle inner circular grid lines
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.08).cgColor)
    ctx.setLineWidth(size * 0.008)
    ctx.addEllipse(in: iconRect.insetBy(dx: size * 0.15, dy: size * 0.15))
    ctx.strokePath()
    
    // Pulse waveform path
    let wavePath = CGMutablePath()
    let midY = size * 0.5
    let startX = size * 0.18
    let endX = size * 0.82
    let width = endX - startX
    
    wavePath.move(to: CGPoint(x: startX, y: midY))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.25, y: midY))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.35, y: midY + size * 0.10))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.45, y: midY - size * 0.25))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.55, y: midY + size * 0.25))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.65, y: midY - size * 0.08))
    wavePath.addLine(to: CGPoint(x: startX + width * 0.75, y: midY))
    wavePath.addLine(to: CGPoint(x: endX, y: midY))
    
    // Wave glow
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: size * 0.06, color: NSColor(red: 0.0, green: 0.9, blue: 0.85, alpha: 0.9).cgColor)
    ctx.addPath(wavePath)
    ctx.setStrokeColor(NSColor(red: 0.0, green: 0.95, blue: 0.85, alpha: 1.0).cgColor)
    ctx.setLineWidth(size * 0.035)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()
    
    // Wave core line
    ctx.addPath(wavePath)
    ctx.setStrokeColor(NSColor.white.cgColor)
    ctx.setLineWidth(size * 0.018)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    
    // Center pulse dot
    let dotCenter = CGPoint(x: startX + width * 0.55, y: midY + size * 0.25)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.setShadow(offset: .zero, blur: size * 0.04, color: NSColor(red: 0.0, green: 1.0, blue: 0.8, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: CGRect(x: dotCenter.x - size * 0.025, y: dotCenter.y - size * 0.025, width: size * 0.05, height: size * 0.05))
    
    ctx.restoreGState()
    
    // Inner border highlight
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.18).cgColor)
    ctx.setLineWidth(size * 0.015)
    ctx.strokePath()
    ctx.restoreGState()
    
    img.unlockFocus()
    return img
}

let fileManager = FileManager.default
let iconsetDir = "/tmp/MacPulse.iconset"
try? fileManager.removeItem(atPath: iconsetDir)
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in sizes {
    let img = renderIcon(size: item.size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(iconsetDir)/\(item.name)")
        try? png.write(to: url)
    }
}

print("Iconset created successfully at \(iconsetDir)")
