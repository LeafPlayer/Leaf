//
//  NSWindows+Ext.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/10/27.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
extension NSWindow {
    public func absCenter() {
        guard let screenFrame = NSScreen.main?.frame else {
            center()
            return
        }
        let x = (screenFrame.width - frame.width) / 2
        let y = (screenFrame.height - frame.height) / 2
        let rect = NSMakeRect(x, y, frame.width, frame.height)
        setFrame(rect, display: true)
    }
    
    public func fadeIn(duration: TimeInterval = 0.3) {
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        animator().alphaValue = 1
        NSAnimationContext.endGrouping()
    }
    
    public func fadeOut(scaling: Bool = false, done: @escaping () -> Void) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.5
        NSAnimationContext.current.completionHandler = { [weak self] in
            self?.orderOut(nil)
            self?.alphaValue = 1
            self?.contentView?.layer?.transform = CATransform3DIdentity
            done()
        }
        if scaling {
            contentView?.wantsLayer = true
            let tran = CATransform3DMakeScale(0.9, 0.9, 0.9)
            animator().contentView?.layer?.transform = tran
        }
        animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }
}
