import AppKit
import SwiftUI

/// Where the notch is on the current screen (or where a floating pill should go
/// on Macs without one).
struct NotchLayout: Equatable {
    var hasNotch: Bool
    /// Notch width / height in points (menu bar height when there is no notch).
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    /// Width of each "ear" that extends the black notch to the left and right.
    var earWidth: CGFloat = 78
    var expandedHeight: CGFloat = 132

    var collapsedSize: CGSize {
        hasNotch ? CGSize(width: notchWidth + earWidth * 2, height: notchHeight) : CGSize(width: 168, height: 36)
    }

    var expandedSize: CGSize {
        CGSize(width: max(collapsedSize.width, 360), height: (hasNotch ? notchHeight : 0) + expandedHeight)
    }

    static func make(for screen: NSScreen) -> NotchLayout {
        let top = screen.safeAreaInsets.top
        if top > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            let width = screen.frame.width - left.width - right.width
            return NotchLayout(hasNotch: true, notchWidth: max(120, width), notchHeight: top)
        }
        let menuBar = max(24, screen.frame.maxY - screen.visibleFrame.maxY)
        return NotchLayout(hasNotch: false, notchWidth: 0, notchHeight: menuBar)
    }
}

/// Borderless, non-activating panel that floats above the menu bar.
final class NotchPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class NotchPanelController {
    private var panel: NotchPanel?
    private var hosting: NSHostingView<NotchRootView>?
    private var layout: NotchLayout?
    private var lastExpanded = false
    private var visible = false

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in MacModel.shared.refreshPanel() }
        }
    }

    private var screen: NSScreen? {
        // Prefer the built-in display with a notch, then the main screen.
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first
    }

    func update(visible: Bool, expanded: Bool) {
        guard visible, let screen else {
            if self.visible {
                panel?.orderOut(nil)
                self.visible = false
            }
            return
        }
        let layout = NotchLayout.make(for: screen)
        if panel == nil {
            let p = NotchPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            let host = NSHostingView(rootView: NotchRootView(layout: layout))
            host.translatesAutoresizingMaskIntoConstraints = true
            p.contentView = host
            panel = p
            hosting = host
        }
        if layout != self.layout {
            hosting?.rootView = NotchRootView(layout: layout)
            self.layout = layout
        }
        let size = expanded ? layout.expandedSize : layout.collapsedSize
        let x = screen.frame.midX - size.width / 2
        let y: CGFloat = layout.hasNotch ? screen.frame.maxY - size.height : screen.visibleFrame.maxY - size.height - 8
        let frame = NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height)
        if panel?.frame != frame {
            panel?.setFrame(frame, display: true, animate: expanded != lastExpanded)
        }
        lastExpanded = expanded
        if !self.visible {
            panel?.orderFrontRegardless()
            self.visible = true
        }
    }
}
