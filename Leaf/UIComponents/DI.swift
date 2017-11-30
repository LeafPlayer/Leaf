//
//  DI.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/8.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//
import Cocoa
import ResourcesManager
public final class DI {
    private static let _shared = DI()
    private lazy var _isInstanceTypeCheck = false
    private lazy var _instanceMap: [ResloveType: WeakBox] = [:]
    private lazy var _classMap: [ResloveType: Any] = [:]
    private init() { }
}

extension DI {
    
    public static func registerActivePlayer(instance: PlayerResolver?) {
        _shared._instanceMap[.activePlayer] = WeakBox(instance)
        guard let menu: MainMenuResolver = referrence(for: .mainMenu) else { return }
        menu.playbackDelegate = instance
    }
    /// register weak referren for instance
    ///
    /// - Parameter instance: AnyLeaf instance
    public static func register(instance: Reslovable) {
        let klz = type(of: instance)
        _shared._instanceMap[klz.resolveType] = WeakBox(instance)
    }
    
    // FIXME: ⚠️Change runtime error to compile time error
    /// retrieve instance for type
    ///
    /// - Parameter type: instance type
    /// - Returns: instance of type
    public static func referrence<T>(for type: ResloveType) -> T? {
        return _shared._instanceMap[type]?.value as? T
    }
    
    /// retrieve class for type
    ///
    /// - Parameter name: class
    public static func register(`class` name: Reslovable.Type) {
        _shared._classMap[name.resolveType] = name
    }
    
    /// retrieve class for type
    ///
    /// - Parameter type: type
    /// - Returns: class of type
    public static func `class`<T>(for type: ResloveType) -> T? {
        return _shared._classMap[type] as? T
    }
}
extension DI {
    
    public enum ResloveType: Int {
        case intro, mainMenu, player, activePlayer
    }
    
    public enum TogglableMenu: Hashable {
        case fileMenu(FileItem)
        case playbackMenu(PlaybackItem)
        case videoMenu(VideoItem)
        case audioMenu(AudioItem)
        case subtitleMenu(SubtitleItem)
        case windowMenu(WindowItem)
        
        // MARK: Hashable
        public var hashValue: Int {
            switch self {
            case .fileMenu(let item): return item.index
            case .playbackMenu(let item): return item.index
            case .videoMenu(let item): return item.index
            case .audioMenu(let item): return item.index
            case .subtitleMenu(let item): return item.index
            case .windowMenu(let item): return item.index
            }
        }
        
        public static func ==(lhs: DI.TogglableMenu, rhs: DI.TogglableMenu) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        // MARK: sub enum
        public enum FileItem: Int {
            static var max = FileItem.saveCurrentPlaylist.index + 1
            case deleteCurrentFile
            case saveCurrentPlaylist
//            case share
            var index: Int { return rawValue }
        }
        
        public enum PlaybackItem: Int {
            static var max = PlaybackItem.selectedChapter.index + 1
            case menu
            case playPause
            case stopAndClearPlayerlist
            case stepForwardFiveSecond
            case stepBackwardFiveSecond
            case jumpToBeginning
            case jumpTo
            case takeAScreenshot
            case abLoop
            case fileLoop
            case showPlaylistPanel
            case playlistLoop
            case playlist
            case selectedPlaylistItem
            case showChaptersPanel
            case chapters
            case selectedChapter
            
            var index: Int { return FileItem.max + rawValue }
        }
       
        public enum VideoItem: Int {
            static var max = VideoItem.deLogo.index + 1
            case showQuickSettingsPanel
            case videoTracks
            case halfSize
            case normalSize
            case doubleSize
            case fitToScreen
            case biggerSize
            case smallerSize
            case enterFullScreen
            case togglePIP
            case floatOnTop
            case musicMode
            case selectedAspectRatio
            case aspectRatio
            case selectedCrop
            case crop
            case selectedRotation
            case rotation
            case selectedFlip
            case flip
            case deinterlace
            case deLogo
            
            var index: Int { return PlaybackItem.max + rawValue }
        }
        
        public enum AudioItem: Int {
            static var max = AudioItem.audioDevice.index + 1
            case showQuickSettingsPanel
            case audioTrack
            case volume
            case volumePlusFivePercent
            case volumeMinusFivePercent
            case mute
            case audioDelayPlusZeroPointFives
            case audioDelayMinusZeroPointFives
            case resetAudioDelay
            case audioDevice
            
            var index: Int { return VideoItem.max + rawValue }
        }
        
        public enum SubtitleItem: Int {
            static var max = SubtitleItem.resetSubtitleDelay.index + 1
            case showQuickSettingsPanel
            case subtitle
            case secondSubtitle
            case loadExternalSubtitle
            case findOnlineSubtitles
            case saveDownloadedSubtitle
            case encoding
            case scaleUp
            case scaleDown
            case resetSubtitleScale
            case subtitleDelay
            case subtitleDelayPlusZeroPointFives
            case subtitleDelayMinusZeroPointFives
            case resetSubtitleDelay
            var index: Int { return AudioItem.max + rawValue }
        }
        
        public enum WindowItem: Int {
            case inspector
            var index: Int { return SubtitleItem.max + rawValue }
        }
    }
    
    
    struct WeakBox {
        weak var value: Reslovable?
        init(_ value: Reslovable?) { self.value = value }
    }
    
    public final class TogglableItemBox {
        deinit {
            #if DEBUG
                print("deinit TogglableItemBox")
            #endif
        }
        weak var menu: NSMenu?
        weak var menuItem: TogglableMenuItem?
        public init(menu: NSMenu? = nil, menuItem: TogglableMenuItem? = nil) {
            self.menu = menu
            self.menuItem = menuItem
        }
    }
    
    public enum PlayerMode { case music, video }
    public enum PlayerState {
        case loading
        case playing
        case buffering
        case paused
        case stopped
        case error(String)
        public var notificationName: Notification.Name {
            var rawValue = ""
            switch self {
            case .error: rawValue = "error"
            case .loading: rawValue = "loading"
            case .buffering: rawValue = "buffering"
            case .paused: rawValue = "paused"
            case .playing: rawValue = "playing"
            case .stopped: rawValue = "stopped"
            }
            return Notification.Name(rawValue: rawValue)
        }
        public var isPaused: Bool {
            switch self {
            case .paused: return true
            default: return false
            }
        }
        public var isPlaying: Bool {
            switch self {
            case .playing, .loading: return true
            default: return false
            }
        }
    }
    
    public final class MediaInfo: CustomStringConvertible {
        public enum ResourceType { case unknown, audio, video }
        public let url: String
        public lazy var loading = true
        public lazy var title: String = ""
        public lazy var duration: Double = 0
        public lazy var playPosition: Double = 0
        public lazy var rotation: Int = 0
        public lazy var justOpenedFile = true
        public lazy var justStartedFile = true
        public lazy var justLaunched = true
        public lazy var disableOSDForFileLoading = false
        public lazy var shouldAutoLoadFiles = false
        public lazy var isIdle = false
        public lazy var resourceType: ResourceType = .unknown
        public lazy var isNetworkResource = false
        public lazy var playingListIndex = 0
        public lazy var playingChapterIndex = 0
        public lazy var isSeeking = false
        
        public lazy var playlist: [PlaylistItem] = []
        public lazy var chapters: [Chapter] = []
        
        public var currentURL: URL? = nil {
            didSet {
                guard let url = currentURL else { return }
                mpvMd5 = url.path.md5
                var curl = url
                curl.deleteLastPathComponent()
                if #available(OSX 10.11, *) {
                    shouldAutoLoadFiles = curl.hasDirectoryPath
                } else {
                    shouldAutoLoadFiles = FileManager.default.fileExists(atPath: curl.path)
                }
                isNetworkResource = shouldAutoLoadFiles == false
            }
        }
        var mpvMd5: String?
        
        public var videoSize: CGSize = .zero
        public var displaySize: CGSize? = .zero
        
        
        public var thumbnailsReady = false
        public var thumbnailsProgress: Double = 0
        public var thumbnails: [FFThumbnail] = []
        
        public func increasePlayPos(to position: Double) {
            if position < playPosition {
                if isSeeking { playPosition = position }
            } else {
                playPosition = position
            }
        }
        
        public func getThumbnail(forSecond sec: Double) -> FFThumbnail? {
            guard !thumbnails.isEmpty else { return nil }
            var tb = thumbnails.last!
            for i in 0..<thumbnails.count {
                if thumbnails[i].realTime >= sec {
                    tb = thumbnails[(i == 0 ? i : i - 1)]
                    break
                }
            }
            return tb
        }
        
        
        public func videoSizeForDisplay(netRotate: Int) -> (CGFloat, CGFloat) {
            var width: CGFloat
            var height: CGFloat
            let musicModeWidth = Pref.musicModeSize.width
            let musicModeHeight = Pref.musicModeSize.height
            
            if let w = displaySize?.width, let h = displaySize?.height {
                // when width and height == 0 there's no video track
                width = w == 0 ? musicModeWidth : w
                height = h == 0 ? musicModeHeight : h
            } else {
                // we cannot get dwidth and dheight, which is unexpected. This block should never be executed
                // but just in case, let's log the error.
                //                Utility.log("videoSizeForDisplay: Cannot get dwidth and dheight")
                width = musicModeWidth
                height = musicModeHeight
            }
            
            // if video has rotation
            //            let netRotate = mpv.getInt(MPVProperty.videoParamsRotate) - mpv.getInt(MPVOption.Video.videoRotate)
            let rotate = netRotate >= 0 ? netRotate : netRotate + 360
            if rotate == 90 || rotate == 270 {
                swap(&width, &height)
            }
            return (width, height)
            
        }
        
        init(url: String) {
            self.url = url
        }
        
        public var description: String {
            let sizeString = displaySize != nil ? "\(displaySize!)" : "nil"
            return """
            url: \(url),
            title: \(title),
            duration: \(duration),
            playPosition: \(playPosition),
            videoSize: \(videoSize),
            displaySize: \(sizeString)
            """
        }
        // MARK: - PlaylistItem
        public final class PlaylistItem: NSObject {
            
            /** Actually this is the path. Use `filename` to conform mpv API's naming. */
            public private(set) var filename: String
            
            /** Title or the real filename */
            public var filenameForDisplay: String {
                return title ?? NSString(string: filename).lastPathComponent
            }
            
            public var isCurrent: Bool
            public var isPlaying: Bool
            
            public var title: String?
            
            public init(filename: String, isCurrent: Bool, isPlaying: Bool, title: String?) {
                self.filename = filename
                self.isCurrent = isCurrent
                self.isPlaying = isPlaying
                self.title = title
            }
        }

        // MARK: - Chapter
        
        public final class Chapter: NSObject {
            
            private var privTitle: String?
            var title: String { return privTitle ?? "\(I18N.MainMenu.Chapter) \(index)" }
            public var time: Double
            public var index: Int
            
            public init(title: String?, startTime: Double, index: Int) {
                if var t = title?.trimmingCharacters(in: .whitespacesAndNewlines), t.hasPrefix("\"") == true, t.hasSuffix("\"") == true {
                    t = String(t[t.index(t.startIndex, offsetBy: 1)..<t.index(t.endIndex, offsetBy: -1)])
                    self.privTitle = t
                } else {
                    self.privTitle = title
                }
                self.time = startTime
                self.index = index
            }
            
        }

    }
}
extension DI {
    public typealias BoxHandler = (TogglableItemBox?) -> Void
    public typealias TogglableMenuItem = NSMenuItem & TogglableMenuItemResolver
}
// MARK: - Protocols
// MARK: Reslovable
public protocol Reslovable: class { static var resolveType: DI.ResloveType { get } }
// MARK: MainMenuResolver
public protocol MainMenuResolver: Reslovable {
    func update(item: DI.TogglableMenu, instance: DI.TogglableItemBox?)
    func update(item: DI.TogglableMenu, handler: DI.BoxHandler)
    weak var playbackDelegate: PlayerResolver? { get set }
    func playingStateChanged()
}
extension MainMenuResolver {
    public static var resolveType: DI.ResloveType { return .mainMenu }
}
// MARK: TogglableMenuItemResolver
public protocol TogglableMenuItemResolver { func toggleTo(enabled: Bool) }

// MARK: PlayerHandler
public protocol PlayerResolver: Reslovable {
    var state: DI.PlayerState? { get }
    var media: DI.MediaInfo? { get }
    init()
    func showWindow()
    // MARK: Playback control
    func open(url: String)
    func changeUI(mode: DI.PlayerMode)
    
    func playing() -> Bool
    func togglePlayPause()
    
    func removeCurrentFileFromPlayList()
    
    func playChapter(at index: Int)
    func playPlaylist(at index: Int)
    var playingChapterIndex: Int? { get }
    var playingListIndex: Int? { get }
    
    func stop()
    func clearPlaylist()
    
    func seekRelative(second: Double, extra: MPV.Command.SeekModeExtra?)
    func seekAbsolute(second: Double)
    func seekPecentage(percent: Double, forceExact: Bool)
}
extension PlayerResolver { public static var resolveType: DI.ResloveType { return .player } }

extension Notification.Name {
    public static var critical: Notification.Name { return Notification.Name(rawValue: "critical") }
    public static var normal: Notification.Name { return Notification.Name(rawValue: "normal") }
}

extension NotificationCenter {
    public static func showError(with message: String) {
        NotificationCenter.default.post(name: NSNotification.Name.critical, object: message)
    }
    
    public static func showTips(with message: String) {
        NotificationCenter.default.post(name: NSNotification.Name.normal, object: message)
    }
}
