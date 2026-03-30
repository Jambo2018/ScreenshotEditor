//
//  PinWindow.swift
//  ScreenshotEditor
//
//  Floating window for pinned screenshots (Snipaste-style)
//

import AppKit
import SwiftUI

/// A floating window that displays a pinned screenshot
/// - Supports drag, zoom, rotate, opacity adjustment
/// - Non-activating: doesn't steal focus from other apps
class PinWindow: NSPanel {

    let id: UUID
    private var imageView: NSImageView
    private var overlayView: PinOverlayView?
    private var keyMonitor: Any?
    private var isClosing = false

    // State
    var opacityValue: Double = 1.0
    var rotationAngle: Double = 0.0
    var scaleFactor: CGFloat = 1.0

    // Callbacks
    var onClose: ((UUID) -> Void)?

    // MARK: - Initialization

    init(id: UUID, image: NSImage, position: CGPoint) {
        self.id = id
        self.imageView = NSImageView(image: image)

        // Calculate initial window size
        let imageSize = image.size
        let initialSize = NSSize(
            width: min(imageSize.width, 800),
            height: min(imageSize.height, 600)
        )

        super.init(
            contentRect: NSRect(origin: position, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Window configuration
        self.level = .floating
        self.isOpaque = false
        self.hasShadow = true
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]
        self.isMovableByWindowBackground = true

        // Enable scroll wheel events
        self.contentView?.addObserver(self, forKeyPath: "frame", options: [.new], context: nil)

        // Setup content
        setupContentView()

        // Setup gestures
        setupGestures()

        // Setup keyboard monitor
        setupKeyboardMonitor()

        // Show window
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        #if DEBUG
        print("[PinWindow] deinitialized: \(id)")
        #endif
    }

    // MARK: - Setup

    private func setupContentView() {
        // Create hosting view with SwiftUI overlay
        overlayView = PinOverlayView(
            onToggleControls: { [weak self] in
                self?.toggleOverlay()
            }
        )

        let hostingView = NSHostingView(rootView: PinWindowContainerView(
            imageView: imageView,
            overlayView: overlayView
        ))

        // Add pan gesture for drag
        let panRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panRecognizer.buttonMask = 0x1 // Left mouse button only
        hostingView.addGestureRecognizer(panRecognizer)

        self.contentView = hostingView
    }

    private func setupGestures() {
        guard let view = contentView else { return }

        // Pan gesture for drag - using alternative approach
        // Note: NSPanGesture requires macOS 10.10+

        // Magnification gesture for zoom
        let magnificationGesture = NSMagnificationGestureRecognizer(
            target: self,
            action: #selector(handleMagnification(_:))
        )
        view.addGestureRecognizer(magnificationGesture)

        // Rotation gesture
        let rotationGesture = NSRotationGestureRecognizer(
            target: self,
            action: #selector(handleRotation(_:))
        )
        view.addGestureRecognizer(rotationGesture)

        // Double-click to close
        let doubleClickGesture = NSClickGestureRecognizer(
            target: self,
            action: #selector(handleDoubleClick(_:))
        )
        doubleClickGesture.numberOfClicksRequired = 2
        view.addGestureRecognizer(doubleClickGesture)
    }

    private func setupKeyboardMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ESC to close
            if event.keyCode == 53 {
                self?.closeWindow()
                return nil
            }
            return event
        }
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let delta = gesture.translation(in: view)

        // Update window position
        let newOrigin = NSPoint(
            x: frame.origin.x + delta.x,
            y: frame.origin.y - delta.y
        )

        // Keep window on screen
        guard let screen = NSScreenContaining(window: self) else { return }
        let visibleFrame = screen.visibleFrame

        // Clamp to screen bounds
        let clampedOrigin = NSPoint(
            x: max(visibleFrame.minX, min(newOrigin.x, visibleFrame.maxX - frame.width)),
            y: max(visibleFrame.minY, min(newOrigin.y, visibleFrame.maxY - frame.height))
        )

        self.setFrameOrigin(clampedOrigin)
        gesture.setTranslation(.zero, in: view)
    }

    @objc private func handleMagnification(_ gesture: NSMagnificationGestureRecognizer) {
        let magnification = gesture.magnification

        // Command + scroll for zoom
        if NSEvent.modifierFlags.contains(.command) {
            applyScale(delta: magnification)
        }

        gesture.magnification = 0
    }

    @objc private func handleRotation(_ gesture: NSRotationGestureRecognizer) {
        let rotation = gesture.rotation

        // Option + scroll for rotate (or two-finger rotate on trackpad)
        if NSEvent.modifierFlags.contains(.option) {
            applyRotation(delta: rotation)
        }

        gesture.rotation = 0
    }

    @objc private func handleScroll(_ event: NSEvent) {
        let scrollDelta = event.deltaY

        if NSEvent.modifierFlags.contains(.command) {
            // Command + scroll: zoom
            applyScale(delta: scrollDelta * 0.01)
        } else if NSEvent.modifierFlags.contains(.option) {
            // Option + scroll: opacity
            applyOpacity(delta: scrollDelta * 0.01)
        }
    }

    @objc private func handleDoubleClick(_ gesture: NSClickGestureRecognizer) {
        closeWindow()
    }

    // MARK: - Transform Methods

    private func applyScale(delta: CGFloat) {
        let newScale = max(0.1, min(scaleFactor + delta, 5.0))
        scaleFactor = newScale

        // Apply scale to content view
        contentView?.layer?.transform = CATransform3DMakeScale(scaleFactor, scaleFactor, 1.0)
    }

    private func applyRotation(delta: CGFloat) {
        rotationAngle += delta * (.pi / 180) // Convert to radians

        // Apply rotation
        contentView?.layer?.transform = CATransform3DMakeRotation(rotationAngle, 0, 0, 1.0)
    }

    private func applyOpacity(delta: Double) {
        opacityValue = max(0.3, min(opacityValue - delta, 1.0))
        alphaValue = CGFloat(opacityValue)
    }

    // MARK: - Overlay

    private func toggleOverlay() {
        NotificationCenter.default.post(name: NSNotification.Name("TogglePinOverlay"), object: nil)
    }

    // MARK: - Window Closure

    func closeWindow() {
        guard !isClosing else { return }
        isClosing = true

        let callback = onClose
        let pinId = id

        // Animate out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            self.contentView = nil
            callback?(pinId)
        })
    }

    // MARK: - Utility

    private func NSScreenContaining(window: NSWindow) -> NSScreen? {
        let frame = window.frame
        let visibleScreens = NSScreen.screens

        guard let mainScreen = NSScreen.main else { return visibleScreens.first }

        for screen in visibleScreens {
            if screen.frame.intersects(frame) {
                return screen
            }
        }

        return mainScreen
    }
}

// MARK: - SwiftUI Container View

struct PinWindowContainerView: NSViewRepresentable {
    let imageView: NSImageView
    let overlayView: PinOverlayView?

    func makeNSView(context: Context) -> NSView {
        let container = NSView()

        // Add image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        container.addSubview(imageView)

        // Add overlay
        if let overlay = overlayView {
            let hostingView = NSHostingView(rootView: overlay)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(hostingView)

            // Full screen overlay
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: container.topAnchor),
                hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }

        // Image view constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No updates needed
    }
}

// MARK: - Pin Overlay View

struct PinOverlayView: View {
    @State private var controlsVisible: Bool = true

    var onToggleControls: () -> Void

    var body: some View {
        Group {
            if controlsVisible {
                VStack {
                    // Top toolbar
                    HStack {
                        Text("Pin")
                            .font(.caption)
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: onToggleControls) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))

                    Spacer()

                    // Bottom controls
                    HStack {
                        // Zoom controls
                        VStack(spacing: 4) {
                            Text("⌘ + Scroll")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("Zoom")
                                .font(.caption)
                                .foregroundColor(.white)
                        }

                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 30)

                        // Opacity controls
                        VStack(spacing: 4) {
                            Text("⌥ + Scroll")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("Opacity")
                                .font(.caption)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Rotate controls
                        VStack(spacing: 4) {
                            Text("⇧ + ⌥ + Scroll")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("Rotate")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TogglePinOverlay"))) { _ in
            controlsVisible.toggle()
        }
    }
}
