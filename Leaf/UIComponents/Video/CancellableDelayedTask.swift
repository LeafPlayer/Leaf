//
//  CancellableDelayedTask.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/24.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Foundation
public final class CancellableDelayedTask {
    public init(delay: Double, task: @escaping () -> Void) {
        let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(delay * 1000))
        DispatchQueue.main.asyncAfter(deadline: time) {[weak self] in
            guard self?._cancelled == false else { return }
            task()
        }
    }
    private lazy var _cancelled = false
    
    public func cancel() { _cancelled = true }
}
