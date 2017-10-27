//
//  LeafPlayer.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/14.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
import ResourcesManager
import SnapKit

public final class LeafPlayer: NSWindowController, NSWindowDelegate {
    
    private static var _openQueue = DispatchQueue(label: "Player.Open.queue")
    
    private final class Holder {
        var player: LeafPlayer?
        init(player: LeafPlayer) {
            self.player = player
        }
    }
    public var isInFullScreen: Bool = false {
        didSet {
            _mpv?.fullScreen(enabled: isInFullScreen)
        }
    }
    
    /** For legacy full screen */
    public var windowFrameBeforeEnteringFullScreen: NSRect?
    
    public var isVideoLoaded: Bool = false
    
    private lazy var _ffmpegController: FFmpegController = {
        let controller = FFmpegController()
        controller.delegate = self
        return controller
    }()
    
    private var _mpv: MPV?
    private var displayOSD = false
    private var obs: [NSObjectProtocol] = []
    private lazy var queue: DispatchQueue = DispatchQueue(label: "com.selfstudio.leaf.controller")
    private var _holder: Holder?
    private var _releaseOnclose = false
    private var _urlToLoad: String? = nil
    private var _loaded = false
    
    private var _hideUITask: CancellableDelayedTask?
    private var _isInFullScreenAnimation = false
    
    private var _videoViewConstraints: [NSLayoutConstraint.Attribute: NSLayoutConstraint] = [:]
    
    private var titleTextField: NSTextField? { return window?.standardWindowButton(.closeButton)?.superview?.subviews.flatMap({ $0 as? NSTextField }).first
    }
    
    private lazy var titleBgView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0, alpha: 0.5).cgColor
        view.alphaValue = 1
        view.layer?.cornerRadius = 4
        return view
    }()
    
    // MARK: - PIP
    
    @available(macOS 10.12, *)
    private lazy var pip: PIPViewController = {
        let pip = PIPViewController()
        pip.delegate = self
        return pip
    }()
    
    private var pipVideo: NSViewController?
    
    struct Constant {
        static let normalRect = CGRect(x: 0, y: 0, width: 640, height: 480)
        static let mini = CGRect(x: 0, y: 0, width: 400, height: 120)
    }
    
    deinit {
        _mpv?.unobserveProperties()
        _mpv?.destory()
        obs.forEach { ob in NotificationCenter.default.removeObserver(ob) }
        print("LeafPlayer deinit")
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public convenience init() {
        
        self.init(window: LeafPlayerWindow())
        
        window?.styleMask = [.borderless, .miniaturizable, .closable, .resizable, .fullSizeContentView, .unifiedTitleAndToolbar, .titled]
//        self.init(contentRect: rect, styleMask: , backing: .buffered, defer: false)
        
        window?.delegate = self
        window?.contentView?.autoresizesSubviews = false
        window?.contentView?.addSubview(videoView, positioned: .below, relativeTo: nil)
        window?.contentView?.addSubview(titleBgView)
        
        // add constraints
        videoView.snp.makeConstraints { m in
            m.top.left.bottom.right.equalToSuperview()
        }
        _holder = Holder(player: self)
        let mpv = MPV()
        _mpv = mpv
        initMPV(mpv)
        _releaseOnclose = true

        videoView.mpv = mpv
        _mpv?.eventHandler = {[unowned self] event in
            switch event {
            case .videoReconfig: self.videoReconfig()
            case .state: self.playingStateChanged()
            }
        }
    }
    
    public override func showWindow(_ sender: Any?) {
        window?.absCenter()
        window?.fadeIn()
        NSApp.activate(ignoringOtherApps: true)
        super.showWindow(sender)
    }
    
    public func windowWillClose(_ notification: Notification) {
        DI.registerActivePlayer(instance: nil)
        _mpv?.savePlaybackPosition()
        _mpv?.stop()
        if _releaseOnclose {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self._holder?.player = nil
            })
        }
    }
    
    private lazy var videoView: PlayerContentView = {
        return PlayerContentView(frame: Constant.normalRect)
    }()
    
    private func initMPV(_ mpv: MPV) {
        videoView.layer?.display()
        _mpv?.openGLCallback = {[unowned self] in
            self.videoView.videoLayer.mpvGLQueue.async {
                self.videoView.videoLayer.display()
            }
        }
        
        // set path for youtube-dl
        let oldPath = String(cString: getenv("PATH")!)
        var path = Preference.exeDirURL.path + ":" + oldPath
        if Pref.ytdlSearchPath.isEmpty == false {
            path = Pref.ytdlSearchPath + ":" + path
        }
        setenv("PATH", path, 1)
        
////        load keybindings
//        let userConfigs = Pref.inputConfigs
//        let leafDefaultConfPath = Pref.defaultConfigs[.leaf]!
//        var inputConfPath = leafDefaultConfPath
//        let confFromUd = Pref.currentInputConfigName
//        if let currentConfigFilePath = Preference.getFilePath(Configs: userConfigs, forConfig: confFromUd, showAlert: false) {
//            inputConfPath = currentConfigFilePath
//        }
//        let mapping = KeyMapping.parseInputConf(at: inputConfPath) ?? KeyMapping.parseInputConf(at: leafDefaultConfPath)!
//        Pref.keyBindings = [:]
//        mapping.forEach { Pref.keyBindings[$0.key] = $0 }
        
        // set http proxy
        if Pref.httpProxy.isEmpty == false {
            setenv("http_proxy", "http://\(Pref.httpProxy)", 1)
        }
        initializeMPV(mpv)
    }
    
    private func initializeMPV(_ mpv: MPV) {
//        guard let mpv = _mpv else { return }
        let volumeValue = Pref.isEnableInitialVolume ? Pref.initialVolume : Pref.softVolume
        mpv.setOption(value: volumeValue, for: .audio(.volume))
       
        // disable internal OSD
        /*
         0:    OSD completely disabled (subtitles only)
         1:    enabled (shows up only on user interaction)
         2:    enabled + current time visible by default
         3:    enabled + --osd-status-msg (current time and status by default)
         */
        if Pref.isUseMpvOsd == false {
            try? mpv.setStringOption(value: "0", for: .oSD(.osdLevel)).checkError()
        } else {
            displayOSD = false
        }
        
        // log
        if Pref.isEnableLogging == true { mpv.enableLog() }
        
        for key in MPV.Preference.Property.Normal {
            mpv.setOption(for: key)
            let ob = NotificationCenter.default.addObserver(forName: key.notificationName, object: nil, queue: nil, using: {[unowned self] (note) in
                self._mpv?.setOption(for: key)
            })
            obs.append(ob)
        }
        
        mpv.setStringOption(value: Pref.audioSpdifValueForMPV(), for: MPV.Option.audio(.audioSpdif))
        // - Sub
        try? mpv.setStringOption(value: MPV.ExOptValue.no.rawValue, for: MPV.Option.subtitles(.subAuto)).checkError()
        try? mpv.setStringOption(value: Pref.defaultEncoding, for: MPV.Option.subtitles(.subCodepage)).checkError()
        
        try? mpv.setStringExOption(value: Preference.watchLaterURL.path, for: .watchLaterDirectory).checkError()
        // Set user defined conf dir.
        if Pref.isUseUserDefinedConfDir == true {
            let dir = (Pref.userDefinedConfDir as NSString).standardizingPath
            mpv.setStringExOption(value: MPV.ExOptValue.yes.rawValue, for: .config)
            let status = mpv.setStringOption(value: dir, for: MPV.Option.programBehavior(.configDir))
            if status < 0 {
                NotificationCenter.showError(with: I18N.Alert.ExtraOption.ConfigFolder(value1: dir))
            }
        }
        
        // Set user defined options.
        let userOptions = Pref.userOptions
        userOptions.forEach { (op) in
            if op.count == 2 {
                let name = op[0]
                let data = op[1]
                let status = mpv.setStringRaw(value: data, for: name)
                if status < 0 {
                    NotificationCenter.showError(with: I18N.Alert.ExtraOption.Error(value1: name, data, Int(status)))
                }
            }
        }

        // Load external scripts
        // Load keybindings. This is still required for mpv to handle media keys or apple remote.
        let userConfigs = Pref.inputConfigs
        var inputConfPath =  Pref.defaultConfigs[.leaf]!
        let confFromUd = Pref.currentInputConfigName
        if let currentConfigFilePath = Preference.getFilePath(Configs: userConfigs, forConfig: confFromUd, showAlert: false) {
            inputConfPath = currentConfigFilePath
        }
        try? mpv.setStringOption(value: inputConfPath, for: .input(.inputConf)).checkError()
        try? mpv.enabledLog(level: .warn).checkError() // Receive log messages at warn level.
        // Request tick event.
        try? mpv.enabledTickEvent().checkError()
        mpv.enabledWakeUpCallback()
        mpv.enabledObserveProperties()
        mpv.initialize()
    }
    
    public func windowDidResize(_ notification: Notification) {
        updateTitleBackbgound()
    }
    
    public func windowDidBecomeKey(_ notification: Notification) {
        window!.makeFirstResponder(window!)
    }
    
    public func windowDidBecomeMain(_ notification: Notification) {
        DI.registerActivePlayer(instance: self)
    }
    
    public func windowDidResignMain(_ notification: Notification) {
       
    }
}
// MARK: - Mouse event
extension LeafPlayer {
    private func updateAllTrackingAreas() {
        updateTrackingAreas(for: window?.contentView)
    }
    
    private func updateTrackingAreas(for value: NSView?) {
        guard let view = value else { return }
        let areas = view.trackingAreas
        for item in areas { view.removeTrackingArea(item) }
        let area = NSTrackingArea(rect: view.bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        view.addTrackingArea(area)
    }
    
    public override func mouseEntered(with event: NSEvent) {
        _hideUITask?.cancel()
        showUI()
    }
    
    public override func mouseExited(with event: NSEvent) {
        _hideUITask = CancellableDelayedTask(delay: 0.25, task: {[unowned self] in
            self.hideUI()
        })
    }
    
    public override func mouseDown(with event: NSEvent) {
//        print("click")
        
    }
    public override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.toggleFullScreen(nil)
        }
    }
    public override func rightMouseUp(with event: NSEvent) {
        _mpv?.togglePlayPause()
    }
    
    private func showUI() {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.25
            self.window?.standardWindowButton(.closeButton)?.animator().alphaValue = 1
            self.window?.standardWindowButton(.miniaturizeButton)?.animator().alphaValue = 1
            self.window?.standardWindowButton(.fullScreenButton)?.animator().alphaValue = 1
            self.window?.standardWindowButton(.zoomButton)?.animator().alphaValue = 1
            self.window?.standardWindowButton(.documentIconButton)?.animator().alphaValue = 1
            self.titleBgView.animator().alphaValue = 1
            self.titleTextField?.animator().alphaValue = 1
        }) {
            
        }
    }
    
    private func hideUI() {
        guard window?.isFullScreenMode == false else {
            NSCursor.setHiddenUntilMouseMoves(true)
            return
        }
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.25
            self.window?.standardWindowButton(.closeButton)?.animator().alphaValue = 0
            self.window?.standardWindowButton(.miniaturizeButton)?.animator().alphaValue = 0
            self.window?.standardWindowButton(.fullScreenButton)?.animator().alphaValue = 0
            self.window?.standardWindowButton(.zoomButton)?.animator().alphaValue = 0
            self.window?.standardWindowButton(.documentIconButton)?.animator().alphaValue = 0
            self.titleBgView.animator().alphaValue = 0
            self.titleTextField?.animator().alphaValue = 0
        }) {
            
        }
    }
}

// MARK: - windows delegate
//extension LeafPlayer {
//    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
//        print("start")
//
//        if videoView.suspending == false {
//            videoView.suspending = true
//            _mpv?.togglePlayPause(play: false)
//        }
//        return frameSize
//    }
//    public func windowDidEndLiveResize(_ notification: Notification) {
//        if videoView.suspending == true {
//            videoView.suspending = false
//            _mpv?.togglePlayPause(play: true)
//        }
//        print("end")
//    }
//}
/*
extension LeafPlayer {
    public func customWindowsToEnterFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    public func customWindowsToExitFullScreen(for window: NSWindow) -> [NSWindow]? {
        return [window]
    }

    public func window(_ window: NSWindow, startCustomAnimationToEnterFullScreenOn screen: NSScreen, withDuration duration: TimeInterval) {
        windowFrameBeforeEnteringFullScreen = window.frame
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            window.animator().setFrame(screen.frame, display: true)
        }, completionHandler: nil)

    }

    public func window(_ window: NSWindow, startCustomAnimationToExitFullScreenWithDuration duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            window.animator().setFrame(windowFrameBeforeEnteringFullScreen!, display: true)
        }, completionHandler: nil)
    }

    private func resetCollectionBehavior() {
        window?.collectionBehavior = [.managed,  Pref.isUseLegacyFullScreen ? .fullScreenAuxiliary : .fullScreenPrimary]
    }
    
    var standardWindowButtons: [NSButton] {
        return ([.closeButton, .miniaturizeButton, .zoomButton, .documentIconButton] as [NSWindow.ButtonType]).flatMap {
            window?.standardWindowButton($0)
        }
    }
    
    /** This method will not set `isOntop`! */
    private func setWindowFloatingOnTop(_ onTop: Bool) {
        guard let window = window else { return }
        if isInFullScreen { return }
        if onTop {
            window.level = .iinaFloating
        } else {
            window.level = .normal
        }

        resetCollectionBehavior()

        // don't know why they will be disabled
        standardWindowButtons.forEach { $0.isEnabled = true }
    }

    public func windowWillEnterFullScreen(_ notification: Notification) {
//        if isInInteractiveMode {
//            exitInteractiveMode(immediately: true)
//        }

        // Let mpv decide the correct render region in full screen
        _mpv?.setBoolOption(value: true, for: MPV.Option.window(.keepaspect))

        // Set the appearance to match the theme so the titlebar matches the theme
        switch Pref.themeMaterial {
        case .dark, .ultraDark: window?.appearance = NSAppearance(named: .vibrantDark)
        case .light, .mediumLight: window?.appearance = NSAppearance(named: .vibrantLight)
        }

        // show titlebar
//        if oscPosition == .top {
//            oscTopMainViewTopConstraint.constant = OSCTopMainViewMarginTopInFullScreen
//            titleBarHeightConstraint.constant = TitleBarHeightWithOSCInFullScreen
//        } else {
//            // stop animation and hide titleBarView
//            removeTitlebarViewFromFadeableViews()
//            titleBarView.isHidden = true
//        }
//        removeStandardButtonsFromFadeableViews()

        setWindowFloatingOnTop(false)

//        thumbnailPeekView.isHidden = true
//        timePreviewWhenSeek.isHidden = true
//        isMouseInSlider = false

        _isInFullScreenAnimation = true
        isInFullScreen = true

        // Exit PIP if necessary
//        if pipStatus == .inPIP,
//            #available(macOS 10.12, *) {
//            exitPIP()
//        }
        
        videoView.videoLayer.mpvGLQueue.suspend()
    }

    public func windowDidEnterFullScreen(_ notification: Notification) {
        _isInFullScreenAnimation = false

        videoView.videoLayer.mpvGLQueue.resume()
        // we must block the mpv rendering queue to do the following atomically
        videoView.videoLayer.mpvGLQueue.async {
            DispatchQueue.main.sync {
                for (_, constraint) in self._videoViewConstraints {
                    constraint.constant = 0
                }
                self.videoView.needsLayout = true
                self.videoView.layoutSubtreeIfNeeded()
                self.videoView.videoLayer.display()
            }
        }

//        if Preference.bool(for: .blackOutMonitor) {
//            blackOutOtherMonitors()
//        }
    }

    public func windowWillExitFullScreen(_ notification: Notification) {
//        if isInInteractiveMode {
//            exitInteractiveMode(immediately: true)
//        }

        // show titleBarView
//        if oscPosition == .top {
//            oscTopMainViewTopConstraint.constant = OSCTopMainViewMarginTop
//            titleBarHeightConstraint.constant = TitleBarHeightWithOSC
//        } else {
//            addBackTitlebarViewToFadeableViews()
//            titleBarView.isHidden = false
//            animationState = .shown
//        }
//        addBackStandardButtonsToFadeableViews()

//        thumbnailPeekView.isHidden = true
//        timePreviewWhenSeek.isHidden = true
//        isMouseInSlider = false

        isInFullScreen = false
        _isInFullScreenAnimation = true

        videoView.videoLayer.mpvGLQueue.suspend()
    }

    public func windowDidExitFullScreen(_ notification: Notification) {
        videoView.videoLayer.mpvGLQueue.resume()

        videoView.videoLayer.mpvGLQueue.async {
            // reset `keepaspect`
            self._mpv?.setBoolOption(value: true, for: MPV.Option.window(.keepaspect))
            DispatchQueue.main.sync {
                for (_, constraint) in self._videoViewConstraints {
                    constraint.constant = 0
                }
                self.videoView.needsLayout = true
                self.videoView.layoutSubtreeIfNeeded()
                self.videoView.videoLayer.display()
            }
        }

        _isInFullScreenAnimation = false

//        if Preference.bool(for: .blackOutMonitor) {
//            removeBlackWindow()
//        }
        // restore ontop status
//        if !player.info.isPaused {
//            setWindowFloatingOnTop(isOntop)
//        }
    }
}
*/

// MARK: - MPV Event Handler
private extension LeafPlayer {
    
    func playingStateChanged() {
        if let value = state, case DI.PlayerState.error(let message) = value {
            NotificationCenter.showError(with: message)
            if let url = _mpv?.playingInfo?.currentURL {
                if var copy = url.absoluteString.replacingOccurrences(of: "file://", with: "").removingPercentEncoding?.cString(using: .utf8) {
                    let rv = realpath(&copy, nil)
                    guard rv == nil else { return }
                    do { try FileManager.default.trashItem(at: url, resultingItemURL: nil) }
                    catch { }
                }
            }
        }
        guard let menu: MainMenuResolver = DI.referrence(for: .mainMenu) else { return }
        menu.playingStateChanged()
    }
    
    func videoReconfig() {
        guard let info = _mpv?.playingInfo, let w = window, let mpv = _mpv else { return }
        
        let (width, height) = info.videoSizeForDisplay(netRotate: mpv.netRotate)
        // set aspect ratio
        let originalVideoSize = NSSize(width: width, height: height)
        DispatchQueue.main.async {
            w.aspectRatio = originalVideoSize
            if #available(macOS 10.12, *) {
                self.pip.aspectRatio = originalVideoSize
            }
            self.videoView.videoSize = w.convertToBacking(self.videoView.frame).size
            w.contentView?.layoutSubtreeIfNeeded()
            if let title = mpv.title() {
                if mpv.playingInfo?.isNetworkResource == true {
                    self.window?.title = title
                } else {
                    self.window?.representedURL = mpv.playingInfo?.currentURL
                    self.window?.setTitleWithRepresentedFilename(mpv.playingInfo?.currentURL?.path ?? "")
                }
                self.updateTitleBackbgound()
            }
        }
        
        
        
        
        var rect: NSRect
        let needResizeWindow = info.justOpenedFile || Pref.isResizeOnlyWhenManuallyOpenFile == false
        
        var ratio: CGFloat = originalVideoSize.height / originalVideoSize.width
        if needResizeWindow {
            // get videoSize on screen
            var videoSize = originalVideoSize
            if Pref.isUsePhysicalResolution == true {
                videoSize = w.convertFromBacking(
                    NSMakeRect(w.frame.origin.x, w.frame.origin.y, width, height)).size
            }
            // check screen size
            if let screenSize = NSScreen.main?.visibleFrame.size {
                videoSize = videoSize.satisfyMaxSizeWithSameAspectRatio(screenSize)
            }
            // guard min size
            videoSize = videoSize.satisfyMinSizeWithSameAspectRatio(Pref.windowMinimumSize)
            // check if have geometry set
            ratio = videoSize.height / videoSize.width
            if let wfg = window?.windowFrame(from: mpv.geometry, newSize: videoSize) {
                rect = wfg
            } else {
                rect = w.frame.centeredResize(to: videoSize)
            }
        } else {
            // user is navigating in playlist. remain same window width.
            let newHeight = w.frame.width / CGFloat(width) * CGFloat(height)
            let newSize = NSSize(width: w.frame.width, height: newHeight).satisfyMinSizeWithSameAspectRatio(Pref.windowMinimumSize)
            rect = NSRect(origin: w.frame.origin, size: newSize)
        }
        
        // maybe not a good position, consider putting these at playback-restart
        info.justOpenedFile = false
        info.justStartedFile = false
        
        if isInFullScreen {
            windowFrameBeforeEnteringFullScreen = rect
        } else {
            // animated `setFrame` can be inaccurate!
            DispatchQueue.main.async {
                self.videoView.snp.remakeConstraints({ m in
                    m.left.right.equalToSuperview()
                    m.center.equalToSuperview()
                    if let superView = w.contentView {
                        m.height.equalTo(superView.snp.width).multipliedBy(ratio)
                    }
                })
                NSAnimationContext.runAnimationGroup({ (ctx) in
                    ctx.duration = 0.25
                    w.animator().setFrame(rect, display: true)
                }, completionHandler: {
                    w.setFrame(rect, display: true)
                    self.updateAllTrackingAreas()
                    self.updateTitleBackbgound()
                })
                
//                w.setFrame(rect, display: true, animate: true)
                
                
            }
        }
        
        // generate thumbnails after video loaded if it's the first time
        if isVideoLoaded == false {
//            player.generateThumbnails()
            isVideoLoaded = true
        }
        DispatchQueue.main.async {
//           self.hideUI()
//            self._mpv?.togglePlayPause(play: false)
        }
        
        // UI and slider
//        updatePlayTime(withDuration: true, andProgressBar: true)
//        updateVolume()
        
    }
    
    private func updateTitleBackbgound() {
        guard let titleFiled = titleTextField else { return }
        var widthOffset: CGFloat = 2
        let heightOffset: CGFloat = 0.75
        var xOffset: CGFloat = 0
        if _mpv?.playingInfo?.isNetworkResource == false {
            widthOffset += 2
            xOffset = -18
        }
        titleBgView.snp.remakeConstraints { m in
            m.left.equalTo(titleFiled.snp.left).offset(-widthOffset+xOffset)
            m.right.equalTo(titleFiled.snp.right).offset(widthOffset)
            m.top.equalTo(titleFiled.snp.top).offset(-0.5)
            m.bottom.equalTo(titleFiled.snp.bottom).offset(heightOffset*2)
        }
        window?.contentView?.layoutSubtreeIfNeeded()
//        if var rect = titleTextField?.frame, let winFrame = window?.frame {
//            rect.origin.y = winFrame.size.height - rect.origin.y - rect.height
//            rect = rect.insetBy(dx: -4, dy: -1.5).offsetBy(dx: 0, dy: 0.5)
//            if _mpv?.playingInfo?.isNetworkResource == false {
//                rect = rect.insetBy(dx: -8, dy: 0).offsetBy(dx: -9, dy: 0)
//            }
//            titleBgView.frame = rect
//        }
    }
}
// MARK: - PIPViewControllerDelegate
@available(macOS 10.12, *)
extension LeafPlayer: PIPViewControllerDelegate {
    public func pipDidClose(_ pip: PIPViewController) {
        
    }
    
    public func pipActionPlay(_ pip: PIPViewController) {
        
    }
    
    public func pipActionStop(_ pip: PIPViewController) {
        
    }
    public func pipActionPause(_ pip: PIPViewController) {
        
    }
    public func pipShouldClose(_ pip: PIPViewController) -> Bool {
        return true
    }
}

extension LeafPlayer: FFmpegControllerDelegate {
    
    public func didUpdate(_ thumbnails: [FFThumbnail]?, forFile filename: String, withProgress progress: Int) {
        
    }
    
    public func didGenerate(_ thumbnails: [FFThumbnail], forFile filename: String, succeeded: Bool) {
        
    }
    
    private func generateThumbnails() {
        guard var info = _mpv?.playingInfo, let path = info.currentURL?.path else { return }
        info.thumbnails.removeAll(keepingCapacity: true)
        info.thumbnailsProgress = 0
        info.thumbnailsReady = false
        guard Pref.isEnableThumbnailPreview else { return }
        
//        if Preference.bool(for: .enableThumbnailPreview) {
//            if let cacheName = info.mpvMd5, ThumbnailCache.fileExists(forName: cacheName) {
//                thumbnailQueue.async {
//                    if let thumbnails = ThumbnailCache.read(forName: cacheName) {
//                        self.info.thumbnails = thumbnails
//                        self.info.thumbnailsReady = true
//                        self.info.thumbnailsProgress = 1
//                        DispatchQueue.main.async {
//                            self.mainWindow?.touchBarPlaySlider?.needsDisplay = true
//                        }
//                    }
//                }
//            } else {
//                ffmpegController.generateThumbnail(forFile: path)
//            }
//        }
    }
    
}
// MARK: - PlayerResolver
extension LeafPlayer: PlayerResolver {
    public var media: DI.MediaInfo? {
        return _mpv?.playingInfo
    }
    
    public var state: DI.PlayerState? {
        return _mpv?.state
    }
    public func playing() -> Bool {
        guard let playing = _mpv?.playing else { return false }
        return playing
    }
    /// togglePlayPause
    ///
    /// - Returns: playing or not
    public func togglePlayPause() {
        _mpv?.togglePlayPause()
    }
    
    public func showWindow() {
        showWindow(NSApp)
    }
    
    public func open(url: String) {
        DI.registerActivePlayer(instance: self)
        _urlToLoad = url
        DispatchQueue.global(qos: .utility).async {
            do {
                try self._mpv?.loadfile(url: url)
            } catch {
                print("error:\(error)")
            }
        }
    }
    public func changeUI(mode: DI.PlayerMode) {
        
    }
    
    public func removeCurrentFileFromPlayList() {
        _mpv?.stop()
        _mpv?.removeCurrentFileFromPlayList()
        
    }
}


private final class LeafPlayerWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }
    convenience init() {
        let rect = LeafPlayer.Constant.normalRect
        self.init(contentRect: rect, styleMask: [.borderless, .miniaturizable, .closable, .resizable, .fullSizeContentView, .unifiedTitleAndToolbar, .titled], backing: .buffered, defer: false)

        contentView = NSView(frame: rect)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.black.cgColor
        isReleasedWhenClosed = true // key property for reopen window
        collectionBehavior = .fullScreenPrimary
        isMovableByWindowBackground = true
        isOpaque = false
        backgroundColor = .clear
        titlebarAppearsTransparent = true
        titleVisibility = .visible
        minSize = LeafPlayer.Constant.mini.size
        appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        setFrame(rect, display: false)
    }
    
    
    
}

public final class NiblessViewController: NSViewController {
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    convenience init(rect: CGRect) {
        self.init(nibName: nil, bundle: nil)
        view.frame = rect
    }
    override public func loadView() { view = NSView(frame: CGRect.zero) }
}

final class PlayerContentView: NSView {
    
    
    lazy var videoLayer: PlayerContentViewLayer = {
        let layer = PlayerContentViewLayer()
        layer.videoView = self
        return layer
    }()
    
    var suspending = false
    
    var videoSize: NSSize?
    
    var isUninited = false
    
    var unintQueue = DispatchQueue(label: "Player.Uninit")
    private var _ob: NSObjectProtocol?
    
    // MARK: - Attributes
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override var isOpaque: Bool { return true }
    override var isFlipped: Bool { return true }
    weak var mpv: MPV? { didSet { videoLayer.mpv = mpv } }
    // MARK: - Init
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        // set up layer
        wantsLayer = true
        layer = videoLayer
        videoLayer.contentsScale = NSScreen.main!.backingScaleFactor
        
        
        // other settings
        autoresizingMask = [.width, .height]
        wantsBestResolutionOpenGLSurface = true
        
        // dragging init
//        registerForDraggedTypes([.nsFilenames, .nsURL, .string])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    // MARK: Drag and drop
    
//    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
//        return player.acceptFromPasteboard(sender)
//    }
//
//    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
//        return player.openFromPasteboard(sender)
//    }
}


import OpenGL.GL
import OpenGL.GL3

final class PlayerContentViewLayer: CAOpenGLLayer {
    
    fileprivate weak var videoView: PlayerContentView?
    
    lazy var mpvGLQueue: DispatchQueue = DispatchQueue(label: "com.colliderli.iina.mpvgl")
    
    override init() {
        super.init()
        initialize()
    }
    
    override init(layer: Any) {
        let previousLayer = layer as? PlayerContentViewLayer
        videoView = previousLayer?.videoView
        super.init()
        initialize()
    }
    
    private func initialize() {
        isOpaque = true
        isAsynchronous = false
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        contentsGravity = kCAGravityResizeAspect
        masksToBounds = true
        backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    weak var mpv: MPV?
    
    override func copyCGLPixelFormat(forDisplayMask mask: UInt32) -> CGLPixelFormatObj {
        
        let attributes0: [CGLPixelFormatAttribute] = [
            kCGLPFADoubleBuffer,
            kCGLPFAOpenGLProfile, CGLPixelFormatAttribute(kCGLOGLPVersion_3_2_Core.rawValue),
            kCGLPFAAccelerated,
            kCGLPFAAllowOfflineRenderers,
            _CGLPixelFormatAttribute(rawValue: 0)
        ]
        
        let attributes1: [CGLPixelFormatAttribute] = [
            kCGLPFADoubleBuffer,
            kCGLPFAOpenGLProfile, CGLPixelFormatAttribute(kCGLOGLPVersion_3_2_Core.rawValue),
            kCGLPFAAllowOfflineRenderers,
            _CGLPixelFormatAttribute(rawValue: 0)
        ]
        
        let attributes2: [CGLPixelFormatAttribute] = [
            kCGLPFADoubleBuffer,
            kCGLPFAAllowOfflineRenderers,
            _CGLPixelFormatAttribute(rawValue: 0)
        ]
        
        var pix: CGLPixelFormatObj?
        var npix: GLint = 0
        
        CGLChoosePixelFormat(attributes0, &pix, &npix)
        
        if pix == nil {
            CGLChoosePixelFormat(attributes1, &pix, &npix)
        }
        
        if pix == nil {
            CGLChoosePixelFormat(attributes2, &pix, &npix)
        }
        
//        Utility.assert(pix != nil, "Cannot create OpenGL pixel format!")
        
        return pix!
    }
    
    
    override func copyCGLContext(forPixelFormat pf: CGLPixelFormatObj) -> CGLContextObj {
        let ctx = super.copyCGLContext(forPixelFormat: pf)
        
        var i: GLint = 1
        CGLSetParameter(ctx, kCGLCPSwapInterval, &i)
        
        CGLEnable(ctx, kCGLCEMPEngine)
        
        CGLSetCurrentContext(ctx)
        return ctx
    }
    
    // MARK: Draw
    
    override func canDraw(inCGLContext ctx: CGLContextObj, pixelFormat pf: CGLPixelFormatObj, forLayerTime t: CFTimeInterval, displayTime ts: UnsafePointer<CVTimeStamp>?) -> Bool {
        return true
    }
    
    override func draw(inCGLContext ctx: CGLContextObj, pixelFormat pf: CGLPixelFormatObj, forLayerTime t: CFTimeInterval, displayTime ts: UnsafePointer<CVTimeStamp>?) {
        
        videoView?.unintQueue.sync {
            guard videoView?.isUninited == false else { return }
            
            CGLLockContext(ctx)
            CGLSetCurrentContext(ctx)
            
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            
            var i: GLint = 0
            glGetIntegerv(GLenum(GL_DRAW_FRAMEBUFFER_BINDING), &i)
            var dims: [GLint] = [0, 0, 0, 0]
            glGetIntegerv(GLenum(GL_VIEWPORT), &dims);
            
            if mpv?.draw(fbo: i, width: dims[2], heihgt: -dims[3]) == true { ignoreGLError() }
            else {
                glClearColor(0, 0, 0, 1)
                glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            }
            glFlush()
            CGLUnlockContext(ctx)
        }
        mpv?.reportFlip()
    }
    
    func draw() { display() }
    
    override func display() {
        super.display()
        CATransaction.flush()
    }
    
    // MARK: Utils
    
    /** Check OpenGL error (for debug only). */
    func gle() {
        let e = glGetError()
        print(arc4random())
        switch e {
        case GLenum(GL_NO_ERROR): break
        case GLenum(GL_OUT_OF_MEMORY): print("GL_OUT_OF_MEMORY")
        case GLenum(GL_INVALID_ENUM): print("GL_INVALID_ENUM")
        case GLenum(GL_INVALID_VALUE): print("GL_INVALID_VALUE")
        case GLenum(GL_INVALID_OPERATION): print("GL_INVALID_OPERATION")
        case GLenum(GL_INVALID_FRAMEBUFFER_OPERATION): print("GL_INVALID_FRAMEBUFFER_OPERATION")
        case GLenum(GL_STACK_UNDERFLOW): print("GL_STACK_UNDERFLOW")
        case GLenum(GL_STACK_OVERFLOW): print("GL_STACK_OVERFLOW")
        default: break
        }
    }
    
    func ignoreGLError() { glGetError() }
}


