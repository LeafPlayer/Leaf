//
//  WindowControlButtonsGroup.swift
//  LuooSkinEditor
//
//  Created by lincolnlaw on 2017/7/12.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
extension Notification.Name {
    public static let FullScreenModeChange: Notification.Name = Notification.Name(rawValue: "FullScreenModeChange")
    public static let DefocusChanged: Notification.Name = Notification.Name(rawValue: "DefocusChanged")
}

public final class WindowControlButtonsGroup: NSView, NSWindowDelegate {
    public static let NotificationKey = "fullscreen"
    public private(set) lazy var closeButton: WindowControlButton =  self.button(for: .close)
    public private(set) lazy var minimizeButton: WindowControlButton =  self.button(for: .minimize)
    public private(set) lazy var fullscreenButton: WindowControlButton =  self.button(for: .fullscreen)
    
    public private(set) weak var targetWindow: NSWindow?
    public private(set) var strongHoldWindow: NSWindow?
    public private(set) var colorType: WindowControlButton.DefaultColorType = .colorful
    public var enableModes: [WindowControlButton.ControlType] = []
    private var _currentWindow: NSWindow? { return targetWindow ?? strongHoldWindow }
    private var _canMinimizeButtonWork = true
    private var _focusOb: NSObjectProtocol?

    
    deinit {
        guard let ob = _focusOb else { return }
        NotificationCenter.default.removeObserver(ob)
    }
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    

    public convenience init(window: NSWindow, strongHold: Bool = false, enableModes: [WindowControlButton.ControlType] = [.close, .minimize, .fullscreen], colorType: WindowControlButton.DefaultColorType = .colorful) {
        let rect = NSMakeRect(10, 0, 52, 12)
        self.init(frame: rect)
        self.colorType = colorType
        self.enableModes = enableModes
        if strongHold { strongHoldWindow = window }
        else { targetWindow = window }
        window.delegate = self
        addSubview(closeButton)
        addSubview(minimizeButton)
        addSubview(fullscreenButton)

        closeButton.clickHandler = { [unowned self] in
            self.close()
        }

        minimizeButton.clickHandler = { [unowned self] in
            self._currentWindow?.miniaturize(nil)
        }

        fullscreenButton.clickHandler = { [unowned self] in
            self._currentWindow?.toggleFullScreen(nil)
        }
        _focusOb = NotificationCenter.default.addObserver(forName: NSNotification.Name.DefocusChanged, object: nil, queue: nil) {[unowned self] (note) in
            if let target = note.object as? NSWindow {
                if target != self._currentWindow {
                    self.toActive(false)
                }
            } else {
                self.toActive(false)
            }
        }
    }

    public override func layout() {
        super.layout()
        minimizeButton.frame.origin.x = closeButton.frame.maxX + 8
        fullscreenButton.frame.origin.x = minimizeButton.frame.maxX + 8
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for item in trackingAreas { removeTrackingArea(item) }
        let area = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.assumeInside], owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    public override func mouseEntered(with _: NSEvent) { toActive(true) }

    public override func mouseExited(with _: NSEvent) { toActive(false) }
    
    private func button(for type: WindowControlButton.ControlType) -> WindowControlButton {
        let isEnabled = enableModes.contains(type)
        return WindowControlButton(type: type, colorType: colorType, isEnabled: isEnabled)
    }

    private func toActive(_ active: Bool) {
        let total = [closeButton, minimizeButton, fullscreenButton]
        for item in total {
            if _canMinimizeButtonWork == false, item == minimizeButton { continue }
            item.toActive(active)
        }
    }

    private func toggleVisible(hide: Bool) {
        let total = [closeButton, minimizeButton, fullscreenButton]
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        for item in total {
            item.animator().alphaValue = hide ? 0 : 1
        }
        NSAnimationContext.endGrouping()
    }

    public func windowDidExitFullScreen(_: Notification) {
        _canMinimizeButtonWork = true
        toActive(false)
        toggleVisible(hide: false)
        NotificationCenter.default.post(name: .FullScreenModeChange, object: targetWindow, userInfo: [WindowControlButtonsGroup.NotificationKey : false])
    }

    public func windowDidEnterFullScreen(_: Notification) {
        _canMinimizeButtonWork = false
        toActive(false)
        minimizeButton.toActive(false)
        toggleVisible(hide: true)
        NotificationCenter.default.post(name: .FullScreenModeChange, object: targetWindow, userInfo: [WindowControlButtonsGroup.NotificationKey : true])
    }
    
    public func windowDidBecomeKey(_ notification: Notification) {
        NotificationCenter.default.post(name: NSNotification.Name.DefocusChanged, object: _currentWindow)
    }
    
    
    public func close() {
        NSAnimationContext.runAnimationGroup({ (ctx) in
            ctx.duration = 0.3
            self._currentWindow?.animator().alphaValue = 0
        }, completionHandler: {[weak self] in
            self?._currentWindow?.orderOut(nil)
            self?._currentWindow?.alphaValue = 1
            self?._currentWindow?.close()
            if self?.strongHoldWindow != nil {
                self?.strongHoldWindow = nil
            }
        })
    }
}

public final class WindowControlButton: NSView {
    
    public private(set) lazy var colorType: DefaultColorType = .colorful
    public private(set) lazy var type: ControlType = .none
    public private(set) lazy var isEnabled: Bool = true
    
    private var _canPerformClick = false
    
    public lazy var clickHandler: () -> Void = {}
    
    private var _iconLayer: CALayer?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    public convenience init(type: ControlType, colorType: DefaultColorType = .colorful, isEnabled: Bool = true) {
        self.init(frame: NSMakeRect(0, 0, 12, 12))
        self.colorType = colorType
        self.type = type
        self.isEnabled = isEnabled
        initialize()
    }

    private func initialize() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 0.5
        
        let icon = type.pathLayer
        _iconLayer = icon
        _iconLayer?.speed = 999
        _iconLayer?.isHidden = true
        layer?.addSublayer(icon)
        
        (isEnabled && colorType == .colorful) ? colorful() : mono()
    }
    

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for item in trackingAreas { removeTrackingArea(item) }
        let area = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.assumeInside], owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    public override var mouseDownCanMoveWindow: Bool { return false }

    public override func mouseDown(with _: NSEvent) {
        _canPerformClick = true
    }

    public override func mouseUp(with _: NSEvent) {
        guard isEnabled else { return }
        if _canPerformClick { clickHandler() }
    }

    public override func mouseExited(with _: NSEvent) {
        _canPerformClick = false
    }

    private func colorful() {
        layer?.backgroundColor = type.backgroundColor.cgColor
        layer?.borderColor = type.borderColor.cgColor
    }
    
    private func mono() {
        layer?.backgroundColor = ControlType.none.backgroundColor.cgColor
        layer?.borderColor = ControlType.none.borderColor.cgColor
    }

    public func toActive(_ active: Bool) {
        if isEnabled { _iconLayer?.isHidden = !active }
        if colorType == .mono { active ? colorful() : mono()  }
    }
}

extension WindowControlButton {
    public enum DefaultColorType { case colorful, mono }
    public enum ControlType {
        case close, minimize, fullscreen, none
        var borderColor: NSColor {
            switch self {
            case .close: return NSColor(red: 0.84, green: 0.27, blue: 0.24, alpha: 1.0)
            case .minimize: return NSColor(red: 0.85, green: 0.62, blue: 0.04, alpha: 1.0)
            case .fullscreen: return NSColor(red: 0.29, green: 0.66, blue: 0.15, alpha: 1.0)
            case .none: return NSColor(red:0.33, green:0.33, blue:0.33, alpha:1.0)
            }
        }
        
        var backgroundColor: NSColor {
            switch self {
            case .close: return
                NSColor(red:1.00, green:0.38, blue:0.35, alpha:1.0)
            case .minimize: return NSColor(red:1.00, green:0.74, blue:0.18, alpha:1.0)
            case .fullscreen: return NSColor(red:0.16, green:0.79, blue:0.26, alpha:1.0)
            case .none: return NSColor(red:0.33, green:0.33, blue:0.33, alpha:1.0)
            }
        }
        
        var contentColor: NSColor {
            switch self {
            case .close: return NSColor(red: 0.27, green: 0.01, blue: 0.00, alpha: 1.0)
            case .minimize: return NSColor(red: 0.58, green: 0.34, blue: 0.00, alpha: 1.0)
            case .fullscreen: return NSColor(red: 0.15, green: 0.39, blue: 0.00, alpha: 1.0)
            default: return NSColor.clear
            }
        }
        
        var pathLayer: CALayer {
            switch self {
            case .close: return closeLayer()
            case .minimize: return minimizeLayer()
            case .fullscreen: return fullscreenLayer()
            default: return CALayer()
            }
        }
        
        private func closeLayer() -> CALayer {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 3.5, y: 3.5))
            path.addLine(to: CGPoint(x: 8.5, y: 8.5))
            path.move(to: CGPoint(x: 8.5, y: 3.5))
            path.addLine(to: CGPoint(x: 3.5, y: 8.5))
            path.closeSubpath()
            
            let layer = CAShapeLayer()
            layer.lineWidth = 1.0
            layer.strokeColor = contentColor.cgColor
            layer.frame = NSMakeRect(0, 0, 5, 5)
            layer.path = path
            return layer
        }
        
        private func minimizeLayer() -> CALayer {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 2, y: 6))
            path.addLine(to: CGPoint(x: 10, y: 6))
            path.closeSubpath()
            let layer = CAShapeLayer()
            layer.lineWidth = 1.0
            layer.strokeColor = contentColor.cgColor
            layer.frame = NSMakeRect(0, 0, 5, 5)
            layer.path = path
            return layer
        }
        
        private func fullscreenLayer() -> CALayer {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 3, y: 3))
            path.addLine(to: CGPoint(x: 3, y: 8))
            path.addLine(to: CGPoint(x: 8, y: 3))
            path.addLine(to: CGPoint(x: 3, y: 3))
            path.closeSubpath()
            
            path.move(to: CGPoint(x: 4, y: 9))
            path.addLine(to: CGPoint(x: 9, y: 9))
            path.addLine(to: CGPoint(x: 9, y: 4))
            path.addLine(to: CGPoint(x: 4, y: 9))
            path.closeSubpath()
            
            let layer = CAShapeLayer()
            layer.fillColor = contentColor.cgColor
            layer.frame = NSMakeRect(0, 0, 6, 6)
            layer.path = path
            return layer
        }
    }
}
