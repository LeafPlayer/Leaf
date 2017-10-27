//
//  MPV.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/15.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Foundation
import libmpv
import OpenGL.GL
import OpenGL.GL3

public final class MPV {
    public static func clean() { OpenGLContextManager.shared.clean() }
    public var playingInfo: DI.MediaInfo? {
        get { return _pQueue.sync { return _playingInfo } }
        set { _pQueue.sync { _playingInfo = newValue }  }
    }
    private var _playingInfo: DI.MediaInfo?
    private var _pQueue = DispatchQueue(label: "MPV.Property.Qeueu")
    private let _handler: OpaquePointer?
    private lazy var _initialized = false
    private lazy var _wakeUpHandler: () -> Void = { }
    private lazy var _hadLog = false
    private lazy var _eventQueue: DispatchQueue = DispatchQueue(label: "MPV.Event.Queue")
    private lazy var _fileLoaded = false
    private var _state: DI.PlayerState = .stopped
    public private(set) var state: DI.PlayerState {
        get { return _pQueue.sync { return _state } }
        set {
            _pQueue.sync { _state = newValue }
            eventHandler(.state)
        }
    }
    public private(set) var playing = false
    
    /**
     This ticket will be increased each time before a new task being submitted to `backgroundQueue`.
     
     Each task holds a copy of ticket value at creation, so that a previous task will perceive and
     quit early if new tasks is awaiting.
     
     **See also**:
     
     `autoLoadFilesInCurrentFolder(ticket:)`
     */
    private var backgroundQueueTicket = 0
    /// A dispatch queue for auto load feature.
    let backgroundQueue: DispatchQueue = DispatchQueue(label: "IINAPlayerCoreTask")
    
    let thumbnailQueue: DispatchQueue = DispatchQueue(label: "IINAPlayerCoreThumbnailTask")
    private var _geometry: Geometry?
    public var geometry: Geometry? {
        guard let value = _geometry else {
            
            let geometry = stringOpt(for: Option.window(.geometry)) ?? ""
            // guard option value
            guard geometry.isEmpty == false else { return nil }
            // match the string, replace empty group by nil
            let captures: [String?] = Regex.geometry.captures(in: geometry).map { $0.isEmpty ? nil : $0 }
            // guard matches
            guard captures.count == 10 else { return nil }
            // return struct
            _geometry = Geometry(x: captures[7],
                               y: captures[9],
                               w: captures[2],
                               h: captures[4],
                               xSign: captures[6],
                               ySign: captures[8])
            return _geometry
        }
        return value
    }
    public lazy var eventHandler: (Event) -> Void = { _ in }
    public var openGLCallback: () -> Void = { }
    public var openGLQueue = DispatchQueue(label: "mpv.opengl")
    public private(set) var openglContext: OpaquePointer? = nil
    
    let observeProperties: [String: mpv_format] = [
        Property.trackList(.count).rawValue: MPV_FORMAT_INT64,
        Property.vf.rawValue: MPV_FORMAT_NONE,
        Property.af.rawValue: MPV_FORMAT_NONE,
        Property.chapter.rawValue: MPV_FORMAT_INT64,
        Option.trackSelection(.vid).rawValue: MPV_FORMAT_INT64,
        Option.trackSelection(.aid).rawValue: MPV_FORMAT_INT64,
        Option.trackSelection(.sid).rawValue: MPV_FORMAT_INT64,
        Option.playbackControl(.pause).rawValue: MPV_FORMAT_FLAG,
        Option.video(.deinterlace).rawValue: MPV_FORMAT_FLAG,
        Option.audio(.mute).rawValue: MPV_FORMAT_FLAG,
        Option.audio(.volume).rawValue: MPV_FORMAT_DOUBLE,
        Option.audio(.audioDelay).rawValue: MPV_FORMAT_DOUBLE,
        Option.playbackControl(.speed).rawValue: MPV_FORMAT_DOUBLE,
        Option.subtitles(.subDelay).rawValue: MPV_FORMAT_DOUBLE,
        Option.subtitles(.subScale).rawValue: MPV_FORMAT_DOUBLE,
        Option.subtitles(.subPos).rawValue: MPV_FORMAT_DOUBLE,
        Option.equalizer(.contrast).rawValue: MPV_FORMAT_INT64,
        Option.equalizer(.brightness).rawValue: MPV_FORMAT_INT64,
        Option.equalizer(.gamma).rawValue: MPV_FORMAT_INT64,
        Option.equalizer(.hue).rawValue: MPV_FORMAT_INT64,
        Option.equalizer(.saturation).rawValue: MPV_FORMAT_INT64,
        Option.window(.fullscreen).rawValue: MPV_FORMAT_FLAG,
        Option.window(.ontop).rawValue: MPV_FORMAT_FLAG,
        Option.window(.windowScale).rawValue: MPV_FORMAT_DOUBLE
    ]
    
    public init() {
        let handler = mpv_create()
        _handler = mpv_create_client(handler, UUID().uuidString)
    }
    
    public func initialize() {
        guard let mpv = _handler else { return }
        do {
            try mpv_initialize(mpv).checkError()
            _initialized = true
            try setStringOption(value: ExOptValue.openglcb.rawValue, for: Option.video(.vo)).checkError()
            try setStringOption(value: ExOptValue.yes.rawValue, for: Option.window(.keepaspect)).checkError()
            try setStringOption(value: ExOptValue.auto.rawValue, for: Option.video(.openglHwdecInterop)).checkError()
        } catch {
            print(error)
        }
        
        guard let cb = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB) else { return }
        let context = OpaquePointer(cb)
        openglContext = context
        let openglCallback: mpv_opengl_cb_get_proc_address_fn = { (ctx, name) -> UnsafeMutableRawPointer? in
            let symbolName: CFString = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII)
            guard let addr = CFBundleGetFunctionPointerForName(CFBundleGetBundleWithIdentifier(CFStringCreateCopy(kCFAllocatorDefault, "com.apple.opengl" as CFString!)), symbolName) else {
                //        Utility.fatal("Cannot get OpenGL function pointer!")
                fatalError("Cannot get OpenGL function pointer!")
            }
            return addr
        }
        mpv_opengl_cb_init_gl(context, nil, openglCallback, nil)
        // Set the callback that notifies you when a new video frame is available, or requires a redraw.
        let callback: mpv_opengl_cb_update_fn = { ctx in
            guard let sself = ctx?.to(object: MPV.self) else { return }
            sself.openGLCallback()
        }
        mpv_opengl_cb_set_update_callback(context, callback, UnsafeMutableRawPointer.from(object: self))
        OpenGLContextManager.shared.add(ctx: openglContext)
    }
    
    public func setOption(for key: Preference.Property) {
        let opts = key.mpvOption()
        guard opts.count != 0, let value = key.value() else { return }
        for opt in opts { setOption(value: value, for: opt) }
    }
    
    public func setOption(value: PreferenceValueCompatible, for key: Option) {
        guard let mpv = _handler else { return }
        let name = key.rawValue
        var result: Int32 = 0
        if let string = value.stringValue {
            result = setStringOption(value: string, for: key)
        } else if let bool = value.boolValue {
            result = setBoolOption(value: bool, for: key)
        } else if let int = value.intValue {
            result = setIntOption(value: int, for: key)
        } else if let double = value.doubleValue {
            result = setDoubleOption(value: double, for: key)
        } else if let color = value.colorValue {
            result = mpv_set_option_string(mpv, name, color)
            // Random error here (perhaps a Swift or mpv one), so set it twice
            // 「没有什么是 set 不了的；如果有，那就 set 两次」
            if result < 0 {
                result = mpv_set_option_string(mpv, name, color)
            }
        }
        if result < 0 {
            print("mpv error[\(result)]:\(String(cString: mpv_error_string(result))) for key:\(key.rawValue), value: \(value)")
        }
    }
    
    public func setProperty(value: PreferenceValueCompatible, for key: Property) {
        guard let mpv = _handler else { return }
        let name = key.rawValue
        var result: Int32 = 0
        if let string = value.stringValue {
            result = mpv_set_property_string(mpv, name, string)
        } else if let bool = value.boolValue {
            var data = bool ? 1 : 0
            result = mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
        } else if let int = value.intValue {
            var value = Int64(int)
            result = mpv_set_property(mpv, name, MPV_FORMAT_INT64, &value)
        } else if var double = value.doubleValue {
            result = mpv_set_property(mpv, name, MPV_FORMAT_DOUBLE, &double)
        }
        if result < 0 {
            print("mpv error[\(result)]:\(String(cString: mpv_error_string(result))) for key:\(key)")
        }
    }
    
    @discardableResult public func setStringRaw(value: String, for key: String) -> Int32 {
        var p = value
        return setOption(value: &p, for: key, format: MPV_FORMAT_STRING)
    }
    
    @discardableResult public func setStringExOption(value: String, for key: ExOptKey) -> Int32 {
        var p = value
        return setOption(value: &p, for: key.rawValue, format: MPV_FORMAT_STRING)
    }
    
    @discardableResult public func setStringOption(value: String, for key: Option) -> Int32 {
        guard let mpv = _handler else { return 0 }
        let name = key.rawValue
        if _initialized {
            return mpv_set_property_string(mpv, name, value)
        } else {
            return mpv_set_option_string(mpv, name, value)
        }
    }
    
    @discardableResult public func setBoolOption(value: Bool, for key: Option) -> Int32 {
        guard let mpv = _handler else { return 0 }
        let name = key.rawValue
        if _initialized {
            var data = value ? 1 : 0
            return mpv_set_property(mpv, name, MPV_FORMAT_FLAG, &data)
        } else {
            return mpv_set_option_string(mpv, name, value.mpvString)
        }
    }
    
    @discardableResult public func setIntOption(value: Int, for key: Option) -> Int32 {
        var data = Int64(value)
        return setOption(value: &data, for: key.rawValue, format: MPV_FORMAT_INT64)
    }
    
    @discardableResult public func setDoubleOption(value: Double, for key: Option) -> Int32 {
        var double = value
        return setOption(value: &double, for: key.rawValue, format: MPV_FORMAT_DOUBLE)
    }
    
    @discardableResult public func setOption(value: UnsafeMutableRawPointer!, for key: String, format: mpv_format) -> Int32{
        guard let mpv = _handler else { return 0 }
        let name = key
        if _initialized {
            return mpv_set_property(mpv, name, format, value)
        } else {
            return mpv_set_option(mpv, name, format, value)
        }
    }
    @discardableResult public func enabledLog(level: LogLevel) -> Int32 {
        guard let mpv = _handler else { return 0 }
        return mpv_request_log_messages(mpv, level.rawValue)
    }
    @discardableResult public func enabledTickEvent() -> Int32 {
        guard let mpv = _handler else { return 0 }
        return mpv_request_event(mpv, MPV_EVENT_TICK, 1)
    }
    public func enabledWakeUpCallback() {
        guard let mpv = _handler else { return }
        let info = UnsafeMutableRawPointer.from(object: self)
        mpv_set_wakeup_callback(mpv, { (ctx) in
            guard let sself = ctx?.to(object: MPV.self) else { return }
            sself.readEvents()
        }, info)
    }
    
    public func enabledObserveProperties() {
        guard let mpv = _handler else { return }
        do {
            for (key, value) in observeProperties {
                var name = key.cString(using: .utf8)!
                let hash = UInt64(abs(key.hashValue))
                try mpv_observe_property(mpv, hash, &name, value).checkError()
            }
        } catch {
            print(error)
        }
        
    }
    
    public func unobserveProperties() {
        guard let mpv = _handler else { return }
        do {
            for (key, _) in observeProperties {
                let hash = UInt64(abs(key.hashValue))
                try mpv_unobserve_property(mpv, hash).checkError()
            }
        } catch {
            print(error)
        }
    }
    
    public func retrieveWaittingEvent() -> UnsafeMutablePointer<mpv_event>? {
        guard let mpv = _handler else { return nil }
        return mpv_wait_event(mpv, 0)
    }
    
    public func destory() {
        guard let mpv = _handler else { return }
        openGLCallback = { }
        OpenGLContextManager.shared.removePlayingWindow()
        mpv_detach_destroy(mpv)
//        mpv_terminate_destroy(mpv) // opengl must be uninit before call this 
    }
    
    public func loadfile(url: String, mode: MPV.Command.LoadFileMode = .replace) throws {
        let info = DI.MediaInfo(url: url)
        playingInfo = info
        state = .loading
        try command(.loadfile(mode, url)).checkError()
        if let title = string(for: .mediaTitle) { info.title = title }
        
//        guard var copy = url.cString(using: .utf8) else { return }
//        var real: UnsafeMutablePointer<Int8>? = nil
//        let rv = realpath(&copy, nil)
//        if let r = rv {
//            let realP = String(cString: r)
//            print(realP)
//        }
        
    }
    
    public func removeCurrentFileFromPlayList() {
        guard let index = int(for: .playlistPos) else { return }
        command(.playlistRemove("\(index)"))
    }
    
    @discardableResult private func command(_ command: Command) -> Int32 {
        guard let mpv = _handler else { return -1 }
        let strArgs = command.commands
        var cargs = strArgs.map { $0.flatMap { UnsafePointer<Int8>(strdup($0)) } }
        let returnValue = mpv_command(mpv, &cargs)
        for ptr in cargs { free(UnsafeMutablePointer(mutating: ptr)) }
        return returnValue
    }
    
    public func initOpenGLCB() -> UnsafeMutableRawPointer? {
        // Get opengl-cb context.
        guard let mpv = _handler else { return nil }
        return mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB)
    }
    
    
    public func togglePlayPause(play: Bool? = nil) {
        var isPaused = playing == false
        if let p = play {
            isPaused = !p
        } else {
            isPaused = !isPaused
        }
        setBoolOption(value: isPaused, for: Option.playbackControl(.pause))
        playing = isPaused == false
        state = playing ? .playing : .paused
    }
    
    public func fullScreen(enabled: Bool) {
        setBoolOption(value: enabled, for: Option.window(.fullscreen))
    }
    
    public func stop() {
        eventHandler = { _ in }
        _eventQueue.suspend()
        state = .stopped
        command(.stop)
    }
    
    public func quit() {
//        if let ctx = openglContext { mpv_opengl_cb_uninit_gl(ctx) }
        command(.quit)
    }
    
    public func enableLog() {
        guard _hadLog == false else { return }
        _hadLog = true
        let token = UUID().uuidString
        var rawTime = time_t()
        time(&rawTime)
        var timeinfo = tm()
        localtime_r(&rawTime, &timeinfo)
        
        var curTime = timeval()
        gettimeofday(&curTime, nil)
        let milliseconds = curTime.tv_usec / 1000
        
        let logFileName = String(format: "%d-%d-%d-%02d-%02d-%03d_%@.log", arguments: [Int(timeinfo.tm_year) + 1900, Int(timeinfo.tm_mon + 1), Int(timeinfo.tm_mday), Int(timeinfo.tm_hour), Int(timeinfo.tm_min), Int(milliseconds), token])
        let path = Preference.logDirURL.appendingPathComponent(logFileName).path
        try? setStringOption(value: path, for: .programBehavior(.logFile)).checkError()
    }
    
    public func savePlaybackPosition() { command(.writeWatchLaterConfig) }
    
    public func title() -> String? {
        return string(for: Property.mediaTitle)
    }
    
    public var netRotate: Int { return videoParamsRotate - videoRotate }
    public var videoParamsRotate: Int {
        return int(for: MPV.Property.videoParams(.rotate)) ?? 0
    }
    
    public var videoRotate: Int {
        return intOpt(for: MPV.Option.video(.videoRotate)) ?? 0
    }
    
    @discardableResult public func draw(fbo: Int32, width: Int32, heihgt: Int32) -> Bool {
        guard let ctx = openglContext else { return false }
        return mpv_opengl_cb_draw(ctx, fbo, width, heihgt) == MPV_ERROR_SUCCESS.rawValue
    }
    
    public func reportFlip() {
        guard let ctx = openglContext else { return }
        mpv_opengl_cb_report_flip(ctx, 0)
    }
    
    public func updatePlayerList() {
        guard let info = playingInfo, let count = int(for: .playlistCount) else { return }
        info.playlist.removeAll()
        for index in 0..<count {
            guard let filename = string(for: .playlist(.nFilename(index))),
                let isCurrent = bool(for: .playlist(.nCurrent(index))),
                let isPlaying = bool(for: .playlist(.nPlaying(index))) else { continue }
            let title = string(for: .playlist(.nTitle(index)))
            let playlistItem = DI.MediaInfo.PlaylistItem(filename: filename, isCurrent: isCurrent, isPlaying: isPlaying, title: title)
            info.playlist.append(playlistItem)
        }
    }
    
    public func updateChapters() {
        guard let info = playingInfo, let count = int(for: .chapterList(.count) ), count > 0 else { return }
        info.chapters.removeAll()
        
        for index in 0..<count {
            guard let title = string(for: .chapterList(.nTitle(index))),
                let startTime = double(for: .chapterList(.nTime(index))) else { continue }
            let chapter = DI.MediaInfo.Chapter(title: title, startTime: startTime, index: index)
            info.chapters.append(chapter)
        }
    }
}
private extension MPV {
    func int(for name: Property) -> Int? {
        return get(property: name.rawValue)
    }
    
    func intOpt(for name: Option) -> Int? {
        return get(property: name.rawValue)
    }
    
    func double(for name: Property) -> Double? {
        return get(property: name.rawValue)
    }
    
    func bool(for name: Property) -> Bool? {
        return get(property: name.rawValue)
    }
    
    func string(for name: Property) -> String?  {
        return get(property: name.rawValue)
    }
    func stringOpt(for name: Option) -> String?  {
        return get(property: name.rawValue)
    }
    
    func get<T>(property: String) -> T? {
        guard let mpv = _handler else { return nil }
        let name = property
        let typeString = "\(type(of: T.self))"
        
        if typeString.contains("String") {
            if let raw = mpv_get_property_string(mpv, name) {
                let value = String(cString: raw) as? T
                mpv_free(raw)
                return value
            }
        } else if typeString.contains("Int") {
            var data = Int64()
            mpv_get_property(mpv, name, MPV_FORMAT_INT64, &data)
            return Int(data) as? T
        } else if typeString.contains("Bool") {
            var data = Int64()
            mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &data)
            let value = data > 0
            return value as? T
        }  else if typeString.contains("Double") {
            var data = Double()
            mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &data)
            return Double(data) as? T
        }
        return nil
    }
    
    func get<T: PreferenceValueCompatible, U: RawRepresentable>(property: U) -> T? where U.RawValue == String {
        return get(property: property.rawValue)
    }
}

extension MPV {
    private func readEvents() {
        _eventQueue.async {
            while true {
                let event = self.retrieveWaittingEvent()
                // Do not deal with mpv-event-none
                if event?.pointee.event_id == MPV_EVENT_NONE { break }
                self.handleEvent(event)
            }
        }
    }
    
    private func handleEvent(_ value: UnsafePointer<mpv_event>?) {
        guard let event = value else { return }
        let eventId = event.pointee.event_id
        enum Event {
            case shutdown
            case log(String)
            case propertyChange
            
        }
        switch eventId {
        case MPV_EVENT_SHUTDOWN:
            print("MPV_EVENT_SHUTDOWN")
            //            let quitByMPV = !player.isMpvTerminated
            //            if quitByMPV {
            //                NSApp.terminate(nil)
            //            } else {
            //                mpv.destory()
            //                _mpv = nil
            //            }
            
        case MPV_EVENT_LOG_MESSAGE:
            let dataOpaquePtr = OpaquePointer(event.pointee.data)
            let msg = UnsafeMutablePointer<mpv_event_log_message>(dataOpaquePtr)?.pointee
            guard let prefix = msg?.prefix, let level = msg?.level, let text = msg?.text else { return }
            let message = String(cString: text)
            if let loglevel = LogLevel(rawValue: String(cString: level)) {
                switch loglevel {
                case .error: state = .error(message)
                default: break
                }
                print("MPV log: [\(String(cString: prefix))] \(loglevel.rawValue): \(message)")
            }
            
            
        case MPV_EVENT_PROPERTY_CHANGE:
            let dataOpaquePtr = OpaquePointer(event.pointee.data)
            guard let property = UnsafePointer<mpv_event_property>(dataOpaquePtr)?.pointee else { return }
            let propertyName = String(cString: property.name)
            handlePropertyChange(propertyName, property)
            
        case MPV_EVENT_AUDIO_RECONFIG: break
            
        case MPV_EVENT_VIDEO_RECONFIG: onVideoReconfig()
            
        case MPV_EVENT_START_FILE: onFileStarted()
            //            player.info.isIdle = false
            //            guard getString(Property.path) != nil else { break }
            //            player.fileStarted()
            //            player.sendOSD(.fileStart(player.info.currentURL?.lastPathComponent ?? "-"))
            
        case MPV_EVENT_FILE_LOADED: onFileLoaded()
            
        case MPV_EVENT_SEEK: break
            //            player.info.isSeeking = true
            //            if needRecordSeekTime {
            //                recordedSeekStartTime = CACurrentMediaTime()
            //            }
            //            player.syncUI(.time)
            //            let osdText = (player.info.videoPosition?.stringRepresentation ?? Constants.String.videoTimePlaceholder) + " / " +
            //                (player.info.videoDuration?.stringRepresentation ?? Constants.String.videoTimePlaceholder)
            //            let percentage = (player.info.videoPosition / player.info.videoDuration) ?? 1
            //            player.sendOSD(.seek(osdText, percentage))
            
        case MPV_EVENT_PLAYBACK_RESTART: break
            //            player.info.isIdle = false
            //            player.info.isSeeking = false
            //            if needRecordSeekTime {
            //                recordedSeekTimeListener?(CACurrentMediaTime() - recordedSeekStartTime)
            //                recordedSeekTimeListener = nil
            //            }
            //            player.playbackRestarted()
            //            player.syncUI(.time)
            
        case MPV_EVENT_END_FILE:
            // if receive end-file when loading file, might be error
            // wait for idle
            //            if player.info.fileLoading {
            //                receivedEndFileWhileLoading = true
            //            } else {
            //                player.info.shouldAutoLoadFiles = false
            //            }
            print("MPV_EVENT_END_FILE")
            break
            
        case MPV_EVENT_IDLE:
            //            if receivedEndFileWhileLoading && player.info.fileLoading {
            //                player.errorOpeningFileAndCloseMainWindow()
            //                player.info.fileLoading = false
            //                player.info.currentURL = nil
            //                player.info.isNetworkResource = false
            //            }
            //            player.info.isIdle = true
            //            if fileLoaded {
            //                fileLoaded = false
            //                player.closeMainWindow()
            //            }
            //            receivedEndFileWhileLoading = false
            break
            
        default:
            // let eventName = String(cString: mpv_event_name(eventId))
            // Utility.log("MPV event (unhandled): \(eventName)")
            break
        }
        
    }
    
    private func onVideoReconfig() {
        // If loading file, video reconfig can return 0 width and height
        guard let info = playingInfo, info.loading == false, var w = int(for: .dwidth), var h = int(for: .dheight) else { return }
        if info.rotation == 90 || info.rotation == 270 { swap(&w, &h) }
        let fw = CGFloat(w)
        let fh = CGFloat(h)
        guard fw != info.displaySize?.width || fh != info.displaySize?.height else { return }
        if fw == 0, fh == 0, bool(for: .coreIdle) == true { return }
        info.displaySize = CGSize(width: fw, height: fh)
        eventHandler(.videoReconfig)
    }
    
    private func onFileLoaded() {
        
        togglePlayPause(play: false)
        if let duration = double(for: .duration) {
            playingInfo?.duration = duration
        }
        if let width = int(for: .width), let height = int(for: .height) {
            playingInfo?.videoSize = CGSize(width: width, height: height)
        }
        if Pref.isPauseWhenOpen == false { togglePlayPause(play: true) }
        
        _fileLoaded = true
        playingInfo?.loading = false
        
        DispatchQueue.main.async {
            self.updatePlayerList()
            self.updateChapters()
            
        }
    }
    
    func onFileStarted() {
        guard var info = playingInfo else { return }

        info.isIdle = false
        guard let path = string(for: Property.path) else { return }
        info.justStartedFile = true
        info.disableOSDForFileLoading = true
        info.resourceType = .unknown
        playing = true
        info.currentURL = path.contains("://") ? URL(string: path) : URL(fileURLWithPath: path)
        // Auto load
        backgroundQueueTicket += 1
        let shouldAutoLoadFiles = info.shouldAutoLoadFiles
        let currentTicket = backgroundQueueTicket
        backgroundQueue.async {
            // add files in same folder
            if shouldAutoLoadFiles {
//                self.autoLoadFilesInCurrentFolder(ticket: currentTicket)
            }
            // auto load matched subtitles
//            if let matchedSubs = self.info.matchedSubs[path] {
//                for sub in matchedSubs {
//                    guard currentTicket == self.backgroundQueueTicket else { return }
//                    self.loadExternalSubFile(sub)
//                }
//                // set sub to the first one
//                guard currentTicket == self.backgroundQueueTicket, self.mpv.mpv != nil else { return }
//                self.setTrack(1, forType: .sub)
//            }
        }
    }
    
    private func handlePropertyChange(_ name: String, _ property: mpv_event_property) {
        
        switch name {
            
        case Property.videoParams(.videoParams).rawValue: break
//            onVideoParamsChange(UnsafePointer<mpv_node_list>(OpaquePointer(property.data)))
            
        case Option.TrackSelection.vid.rawValue: break
//            let data = getInt(Option.TrackSelection.vid)
//            player.info.vid = Int(data)
//            let currTrack = player.info.currentTrack(.video) ?? .noneVideoTrack
//            player.sendOSD(.track(currTrack))
//            DispatchQueue.main.async {
//                self.player.mainWindow.quickSettingView.reloadVideoData()
//            }
            
        case Option.TrackSelection.aid.rawValue: break
//            let data = getInt(Option.TrackSelection.aid)
//            player.info.aid = Int(data)
//            let currTrack = player.info.currentTrack(.audio) ?? .noneAudioTrack
//            player.sendOSD(.track(currTrack))
//            DispatchQueue.main.async {
//                self.player.mainWindow.quickSettingView.reloadAudioData()
//            }
            
        case Option.TrackSelection.sid.rawValue: break
//            let data = getInt(Option.TrackSelection.sid)
//            player.info.sid = Int(data)
//            let currTrack = player.info.currentTrack(.sub) ?? .noneSubTrack
//            player.sendOSD(.track(currTrack))
//            DispatchQueue.main.async {
//                self.player.mainWindow.quickSettingView.reloadSubtitleData()
//            }
            
        case Option.PlaybackControl.pause.rawValue: break
//            if let data = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee {
//                if player.info.isPaused != data {
//                    player.sendOSD(data ? .pause : .resume)
//                    player.info.isPaused = data
//                }
//                if player.mainWindow.isWindowLoaded {
//                    if Preference.bool(for: .alwaysFloatOnTop) {
//                        DispatchQueue.main.async {
//                            self.player.mainWindow.setWindowFloatingOnTop(!data)
//                        }
//                    }
//                }
//            }
//            player.syncUI(.playButton)
            
        case Property.chapter.rawValue: break
//            player.syncUI(.time)
//            player.syncUI(.chapterList)
            
            
        case Option.Video.deinterlace.rawValue: break
//            if let data = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee {
//                // this property will fire a change event at file start
//                if player.info.deinterlace != data {
//                    player.sendOSD(.deinterlace(data))
//                    player.info.deinterlace = data
//                }
//            }
            
        case Option.Audio.mute.rawValue: break
//            player.syncUI(.muteButton)
//            if let data = UnsafePointer<Bool>(OpaquePointer(property.data))?.pointee {
//                player.info.isMuted = data
//                player.sendOSD(data ? OSDMessage.mute : OSDMessage.unMute)
//            }
            
        case Option.Audio.volume.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                player.info.volume = data
//                player.syncUI(.volume)
//                player.sendOSD(.volume(Int(data)))
//            }
            
        case Option.Audio.audioDelay.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                player.info.audioDelay = data
//                player.sendOSD(.audioDelay(data))
//            }
            
        case Option.Subtitles.subDelay.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                player.info.subDelay = data
//                player.sendOSD(.subDelay(data))
//            }
            
        case Option.Subtitles.subScale.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                let displayValue = data >= 1 ? data : -1/data
//                let truncated = round(displayValue * 100) / 100
//                player.sendOSD(.subScale(truncated))
//            }
            
        case Option.Subtitles.subPos.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                player.sendOSD(.subPos(data))
//            }
            
        case Option.PlaybackControl.speed.rawValue: break
//            if let data = UnsafePointer<Double>(OpaquePointer(property.data))?.pointee {
//                player.sendOSD(.speed(data))
//            }
            
        case Option.Equalizer.contrast.rawValue: break
//            if let data = UnsafePointer<Int64>(OpaquePointer(property.data))?.pointee {
//                let intData = Int(data)
//                player.info.contrast = intData
//                player.sendOSD(.contrast(intData))
//            }
            
        case Option.Equalizer.hue.rawValue: break
//            if let data = UnsafePointer<Int64>(OpaquePointer(property.data))?.pointee {
//                let intData = Int(data)
//                player.info.hue = intData
//                player.sendOSD(.hue(intData))
//            }
            
        case Option.Equalizer.brightness.rawValue: break
//            if let data = UnsafePointer<Int64>(OpaquePointer(property.data))?.pointee {
//                let intData = Int(data)
//                player.info.brightness = intData
//                player.sendOSD(.brightness(intData))
//            }
            
        case Option.Equalizer.gamma.rawValue: break
//            if let data = UnsafePointer<Int64>(OpaquePointer(property.data))?.pointee {
//                let intData = Int(data)
//                player.info.gamma = intData
//                player.sendOSD(.gamma(intData))
//            }
            
        case Option.Equalizer.saturation.rawValue: break
//            if let data = UnsafePointer<Int64>(OpaquePointer(property.data))?.pointee {
//                let intData = Int(data)
//                player.info.saturation = intData
//                player.sendOSD(.saturation(intData))
//            }
            
            // following properties may change before file loaded
            
        case Property.playlistCount.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.playlistChanged))
            
        case Property.trackList(.count).rawValue: break
//            player.trackListChanged()
//            NotificationCenter.default.post(Notification(name: Constants.Noti.tracklistChanged))
            
        case Property.vf.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.vfChanged))
            
        case Property.af.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.afChanged))
            
        case Option.Window.fullscreen.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.fsChanged))
            
        case Option.Window.ontop.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.ontopChanged))
            
        case Option.Window.windowScale.rawValue: break
//            NotificationCenter.default.post(Notification(name: Constants.Noti.windowScaleChanged))
            
        default:
            // Utility.log("MPV property changed (unhandled): \(name)")
            break
        }
    }
}


// MARK: - enums
extension MPV {
    public enum Event { case videoReconfig, state }
    public enum ActionError: Error { case error(String) }
    public enum ExOptKey: String {
        case config
        case watchLaterDirectory = "watch-later-directory"
    }
    public enum ExOptValue: String { case yes, no, auto, openglcb = "opengl-cb" }
    public enum LogLevel: String {
        case no         //- disable absolutely all messages
        case fatal      //- critical/aborting errors
        case error      //- simple errors
        case warn       //- possible problems
        case info       //- informational message
        case v          //- noisy informational message
        case debug      //- very noisy technical information
        case trace      //- extremely noisy
    }
    public struct Geometry {
        public var x: String?, y: String?, w: String?, h: String?, xSign: String?, ySign: String?
    }
}


private final class OpenGLContextManager {
    static let shared = OpenGLContextManager()

    private var _playingWindowCount = 0

    private var _contexts: [OpaquePointer?] = []

    func add(ctx: OpaquePointer?) {
        _playingWindowCount += 1
        _contexts.append(ctx)
    }

    func clean() {
        guard _contexts.count > 0 else { return }
        for item in _contexts {
            guard let ctx = item else { continue }
            mpv_opengl_cb_set_update_callback(ctx, nil, nil)
            mpv_opengl_cb_uninit_gl(ctx)
        }
        print("clean opengl context")
        _contexts = []
    }

    func removePlayingWindow() {
        _playingWindowCount -= 1
        if _playingWindowCount == 0 { clean() }
    }
}

