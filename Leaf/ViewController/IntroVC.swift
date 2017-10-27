//
//  IntroVC.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/10/27.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa

final class IntroWindowController: NSWindowController, Reslovable {
    static var resolveType: DI.ResloveType = .intro
    
    struct Constant {
        static let introRect = CGRect(x: 0, y: 0, width: 640, height: 400)
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init() {
        let win = IntroWindow()
        self.init(window: win)
        DI.register(instance: self)
    }
    
    override func showWindow(_ sender: Any?) {
        window?.absCenter()
        window?.fadeIn()
        NSApp.activate(ignoringOtherApps: true)
        super.showWindow(sender)
    }
}
//

private final class IntroWindow: NSWindow {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    
    convenience init() {
        let rect = IntroWindowController.Constant.introRect
        self.init(contentRect: rect, styleMask: [.borderless, .miniaturizable, .closable, .fullSizeContentView, .unifiedTitleAndToolbar, .titled], backing: .buffered, defer: false)
        let vc = IntroViewController()
        contentViewController = vc
        isReleasedWhenClosed = false // key property for reopen window
        collectionBehavior = .fullScreenNone
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        minSize = rect.size
        appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        setFrame(rect, display: false)
    }
}

private final class IntroViewController: NSViewController {
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
   
    convenience init() { self.init(nibName: nil, bundle: nil) }
    
    override func loadView() {
        let rect = IntroWindowController.Constant.introRect
        let effect = NSFlipVisualEffectView(frame: rect)
        effect.blendingMode = .behindWindow
        effect.maskImage = NSImage.maskImage(cornerRadius: 6)
        effect.state = .active
        effect.material = .dark
        effect.blendingMode = NSVisualEffectView.BlendingMode.behindWindow
        if #available(OSX 10.11, *) {
            effect.material = .ultraDark
        }
        view = effect
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addIconAndVersion()
        addOpenActionItems()
    }
    
    private func addIconAndVersion() {
        let viewHeight = view.frame.height
        let bgWidth: CGFloat = 180
        let bgView = NSFlipView(frame: CGRect(x: 0, y: 0, width: bgWidth, height: viewHeight))
        bgView.wantsLayer = true
        bgView.layer?.backgroundColor = NSColor(red:0.13, green:0.13, blue:0.13, alpha:1.0).cgColor
        view.addSubview(bgView)
        
        let icon = CALayer()
        let length: CGFloat = 128
        let x = (bgWidth - length) / 2
        icon.frame = CGRect(x: x, y: 32, width: length, height: length)
        icon.contents = NSApp.applicationIconImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        bgView.layer?.addSublayer(icon)
        
        let name = Bundle.main.appName
        let textField = NSTextField.label(for: name, font: NSFont.boldSystemFont(ofSize: 16))
        textField.frame = CGRect(x: x, y: 20 + icon.frame.maxY, width: length, height: 20)
        bgView.addSubview(textField)
        
        let versionBuild = Bundle.main.versionBuild
        let versionText = NSTextField.label(for: versionBuild, font: NSFont.systemFont(ofSize: NSFont.systemFontSize))
        versionText.frame = CGRect(x: x, y: 4 + textField.frame.maxY, width: length, height: 20)
        bgView.addSubview(versionText)
    }
    
    private func addOpenActionItems() {
        
    }
}

private extension NSTextField {
    static func label(for text: String, font: NSFont) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.alignment = .center
        textField.textColor = NSColor.white
        textField.drawsBackground = false
        textField.font = font
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = false
        return textField
    }
}
