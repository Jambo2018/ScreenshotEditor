//
//  CaptureOverlayView.swift
//  ScreenshotEditor
//
//  Full-screen overlay for region selection during screen capture
//

import SwiftUI

class CaptureOverlayWindow: NSWindow {

    var onCaptureConfirmed: ((CGRect) -> Void)?
    var onCaptureCancelled: (() -> Void)?

    private var overlayView: CaptureOverlayView
    private var keyMonitor: Any?
    private var isSelectingHandler: (() -> Bool)?

    init(screen: NSScreen) {
        overlayView = CaptureOverlayView()

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenNone]

        self.contentView = NSHostingView(rootView: overlayView)

        // Store the isSelecting handler
        isSelectingHandler = { [weak self] in
            return self?.overlayView.isSelecting ?? false
        }

        self.overlayView.onConfirm = { [weak self] rect in
            self?.confirmCapture(rect)
        }
        self.overlayView.onCancel = { [weak self] in
            self?.cancelCapture()
        }

        // Monitor keyboard events
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.cancelCapture()
                return nil
            }
            if event.keyCode == 36 && (self?.isSelectingHandler?() ?? false) { // Return
                self?.confirmCapture()
                return nil
            }
            return event
        }

        // Make window key and order front
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func confirmCapture(_ rect: CGRect? = nil) {
        guard let rect = rect else { return }
        onCaptureConfirmed?(rect)
        closeOverlay()
    }

    func cancelCapture() {
        onCaptureCancelled?()
        closeOverlay()
    }

    func closeOverlay() {
        // Remove monitor first
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        // Remove from parent screen
        self.orderOut(nil)

        // Make window non-key and remove from runloop
        self.resignKey()

        // Force close
        self.close()
    }
}

struct CaptureOverlayView: View {

    @State private var startPoint: CGPoint = .zero
    @State private var endPoint: CGPoint = .zero
    @State var isSelecting: Bool = false

    var onConfirm: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent dark overlay
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()

                // Selection rectangle
                if isSelecting {
                    let rect = selectionRect(in: geometry.size)
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(
                            Color.white.opacity(0.2)
                        )
                        .frame(
                            width: rect.width,
                            height: rect.height
                        )
                        .position(x: rect.midX, y: rect.midY)

                    // Dimensions label
                    Text("\(Int(rect.width)) × \(Int(rect.height))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .position(x: rect.midX, y: rect.minY - 25)
                }

                // Instructions
                VStack {
                    Text("Drag to select area • Release to capture • ESC to cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 40)

                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isSelecting {
                            isSelecting = true
                            startPoint = value.location
                        }
                        endPoint = value.location
                    }
                    .onEnded { value in
                        isSelecting = false

                        // Auto-confirm on drag end with a valid selection
                        let rect = selectionRect(in: geometry.size)
                        if rect.width > 10 && rect.height > 10 {
                            // Valid selection - auto-confirm after short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onConfirm?(rect)
                            }
                        }
                    }
            )
            // Tap to confirm (if selection exists)
            .onTapGesture {
                if isSelecting {
                    let rect = selectionRect(in: geometry.size)
                    if rect.width > 10 && rect.height > 10 {
                        onConfirm?(rect)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func selectionRect(in size: CGSize) -> CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)

        return CGRect(
            x: max(0, minX),
            y: max(0, minY),
            width: min(maxX - minX, size.width),
            height: min(maxY - minY, size.height)
        )
    }
}
