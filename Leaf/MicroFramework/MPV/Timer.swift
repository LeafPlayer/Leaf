//
//  Timer.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/29.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Foundation
final class RepeatingTimer {
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now(), repeating: .milliseconds(100))
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        t.resume()
        t.suspend()
        return t
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed { return }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended { return }
        state = .suspended
        timer.suspend()
    }
}
