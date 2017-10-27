//
//  NSWindow+AutoHide.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/23.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
extension NSWindow.Level {
    static let iinaFloating = NSWindow.Level(NSWindow.Level.floating.rawValue - 1)
    static let iinaBlackScreen = NSWindow.Level(NSWindow.Level.mainMenu.rawValue + 1)
}
extension NSWindow {
    public var isFullScreenMode: Bool {
        return styleMask.contains(.fullScreen)
    }
}
