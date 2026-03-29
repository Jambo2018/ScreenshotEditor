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

    private var overlayView: CaptureOverlayView?
    private var keyMonitor: Any?
    private var isClosing = false

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

        overlayView?.onConfirm = { [weak self] rect in
            self?.handleCaptureConfirmed(rect)
        }

        overlayView?.onCancel = { [weak self] in
            self?.handleCaptureCancelled()
        }

        guard let view = overlayView else { return }
        self.contentView = NSHostingView(rootView: view)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.handleCaptureCancelled()
                return nil
            }
            return event
        }

        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    deinit {
        #if DEBUG
        print("[Overlay] deinitialized")
        #endif
    }

    private func handleCaptureConfirmed(_ rect: CGRect) {
        guard !isClosing else { return }
        isClosing = true

        cleanupResources()

        // Close window first
        self.contentView = nil
        overlayView = nil
        self.orderOut(nil)
        self.close()

        // Notify parent on next run loop to ensure window close is processed
        DispatchQueue.main.async { [weak self] in
            self?.onCaptureConfirmed?(rect)
        }
    }

    private func handleCaptureCancelled() {
        guard !isClosing else { return }
        isClosing = true

        cleanupResources()

        // Close window first
        self.contentView = nil
        overlayView = nil
        self.orderOut(nil)
        self.close()

        // Notify parent on next run loop
        DispatchQueue.main.async { [weak self] in
            self?.onCaptureCancelled?()
        }
    }

    private func cleanupResources() {
        onCaptureConfirmed = nil
        onCaptureCancelled = nil
        overlayView?.onConfirm = nil
        overlayView?.onCancel = nil

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
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
                            endPoint = value.location
                        } else {
                            endPoint = value.location
                        }
                    }
                    .onEnded { value in
                        print("[Gesture] onEnded called")

                        let rect = CGRect(
                            x: max(0, min(startPoint.x, endPoint.x)),
                            y: max(0, min(startPoint.y, endPoint.y)),
                            width: abs(endPoint.x - startPoint.x),
                            height: abs(endPoint.y - startPoint.y)
                        )
                        print("[Gesture] Calculated rect: \(rect.width)x\(rect.height)")

                        isSelecting = false

                        // Always call onConfirm - let parent decide if rect is valid
                        onConfirm?(rect)
                    }
            )
        }
        .ignoresSafeArea()
    }

    func selectionRect(in size: CGSize) -> CGRect {
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
