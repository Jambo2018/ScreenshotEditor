//
//  CaptureOverlayWindow.swift
//  ScreenshotEditor
//
//  Full-screen overlay window for screen region selection
//  Fixed version with proper lifecycle management
//

import AppKit
import SwiftUI

class CaptureOverlayWindow: NSWindow {

    var onCaptureConfirmed: ((CGRect) -> Void)?
    var onCaptureCancelled: (() -> Void)?

    private var overlayView: CaptureOverlayView?
    private var keyMonitor: Any?
    private var isClosing = false
    private var hasCompleted = false

    init(screen: NSScreen) {
        overlayView = CaptureOverlayView()

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver + 1 // Higher than other overlays
        self.isOpaque = false
        self.hasShadow = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenNone, .ignoresCycle]
        
        // Make window key and order front
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        
        // Activate app to receive events
        NSApp.activate(ignoringOtherApps: true)
        self.makeMainWindow()

        overlayView?.onConfirm = { [weak self] rect in
            self?.handleCaptureConfirmed(rect)
        }

        overlayView?.onCancel = { [weak self] in
            self?.handleCaptureCancelled()
        }

        guard let view = overlayView else { return }
        self.contentView = NSHostingView(rootView: view)

        // Monitor for ESC key
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.handleCaptureCancelled()
                return nil
            }
            return event
        }
        
        #if DEBUG
        print("[Overlay] Window created and shown")
        #endif
    }

    deinit {
        #if DEBUG
        print("[Overlay] deinitialized")
        #endif
    }

    private func handleCaptureConfirmed(_ rect: CGRect) {
        guard !isClosing && !hasCompleted else { return }
        hasCompleted = true
        isClosing = true

        #if DEBUG
        print("[Overlay] Capture confirmed, rect: \(rect)")
        #endif

        // Remove event monitor first
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        // Clear callbacks to prevent re-entrancy
        let confirmCallback = onCaptureConfirmed
        onCaptureConfirmed = nil
        onCaptureCancelled = nil
        
        // Clear view references
        overlayView?.onConfirm = nil
        overlayView?.onCancel = nil
        overlayView = nil
        self.contentView = nil

        // Close window
        self.orderOut(nil)
        self.close()

        // Call callback after window is fully closed
        // Use dispatch to ensure this runs after window close completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            confirmCallback?(rect)
        }
    }

    private func handleCaptureCancelled() {
        guard !isClosing && !hasCompleted else { return }
        hasCompleted = true
        isClosing = true

        #if DEBUG
        print("[Overlay] Capture cancelled")
        #endif

        // Remove event monitor first
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        // Clear callbacks
        let cancelCallback = onCaptureCancelled
        onCaptureConfirmed = nil
        onCaptureCancelled = nil
        
        // Clear view references
        overlayView?.onConfirm = nil
        overlayView?.onCancel = nil
        overlayView = nil
        self.contentView = nil

        // Close window
        self.orderOut(nil)
        self.close()

        // Call callback after window is fully closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cancelCallback?()
        }
    }
    
    override func orderOut(_ sender: Any?) {
        super.orderOut(sender)
        #if DEBUG
        print("[Overlay] Window ordered out")
        #endif
    }
    
    override func close() {
        super.close()
        #if DEBUG
        print("[Overlay] Window closed")
        #endif
    }
}

// MARK: - Capture Overlay View

struct CaptureOverlayView: View {

    @State private var startPoint: CGPoint = .zero
    @State private var endPoint: CGPoint = .zero
    @State private var isSelecting: Bool = false
    @State private var hasCompleted: Bool = false

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
                if isSelecting && !hasCompleted {
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
                        guard !hasCompleted else { return }
                        if !isSelecting {
                            isSelecting = true
                            startPoint = value.location
                            endPoint = value.location
                        } else {
                            endPoint = value.location
                        }
                    }
                    .onEnded { value in
                        guard !hasCompleted else { return }
                        hasCompleted = true
                        
                        #if DEBUG
                        print("[Gesture] onEnded called")
                        #endif

                        let rect = CGRect(
                            x: max(0, min(startPoint.x, endPoint.x)),
                            y: max(0, min(startPoint.y, endPoint.y)),
                            width: abs(endPoint.x - startPoint.x),
                            height: abs(endPoint.y - startPoint.y)
                        )
                        
                        #if DEBUG
                        print("[Gesture] Calculated rect: \(rect.width)x\(rect.height)")
                        #endif

                        isSelecting = false

                        // Call onConfirm - parent will handle window closure
                        onConfirm?(rect)
                    }
            )
        }
        .ignoresSafeArea()
        .focusable(false)
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
