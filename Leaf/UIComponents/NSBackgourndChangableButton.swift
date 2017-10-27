//
//  NSBackgourndChangableButton.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/2.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa

final class NSBackgourndChangableButton: NSView {
    typealias Action = (NSBackgourndChangableButton) -> Void
    private let normalBackground = CGColor(gray: 0, alpha: 0)
    private let hoverBackground = CGColor(gray: 0, alpha: 0.25)
    private let pressedBackground = CGColor(gray: 0, alpha: 0.35)
    
    public private(set) var action: Action = { _ in }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    convenience init(action: @escaping Action) {
        self.init(frame: .zero)
        self.action = action
        wantsLayer = true
        layer?.cornerRadius = 4
    }
    
    override var frame: NSRect {
        get { return super.frame }
        set {
            for area in trackingAreas { removeTrackingArea(area) }
            super.frame = newValue
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil))
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = hoverBackground
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = normalBackground
    }
    
    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = pressedBackground
        action(self)
    }
    
    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = hoverBackground
    }
    
}
