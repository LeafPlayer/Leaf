//
//  Preference.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/14.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
import ResourcesManager
public typealias Preference = MPV.Preference
public let Pref = Preference.shared

extension MPV {
    public final class Preference: Codable {
        
        // MARK: - Vars
        public var arrowButtonAction: ArrowButtonAction = .speed { didSet { postChangedProperty(.arrowButtonAction) } }
        public var doubleClickAction: MouseClickAction = .fullscreen { didSet { postChangedProperty(.doubleClickAction) } }
        public var forceTouchAction: MouseClickAction = .none
        public var hardwareDecoder: HardwareDecoderOption = .auto { didSet { postChangedProperty(.hardwareDecoder) } }
        public var horizontalScrollAction: ScrollAction = .seek
        public var middleClickAction: MouseClickAction = .none
        public var onlineSubSource: OnlineSubtitleSource = .shooter
        public var oscPosition: OSCPosition = .floating { didSet { postChangedProperty(.oscPosition) } }
        public var pinchAction: PinchAction = .windowSize { didSet { postChangedProperty(.pinchAction) } }
        public var postLaunchAction: PostLaunchAction = .welcomWindow
        public var rightClickAction: MouseClickAction = .pause
        public var screenshotFormat: ScreenshotFormat = .png { didSet { postChangedProperty(.screenshotFolder) } }
        public var singleClickAction: MouseClickAction = .hideOSC { didSet { postChangedProperty(.singleClickAction) } }
        public var subAlignX: SubAlign = .center { didSet { postChangedProperty(.subAlignX) } }
        public var subAlignY: SubAlign = .bottom { didSet { postChangedProperty(.subAlignY) } }
        public var subAutoLoadPolicy: SubAutoLoadPolicy = .leaf
        public var subOverrideLevel: SubOverrideLevel = .strip { didSet { postChangedProperty(.subOverrideLevel) } }
        public var themeMaterial: Theme = .dark { didSet { postChangedProperty(.themeMaterial) } }
        public var transportRTSPThrough: RTSPTransportation = .tcp { didSet { postChangedProperty(.transportRTSPThrough) } }
        public var verticalScrollAction: ScrollAction = .volume
        
        public var audioThreads = 0 { didSet { postChangedProperty(.audioThreads) } }
        public var cacheBufferSize = 153600
        public var controlBarPositionHorizontal: Float = 0.5
        public var controlBarPositionVertical: Float = 0.1
        public var controlBarAutoHideTimeout: Float = 2.5
        public var defaultCacheSize = 153600 { didSet { postChangedProperty(.defaultCacheSize) } }
        public var initialVolume = 100
        public var maxThumbnailPreviewCacheSize = 500
        public var maxVolume = 100 { didSet { postChangedProperty(.maxVolume) } }
        public var osdAutoHideTimeout: Float = 1
        public var osdTextSize: Float = 20
        public var playlistWidth = 270
        public var relativeSeekAmount = 3 { didSet { postChangedProperty(.relativeSeekAmount) } }
        public var secPrefech = 100 { didSet { postChangedProperty(.secPrefech) } }
        public var softVolume = 100
        public var subBlur: Float = 0 { didSet { postChangedProperty(.subBlur) } }
        public var subBorderSize: Float = 3 { didSet { postChangedProperty(.subBorderSize) } }
        public var subMarginX: Int = 25 { didSet { postChangedProperty(.subMarginX) } }
        public var subMarginY: Int = 22 { didSet { postChangedProperty(.subMarginY) } }
        public var subPos: Int = 100 { didSet { postChangedProperty(.subPos) } }
        public var subShadowSize: Float = 0 { didSet { postChangedProperty(.subShadowSize) } }
        public var subSpacing: Float = 0
        public var subTextSize: Float = 55
        public var videoThreads = 0 { didSet { postChangedProperty(.videoThreads) } }
        public var volumeScrollAmount = 3
        
        public var isAlwaysFloatOnTop = false { didSet { postChangedProperty(.isAlwaysFloatOnTop) } }
        public var isAlwaysOpenInNewWindow = true
        public var isAutoSwitchToMusicMode = true
        public var isBlackOutMonitor = false { didSet { postChangedProperty(.isBlackOutMonitor) } }
        public var isControlBarStickToCenter = true
        public var isDisplayInLetterBox = true { didSet { postChangedProperty(.isDisplayInLetterBox) } }
        public var isEnableAdvancedSettings = false
        public var isEnableCache = true { didSet { postChangedProperty(.isEnableCache) } }
        public var isEnableCmdN = false
        public var isEnableInitialVolume = false
        public var isEnableLogging = false
        public var isEnableSpdifAC3 = false
        public var isEnableSpdifDTS = false
        public var isEnableSpdifDTSHD = false
        public var isEnableThumbnailPreview = true
        public var isFollowGlobalSeekTypeWhenAdjustSlider = false
        public var isFullScreenWhenOpen = false
        public var isIgnoreAssStyles = false { didSet { postChangedProperty(.isIgnoreAssStyles) } }
        public var isKeepOpenOnFileEnd = true { didSet { postChangedProperty(.isKeepOpenOnFileEnd) } }
        public var isLegacyFullScreenAnimation = false
        public var isPlaylistAutoAdd = true
        public var isPlaylistAutoPlayNext = true { didSet { postChangedProperty(.isPlaylistAutoPlayNext) } }
        public var isPauseWhenOpen = false
        public var isQuitWhenNoOpenedWindow = false
        public var isRecordPlaybackHistory = true
        public var isRecordRecentFiles = true
        public var isResizeOnlyWhenManuallyOpenFile = true
        public var isResumeLastPosition = true { didSet { postChangedProperty(.isResumeLastPosition) } }
        public var isScreenshotIncludeSubtitle = true
        public var isShowChapterPos = false { didSet { postChangedProperty(.isShowChapterPos) } }
        public var isShowRemainingTime = false { didSet { postChangedProperty(.isShowRemainingTime) } }
        public var isSubBold = false { didSet { postChangedProperty(.isSubBold) } }
        public var isSubItalic = false { didSet { postChangedProperty(.isSubItalic) } }
        public var isSubScaleWithWindow = true { didSet { postChangedProperty(.isSubScaleWithWindow) } }
        public var isTrackAllFilesInRecentOpenMenu = true
        public var isUseAppleRemote = false { didSet { postChangedProperty(.isUseAppleRemote) } }
        public var isUseExactSeek: Bool = false { didSet { postChangedProperty(.isUseExactSeek) } }
        public var isUseLegacyFullScreen = false { didSet { postChangedProperty(.isUseLegacyFullScreen) } }
        public var isUseMediaKeys = false { didSet { postChangedProperty(.isUseMediaKeys) } }
        public var isUseMpvOsd = false
        public var isUsePhysicalResolution = true
        public var isUseUserDefinedConfDir = false
        public var isYtdlEnabled = true { didSet { postChangedProperty(.isYtdlEnabled) } }
        
        public var audioLanguage = "" { didSet { postChangedProperty(.audioLanguage) } }
        public var currentInputConfigName: ConfigName = .leaf
        public var defaultEncoding = "auto"
        public var httpProxy = ""
        public var openSubUsername = ""
        public var screenshotFolder = "~/Pictures/Screenshots" { didSet { postChangedProperty(.screenshotFolder) } }
        public var screenshotTemplate = "%F-%n" { didSet { postChangedProperty(.screenshotTemplate) } }
        public var subAutoLoadPriorityString = ""
        public var subAutoLoadSearchPath = "./*"
        public var subLang = "" { didSet { postChangedProperty(.subLang) } }
        public var subTextFont = "sans-serif" { didSet { postChangedProperty(.subTextFont) } }
        public var userAgent = "" { didSet { postChangedProperty(.userAgent) } }
        public var userDefinedConfDir = "~/.config/mpv/"
        public var ytdlRawOptions = "" { didSet { postChangedProperty(.ytdlRawOptions) } }
        public var ytdlSearchPath = ""
        
        public var subBgColor: ColorHex = NSColor.clear.colorHex { didSet { postChangedProperty(.subBgColor) } }
        public var subBorderColor: ColorHex = NSColor.black.colorHex { didSet { postChangedProperty(.subBorderColor) } }
        public var subShadowColor: ColorHex = NSColor.clear.colorHex { didSet { postChangedProperty(.subShadowColor) } }
        public var subTextColor: ColorHex = NSColor.white.colorHex { didSet { postChangedProperty(.subTextColor) } }
        
        public var inputConfigs: [String : Any] = [:]
        public var userOptions: [[String]] = []
        public var watchProperties: [String] = []
        public var keyBindings: [String : Any] = [:]
        
        public var musicModeSize: CGSize = CGSize(width: 300, height: 100)
        /** Minimum window size. */
        public var windowMinimumSize: CGSize = CGSize(width: 500, height: 300)
        
        public private(set) var defaultConfigs: [ConfigName: String] = [
            .leaf: Bundle.main.path(forResource: "iina-default-input", ofType: "conf", inDirectory: "config")!,
            .mpv: Bundle.main.path(forResource: "input", ofType: "conf", inDirectory: "config")!,
            .vlc: Bundle.main.path(forResource: "vlc-default-input", ofType: "conf", inDirectory: "config")!
        ]
        
        // MARK: - Compound value
        public func screenshotFolderValueForMPV() -> String { return (screenshotFolder as NSString).expandingTildeInPath }
        public func screenshotFormatValueForMPV() -> String { return screenshotFormat.rawValue }
        public func keepOpenValueForMPV() -> String { return isPlaylistAutoPlayNext ? (isKeepOpenOnFileEnd ? MPV.ExOptValue.yes : MPV.ExOptValue.no).rawValue : "always" }
        public func hardwareDecoderValueForMPV() -> String { return hardwareDecoder.rawValue }
        public func audioSpdifValueForMPV() -> String {
            var total = ""
            isEnableSpdifAC3 ? (total += "ac3") : ()
            isEnableSpdifDTS ? (total += ",dts") : ()
            isEnableSpdifDTSHD ? (total += ",dts-hd") : ()
            return total
        }
        public func subAssOverrideValueForMPV() -> String { return isIgnoreAssStyles ? subOverrideLevel.rawValue : MPV.ExOptValue.yes.rawValue }
        public func subAlignXValueForMPV() -> String { return subAlignX.xString }
        public func subAlignYValueForMPV() -> String { return subAlignX.rawValue }
        public func isEnableCacheValueForMPV() -> String? { return isEnableCache ? nil : MPV.ExOptValue.no.rawValue }
        public func userAgentValueForMPV() -> String? { return userAgent.isEmpty ? nil : userAgent }
        public func transportRTSPThroughValueForMPV() -> String { return transportRTSPThrough.rawValue }
        
        // MARK: - Static
        public static let shared: Preference = Preference.read()
        
        private static let _storeKey = "MPV.Preference"
        private static let _inputConfigsStoreKey = "\(_storeKey).inputConfigs"
        
        private static func read() -> Preference {
            guard let d = UserDefaults.standard.data(forKey: Preference._storeKey) else { return Preference() }
            let decoder = JSONDecoder()
            do {
                let pre = try decoder.decode(Preference.self, from: d)
                if let inputConfigs = UserDefaults.standard.object(forKey: _inputConfigsStoreKey) as? [String : Any] {
                    pre.inputConfigs = inputConfigs
                }
                return pre
            } catch {
                print("decode Preference error:\(error)")
                UserDefaults.standard.removeObject(forKey: _storeKey)
                UserDefaults.standard.synchronize()
                print("remove currupted data in UserDefaults")
                return Preference()
            }
        }
        
        public static func getFilePath(Configs userConfigs: [String: Any]!, forConfig conf: ConfigName, showAlert: Bool = true) -> String? {
            
            // if is default config
            if let dv = Pref.defaultConfigs[conf] {
                return dv
            } else if let uv = userConfigs[conf.rawValue] as? String {
                return uv
            } else {
                if showAlert {
                    NotificationCenter.showError(with: I18N.Alert.ErrorFindingFile(value1: "config"))
                }
                return nil
            }
        }
        
        // MARK: - Instance
        private init() { }
        
        public func save() {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self)
                UserDefaults.standard.set(Pref.inputConfigs, forKey: Preference._inputConfigsStoreKey)
                UserDefaults.standard.set(data, forKey: Preference._storeKey)
                UserDefaults.standard.synchronize()
                print("Preference saved")
            } catch {
                print("encode Preference error:\(error)")
            }
        }
        
        private func postChangedProperty(_ value: Property) {
            NotificationCenter.default.post(name: value.notificationName, object: nil)
        }
        
        private enum CodingKeys: String, CodingKey {
            case screenshotFolder, screenshotFormat, screenshotTemplate, isUseMediaKeys, isUseAppleRemote, isKeepOpenOnFileEnd, isPlaylistAutoPlayNext, isResumeLastPosition, videoThreads, audioThreads, hardwareDecoder, audioLanguage, maxVolume, isIgnoreAssStyles, subOverrideLevel, subTextFont, subTextSize, subTextColor, subBgColor, isSubBold, isSubItalic, subBlur, subSpacing, subBorderSize, subBorderColor, subShadowSize, subShadowColor, subAlignX, subAlignY, subMarginX, subMarginY, subPos, subLang, isDisplayInLetterBox, isSubScaleWithWindow, isEnableCache, defaultCacheSize, cacheBufferSize, secPrefech, userAgent, transportRTSPThrough, isYtdlEnabled, ytdlRawOptions, themeMaterial, oscPosition, isShowChapterPos, isUseExactSeek, relativeSeekAmount, volumeScrollAmount, horizontalScrollAction, verticalScrollAction, arrowButtonAction, singleClickAction, doubleClickAction, pinchAction, isShowRemainingTime, isBlackOutMonitor, isAlwaysFloatOnTop, isUseLegacyFullScreen, isAlwaysOpenInNewWindow, isEnableCmdN, isRecordPlaybackHistory, isRecordRecentFiles, isTrackAllFilesInRecentOpenMenu, controlBarPositionHorizontal, controlBarPositionVertical, isControlBarStickToCenter, controlBarAutoHideTimeout, playlistWidth, osdAutoHideTimeout, osdTextSize, softVolume, isPauseWhenOpen, isFullScreenWhenOpen, isLegacyFullScreenAnimation, isPlaylistAutoAdd, isUsePhysicalResolution, isResizeOnlyWhenManuallyOpenFile, isEnableThumbnailPreview, maxThumbnailPreviewCacheSize, watchProperties, isAutoSwitchToMusicMode, isEnableSpdifAC3, isEnableSpdifDTS, isEnableSpdifDTSHD, isEnableInitialVolume, initialVolume, subAutoLoadPolicy, subAutoLoadPriorityString, subAutoLoadSearchPath, onlineSubSource, openSubUsername, defaultEncoding, ytdlSearchPath, httpProxy, currentInputConfigName, isEnableAdvancedSettings, isUseMpvOsd, isEnableLogging, userOptions, isUseUserDefinedConfDir, userDefinedConfDir, isQuitWhenNoOpenedWindow, isFollowGlobalSeekTypeWhenAdjustSlider, middleClickAction, forceTouchAction, isScreenshotIncludeSubtitle, postLaunchAction, musicModeSize, windowMinimumSize
        }
        //
    }
}
// MARK: - URLs
extension MPV.Preference {
    public static let exeDirURL: URL = URL(fileURLWithPath: Bundle.main.executablePath!).deletingLastPathComponent()
    
    public static let appSupportDirUrl: URL = {
        let asPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier!
        let appAsUrl = asPath.appendingPathComponent(bundleID)
        FileManager.createDirIfNotExist(url: appAsUrl)
        return appAsUrl
    }()
    
    public static let logDirURL: URL = {
        let url = appSupportDirUrl.appendingPathComponent("log", isDirectory: true)
        FileManager.createDirIfNotExist(url: url)
        return url
    }()
    
    public static let watchLaterURL: URL = {
        let url = appSupportDirUrl.appendingPathComponent("watch_later", isDirectory: true)
        FileManager.createDirIfNotExist(url: url)
        return url
    }()
}
// MARK: - Enums
extension MPV.Preference {
    
    public enum ConfigName: String, Codable { case leaf, mpv, vlc }
    public enum ArrowButtonAction: Int, Codable { case speed, playlist, seek }
    public enum HardwareDecoderOption: String, Codable { case disabled = "no", auto, autoCopy = "auto-copy" }
    public enum MouseClickAction: Int, Codable { case none, fullscreen, pause, hideOSC }
    public enum OnlineSubtitleSource: String, Codable { case shooter = "shooter.cn", openSub = "opensubtitles.org" }
    public enum OSCPosition: Int, Codable { case floating, top, bottom }
    public enum PinchAction: Int, Codable { case windowSize, fullscreen, none }
    public enum PostLaunchAction: Int, Codable { case welcomWindow, openPanel, none }
    public enum RTSPTransportation: String, Codable { case lavf, tcp, udp, http }
    public enum ScreenshotFormat: String, Codable { case png, jpg, jpeg, ppm, pgm, pgmyuv, tga }
    public enum ScrollAction: Int, Codable { case volume, seek, none, passToMpv }
    public enum SeekOption: Int, Codable { case relative, extract, auto }
    public enum SubOverrideLevel: String, Codable { case yes, force, strip }
    public enum Theme: Int, Codable { case dark, ultraDark, light, mediumLight }
    public enum SubAutoLoadPolicy: Int, Codable {
        case disabled, mpvFuzzy, leaf
        func shouldLoadSubsContainingVideoName() -> Bool { return self != .disabled }
        func shouldLoadSubsMatchedByLeaf() -> Bool { return self == .leaf }
    }
    
    public enum Property: String {
        static let UserActionRelative: Set<Property> = [.themeMaterial, .oscPosition, .isShowChapterPos, .isUseExactSeek, .relativeSeekAmount, .volumeScrollAmount, .horizontalScrollAction, .verticalScrollAction, .arrowButtonAction, .singleClickAction, .doubleClickAction, .pinchAction, .isShowRemainingTime, .isBlackOutMonitor, .isAlwaysFloatOnTop, .isUseLegacyFullScreen, .maxVolume]
        static let Normal: Set<Property> = [.screenshotFolder, .screenshotFormat, .screenshotTemplate, .isUseMediaKeys, .isUseAppleRemote, .isKeepOpenOnFileEnd, .isPlaylistAutoPlayNext, .isResumeLastPosition, .videoThreads, .audioThreads, .hardwareDecoder, .audioLanguage, .maxVolume, .isIgnoreAssStyles, .subOverrideLevel, .subTextFont, .subTextSize, .subTextColor, .subBgColor, .isSubBold, .isSubItalic, .subBlur, .subSpacing, .subBorderSize, .subBorderColor, .subShadowSize, .subShadowColor, .subAlignX, .subAlignY, .subMarginX, .subMarginY, .subPos, .subLang, .isDisplayInLetterBox, .isSubScaleWithWindow, .isEnableCache, .defaultCacheSize, .cacheBufferSize, .secPrefech, .userAgent, .transportRTSPThrough, .isYtdlEnabled, .ytdlRawOptions]
        case screenshotFolder, screenshotFormat, screenshotTemplate, isUseMediaKeys, isUseAppleRemote, isKeepOpenOnFileEnd, isPlaylistAutoPlayNext, isResumeLastPosition, videoThreads, audioThreads, hardwareDecoder, audioLanguage, maxVolume, isIgnoreAssStyles, subOverrideLevel, subTextFont, subTextSize, subTextColor, subBgColor, isSubBold, isSubItalic, subBlur, subSpacing, subBorderSize, subBorderColor, subShadowSize, subShadowColor, subAlignX, subAlignY, subMarginX, subMarginY, subPos, subLang, isDisplayInLetterBox, isSubScaleWithWindow, isEnableCache, defaultCacheSize, cacheBufferSize, secPrefech, userAgent, transportRTSPThrough, isYtdlEnabled, ytdlRawOptions, themeMaterial, oscPosition, isShowChapterPos, isUseExactSeek, relativeSeekAmount, volumeScrollAmount, horizontalScrollAction, verticalScrollAction, arrowButtonAction, singleClickAction, doubleClickAction, pinchAction, isShowRemainingTime, isBlackOutMonitor, isAlwaysFloatOnTop, isUseLegacyFullScreen
        public var notificationName: Notification.Name { return Notification.Name(rawValue) }
        
        public func mpvOption() -> [MPV.Option] {
            var opts: [MPV.Option] = []
            switch self {
            case .arrowButtonAction: break
            case .audioLanguage: opts.append(.trackSelection(.alang))
            case .audioThreads: opts.append(.audio(.adLavcThreads))
            case .cacheBufferSize: opts.append(.cache(.cacheBackbuffer))
            case .defaultCacheSize: opts.append(.cache(.cacheDefault))
            case .doubleClickAction: break
            case .hardwareDecoder: opts.append(.video(.hwdec))
            case .horizontalScrollAction: break
            case .isAlwaysFloatOnTop: break
            case .isBlackOutMonitor: break
            case .isDisplayInLetterBox: opts.append(contentsOf: [.subtitles(.subUseMargins), .subtitles(.subAssForceMargins)])
            case .isEnableCache: if Pref.isEnableCacheValueForMPV() != nil { opts.append(.cache(.cache)) }
            case .isIgnoreAssStyles: opts.append(.subtitles(.subAssOverride))
            case .isKeepOpenOnFileEnd: opts.append(.window(.keepOpen))
            case .isPlaylistAutoPlayNext: opts.append(.window(.keepOpen))
            case .isResumeLastPosition: opts.append(.programBehavior(.savePositionOnQuit))
            case .isShowChapterPos: break
            case .isShowRemainingTime: break
            case .isSubBold: opts.append(.subtitles(.subBold))
            case .isSubItalic: opts.append(.subtitles(.subItalic))
            case .isSubScaleWithWindow: opts.append(.subtitles(.subScaleWithWindow))
            case .isUseAppleRemote: opts.append(.input(.inputAppleremote))
            case .isUseLegacyFullScreen: break
            case .isUseMediaKeys: opts.append(.input(.inputMediaKeys))
            case .isYtdlEnabled: opts.append(.programBehavior(.ytdl))
            case .maxVolume: opts.append(.audio(.volumeMax))
            case .oscPosition: break
            case .pinchAction: break
            case .relativeSeekAmount: break
            case .screenshotFolder: opts.append(.screenshot(.screenshotDirectory))
            case .screenshotFormat: opts.append(.screenshot(.screenshotFormat))
            case .screenshotTemplate: opts.append(.screenshot(.screenshotTemplate))
            case .secPrefech: opts.append(.cache(.cacheSecs))
            case .singleClickAction: break
            case .subAlignX: opts.append(.subtitles(.subAlignX))
            case .subAlignY: opts.append(.subtitles(.subAlignY))
            case .subBgColor: opts.append(.subtitles(.subBackColor))
            case .subBlur: opts.append(.subtitles(.subBlur))
            case .subBorderColor: opts.append(.subtitles(.subBorderColor))
            case .subBorderSize: opts.append(.subtitles(.subBorderSize))
            case .subLang: opts.append(.trackSelection(.slang))
            case .subMarginX: opts.append(.subtitles(.subMarginX))
            case .subMarginY: opts.append(.subtitles(.subMarginY))
            case .subOverrideLevel: opts.append(.subtitles(.subAssOverride))
            case .subPos: opts.append(.subtitles(.subPos))
            case .subShadowColor: opts.append(.subtitles(.subShadowColor))
            case .subShadowSize: opts.append(.subtitles(.subShadowOffset))
            case .subSpacing: opts.append(.subtitles(.subSpacing))
            case .subTextColor: opts.append(.subtitles(.subColor))
            case .subTextFont: opts.append(.subtitles(.subFont))
            case .subTextSize: opts.append(.subtitles(.subFontSize))
            case .themeMaterial: break
            case .transportRTSPThrough: opts.append(.network(.rtspTransport))
            case .isUseExactSeek: break
            case .userAgent: opts.append(.network(.userAgent))
            case .verticalScrollAction: break
            case .videoThreads: opts.append(.video(.vdLavcThreads))
            case .volumeScrollAmount: break
            case .ytdlRawOptions: opts.append(.programBehavior(.ytdlRawOptions))
            }
            return opts
        }
        
        public func value() -> PreferenceValueCompatible? {
            let p = Preference.shared
            switch self {
            case .arrowButtonAction: return p.arrowButtonAction.rawValue
            case .audioLanguage: return p.audioLanguage
            case .audioThreads: return p.audioThreads
            case .cacheBufferSize: return p.cacheBufferSize
            case .defaultCacheSize: return p.defaultCacheSize
            case .doubleClickAction: return p.doubleClickAction.rawValue
            case .hardwareDecoder: return p.hardwareDecoderValueForMPV()
            case .horizontalScrollAction: return p.horizontalScrollAction.rawValue
            case .isAlwaysFloatOnTop: return p.isAlwaysFloatOnTop
            case .isBlackOutMonitor: return p.isBlackOutMonitor
            case .isDisplayInLetterBox: return p.isDisplayInLetterBox
            case .isEnableCache: return p.isEnableCacheValueForMPV()
            case .isIgnoreAssStyles: return p.subAssOverrideValueForMPV()
            case .isKeepOpenOnFileEnd: return p.keepOpenValueForMPV()
            case .isPlaylistAutoPlayNext: return p.keepOpenValueForMPV()
            case .isResumeLastPosition: return p.isResumeLastPosition
            case .isShowChapterPos: return p.isShowChapterPos
            case .isShowRemainingTime: return p.isShowRemainingTime
            case .isSubBold: return p.isSubBold
            case .isSubItalic: return p.isSubItalic
            case .isSubScaleWithWindow: return p.isSubScaleWithWindow
            case .isUseAppleRemote: return p.isUseAppleRemote
            case .isUseLegacyFullScreen: return p.isUseLegacyFullScreen
            case .isUseMediaKeys: return p.isUseMediaKeys
            case .isYtdlEnabled: return p.isYtdlEnabled
            case .maxVolume: return p.maxVolume
            case .oscPosition: return p.oscPosition.rawValue
            case .pinchAction: return p.pinchAction.rawValue
            case .relativeSeekAmount: return p.relativeSeekAmount
            case .screenshotFolder: return p.screenshotFolderValueForMPV()
            case .screenshotFormat: return p.screenshotFormatValueForMPV()
            case .screenshotTemplate: return p.screenshotTemplate
            case .secPrefech: return p.secPrefech
            case .singleClickAction: return p.singleClickAction.rawValue
            case .subAlignX: return p.subAlignXValueForMPV()
            case .subAlignY: return p.subAlignYValueForMPV()
            case .subBgColor: return p.subBgColor
            case .subBlur: return p.subBlur
            case .subBorderColor: return p.subBorderColor
            case .subBorderSize: return p.subBorderSize
            case .subLang: return p.subLang
            case .subMarginX: return p.subMarginX
            case .subMarginY: return p.subMarginY
            case .subOverrideLevel: return p.subAssOverrideValueForMPV()
            case .subPos: return p.subPos
            case .subShadowColor: return p.subShadowColor
            case .subShadowSize: return p.subShadowSize
            case .subSpacing: return p.subSpacing
            case .subTextColor: return p.subTextColor
            case .subTextFont: return p.subTextFont
            case .subTextSize: return p.subTextSize
            case .themeMaterial: return p.themeMaterial.rawValue
            case .transportRTSPThrough: return p.transportRTSPThroughValueForMPV()
            case .isUseExactSeek: return p.isUseExactSeek
            case .userAgent: return p.userAgentValueForMPV()
            case .verticalScrollAction: return p.verticalScrollAction.rawValue
            case .videoThreads: return p.videoThreads
            case .volumeScrollAmount: return p.volumeScrollAmount
            case .ytdlRawOptions: return p.ytdlRawOptions
            }
        }
    }
    
    public struct ColorHex: Codable, PreferenceValueCompatible {
        public let r: CGFloat
        public let g: CGFloat
        public let b: CGFloat
        public let a: CGFloat
        public init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        }
        public func color() -> NSColor {
            return NSColor(red: r/255, green: g/255, blue: b/255, alpha: a)
        }
        public func mpvString() -> String { return "\(r)/\(g)/\(b)/\(a)" }
        
        public var colorValue: String? { return mpvString() }
    }
    
    public enum SubAlign: String, Codable {
        case top, center, bottom
        public var xString: String {
            switch self {
            case .top: return "left"
            case .bottom: return "right"
            case .center: return rawValue
            }
        }
    }
    
    
}
