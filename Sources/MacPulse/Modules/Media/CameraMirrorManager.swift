import AppKit
import AVFoundation
import SwiftUI

// MARK: - Camera Mirror Manager
@MainActor
public final class CameraMirrorManager: NSObject, ObservableObject {
    public static let shared = CameraMirrorManager()
    
    @Published public private(set) var isStreaming: Bool = false
    @Published public private(set) var hasPermission: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    public let captureSession = AVCaptureSession()
    private var isConfigured = false
    
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    public func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.hasPermission = granted
                    if granted {
                        self?.configureSession()
                    }
                }
            }
        default:
            hasPermission = false
        }
    }
    
    private func configureSession() {
        guard !isConfigured else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified)
                ?? AVCaptureDevice.default(for: .video) else {
            errorMessage = "No camera found"
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                isConfigured = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        captureSession.commitConfiguration()
    }
    
    public func start() {
        checkAuthorization()
        guard hasPermission else { return }
        
        if !isConfigured {
            configureSession()
        }
        
        guard isConfigured, !captureSession.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [session = self.captureSession] in
            session.startRunning()
            await MainActor.run { [weak self] in
                self?.isStreaming = true
            }
        }
    }
    
    public func stop() {
        guard captureSession.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [session = self.captureSession] in
            session.stopRunning()
            await MainActor.run { [weak self] in
                self?.isStreaming = false
            }
        }
    }
    
    public func toggle() {
        if isStreaming {
            stop()
        } else {
            start()
        }
    }
}

// MARK: - Native Mirror NSView
public final class CameraPreviewNSView: NSView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    public override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 14
        setupLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 14
        setupLayer()
    }
    
    private func setupLayer() {
        let session = CameraMirrorManager.shared.captureSession
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        // Mirror horizontally
        layer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0)
        self.layer?.addSublayer(layer)
        self.previewLayer = layer
    }
    
    public override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}

// MARK: - SwiftUI Camera Preview Representable
public struct CameraPreviewView: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView(frame: .zero)
        return view
    }
    
    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.layout()
    }
}
