//
//  NSFlipView.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/2.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
public final class NSFlipView: NSView {
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    public override var isFlipped: Bool { return true }
}

