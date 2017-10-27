//
//  Application.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/10/27.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa

final class Application: NSApplication {
    private var _ob: NSObjectProtocol?
    
    deinit { if let ob = _ob { NotificationCenter.default.removeObserver(ob) } }
    override init() {
        super.init()
        runDI()
        handlerAlert()
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    
    private func runDI() {
        DI.register(class: LeafPlayer.self)
    }
    
    private func handlerAlert() {
        _ob = NotificationCenter.default.addObserver(forName: NSNotification.Name.critical, object: nil, queue: nil) {[unowned self] (note) in
            guard let message = note.object as? String else { return }
            self.show(message: message, style: .critical)
        }
        _ob = NotificationCenter.default.addObserver(forName: NSNotification.Name.normal, object: nil, queue: nil) {[unowned self] (note) in
            guard let message = note.object as? String else { return }
            self.show(message: message, style: .informational)
        }
    }
    private func show(message: String, style: NSAlert.Style) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.informativeText = message
            alert.alertStyle = style
            alert.runModal()
        }
    }
}

extension Application {
    private static let appDelegate = AppDelegate()
//    static let mainWindow: MainWindowController = { MainWindowController() }()
    static var introWindowController: IntroWindowController = IntroWindowController()
    static func start() {
        let app = Application.shared as! Application
        app.setActivationPolicy(.regular)
        app.activate(ignoringOtherApps: true)
        app.delegate = appDelegate
        app.mainMenu = MainMenu( )
    }
    
    static func showIntro() {
        introWindowController.showWindow(nil)
    }
}

