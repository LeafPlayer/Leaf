//
//  AppDelegate.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/10/27.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private lazy var _wakeUpWithFile = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard _wakeUpWithFile == false else { return }
        Application.showIntro()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        Pref.save()
        for win in NSApp.windows { win.close() }
        MPV.clean()
    }
   
    func applicationDidResignActive(_ notification: Notification) { }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        _wakeUpWithFile = true
        let desktop = "/Users/\(NSUserName())/Desktop"
        var targetFileName = filename
        if filename.hasPrefix(desktop) {
            do {
                let url = URL(fileURLWithPath: filename)
                var target = Preference.appSupportDirUrl.appendingPathComponent("links")
                FileManager.createDirIfNotExist(url: target)
                target = target.appendingPathComponent(url.lastPathComponent)
                if let path = target.absoluteString.replacingOccurrences(of: "file://", with: "").removingPercentEncoding {
                    targetFileName = path
                    if FileManager.default.fileExists(atPath: path) == false {
                        try FileManager.default.createSymbolicLink(at: target, withDestinationURL: url)
                    }
                }
            } catch {
                print(error)
            }
        }
        NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: targetFileName))
        let introVC: NSWindowController? = DI.referrence(for: .intro)
        introVC?.close()
        Pref.isAlwaysOpenInNewWindow = true
        if Pref.isAlwaysOpenInNewWindow == false {
            if let old: PlayerResolver = DI.referrence(for: .activePlayer) {
                old.open(url: targetFileName)
                return true
            }
        }
        guard let resolver: PlayerResolver.Type = DI.class(for: .player) else { return true }
        let player = resolver.init()
        player.showWindow()
        player.open(url: targetFileName)
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let window = sender.windows.last else { return true }
        if flag {
            window.orderFront(nil)
        } else {
            window.makeKeyAndOrderFront(NSApp)
            window.absCenter()
        }
        return true
    }

}

