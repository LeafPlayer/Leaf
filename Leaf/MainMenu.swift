//
//  MenuBar.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/2.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
import ResourcesManager

final class MainMenu: NSMenu {
    
    weak var playbackDelegate: PlayerResolver? {
        didSet {
            let hasDelegate = playbackDelegate != nil
            for item in toggleItems {
                _itemPool[item]?.menu?.toggleAllItem(enabled: hasDelegate)
                _itemPool[item]?.menuItem?.toggleTo(enabled: hasDelegate)
            }
        }
    }
    
    private lazy var toggleItems: [DI.TogglableMenu] = {
        let items: [DI.TogglableMenu] = [.fileMenu(.deleteCurrentFile), .fileMenu(.saveCurrentPlaylist), .playbackMenu(.playPause), .playbackMenu(.stopAndClearPlayerlist), .playbackMenu(.stepForwardFiveSecond), .playbackMenu(.stepBackwardFiveSecond), .playbackMenu(.jumpToBeginning)]
        return items
    }()
    
    private lazy var appName: String = I18N.MainMenu.Leaf
    
    private lazy var _itemPool: [DI.TogglableMenu : DI.TogglableItemBox] = [:]
    
//    let fontManager = NSFontManager.shared
    override init(title: String) {
        super.init(title: title)
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    convenience init() {
        self.init(title: "")
        I18N.setToSystemDefaultLangauge()
        DI.register(instance: self)
        
        let titles = [I18N.MainMenu.Leaf, I18N.MainMenu.File, I18N.MainMenu.Playback, I18N.MainMenu.Video, I18N.MainMenu.Audio, I18N.MainMenu.Subtitle, I18N.MainMenu.Window, I18N.MainMenu.Help]
        for (i, title) in titles.enumerated() {
            addItem(NSMenuItem())
            let menu = NSMenu(title: title)
            menu.delegate = self
            items[i].submenu = menu
            switch i {
            case 0: setupAppMenu(menu)
            case 1: setupFileMenu(menu)
            case 2: setupPlaybackMenu(menu)
            case 3: setupVideoMenu(menu)
            case 4: setupAudioMenu(menu)
            case 5: setupSubtitleMenu(menu)
            case 6: setupWindowMenu(menu)
            case 7: setupHelpMenu(menu)
            default: break
            }
        }
        
        
    }
    
    private func setupAppMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        menu.addItem(title: I18N.MainMenu.AboutLeaf, action: .about)
        menu.addItem(title: I18N.MainMenu.CheckForUpdates, action: .checkUpdate, target: self)
        menu.addSeparator()
        menu.addItem(title: I18N.MainMenu.Preferences, action: .preferences, target: self, keyEquivalent: Key.comma)
        menu.addSeparator()
        let item = menu.addItem(title: I18N.MainMenu.Services, action: nil)
        let s = NSMenu()
        item.submenu = s
        NSApp.servicesMenu = s
        
        menu.addSeparator()
        menu.addItem(title: I18N.MainMenu.HideLeaf, action: .hide, keyEquivalent: Alphabet.h)
        menu.addItem(title: I18N.MainMenu.HideOthers, action: .hideOthers, keyEquivalent: Alphabet.h).keyEquivalentModifierMask = [.command, .option]
        menu.addItem(title: I18N.MainMenu.ShowAll, action: .unhideAll)
        menu.addSeparator()
        menu.addItem(title: I18N.MainMenu.QuitLeaf, action: .terminate, keyEquivalent: Alphabet.q)
    }
    
    private func setupFileMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        // File
        menu.addItem(title: I18N.MainMenu.OpenInNewWindow, action: .openInNewWindow, target: self, keyEquivalent: Alphabet.o)
        menu.addItem(title: I18N.MainMenu.OpenURLInNewWindow, action: .openURLInNewWindow, target: self, keyEquivalent: Alphabet.o).keyEquivalentModifierMask = [.shift, .command]
        
        let openRecentMenuItem = menu.addItem(title: I18N.MainMenu.OpenRecent, action: nil)
        let openRecentMenu = NSMenu(title: I18N.MainMenu.OpenRecent)
        menu.setSubmenu(openRecentMenu, for: openRecentMenuItem)
        // FIXME: WTF!!!!!! https://github.com/mshibanami/OverlayApp/blob/71ab03600dfef54a283ad2996eed4485024ba803/OverlayApp/AppDelegate.swift#L97
        openRecentMenu.performSelector(inBackground: Selector(("_setMenuName:")), with: "NSRecentDocumentsMenu")
        openRecentMenu.addItem(title: I18N.MainMenu.ClearMenu, action: .clearRecentDocuments)
        
        menu.addSeparator()
        menu.addItem(title: I18N.MainMenu.PlaybackHistory, action: .playbackHistory, target: self, keyEquivalent: Alphabet.h).keyEquivalentModifierMask = [.shift, .command]
        
        menu.addSeparator()
        let deleteItem = TogglableMenuItem(target: self, title: I18N.MainMenu.DeleteCurrentFile, action: .deleteCurrentFile)
        menu.addItem(deleteItem)
        let playlistItem = TogglableMenuItem(target: self, title: I18N.MainMenu.SaveCurrentPlaylist, action: .saveCurrentPlaylist)
        menu.addItem(playlistItem)
        menu.addSeparator()
//        let shareItem = TogglableMenuItem(target: self, title: I18N.MainMenu.Share, action: .share)
//        let button = NSButton()
//        button.title = I18N.MainMenu.Share
//        button.target = self
//        button.action = Selector.showShare
//        button.sendAction(on: NSEvent.EventTypeMask.leftMouseDown)
//        button.frame = CGRect(x: 0, y: 0, width: 120, height: 30)
//        shareItem.view = button
//        menu.addItem(shareItem)
//        menu.addSeparator()
        menu.addItem(title: I18N.MainMenu.Close, action: .performClose, keyEquivalent: Alphabet.w)
        
        _itemPool[.fileMenu(.deleteCurrentFile)] = DI.TogglableItemBox(menuItem: deleteItem)
        _itemPool[.fileMenu(.saveCurrentPlaylist)] = DI.TogglableItemBox(menuItem: playlistItem)
//        _itemPool[.fileMenu(.share)] = DI.TogglableItemBox(menuItem: shareItem)
    }
    
    private func setupPlaybackMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        let playPause = TogglableMenuItem(target: self, title: I18N.MainMenu.Pause, action: .playPause, keyEquivalent: Key.spacebar, keyEquivalentModifierMask: [])
        let stopAndClearPlaylist = TogglableMenuItem(target: self, title: I18N.MainMenu.StopAndClearPlaylists, action: .stopAndClearPlaylist, keyEquivalent: Key.dot)
        let stepForwardFives = TogglableMenuItem(target: self, title: I18N.MainMenu.StepForwardFives, action: .stepForwardFives, keyEquivalent: Key.right)
        let stepBackwardFives = TogglableMenuItem(target: self, title: I18N.MainMenu.StepBackwardFives, action: .stepBackwardFives, keyEquivalent: Key.left)
        let jumpToBeginning = TogglableMenuItem(target: self, title: I18N.MainMenu.JumpToBeginning, action: .jumpToBeginning)
        let jumpTo = TogglableMenuItem(target: self, title: I18N.MainMenu.JumpTo, action: .jumpTo, keyEquivalent: Alphabet.j)
        let takeAScreenshot = TogglableMenuItem(target: self, title: I18N.MainMenu.TakeAScreenshot, action: .takeAScreenshot, keyEquivalent: Alphabet.s, keyEquivalentModifierMask: [.command, .shift])
        let goToScreenshotFolder = TogglableMenuItem(target: self, title: I18N.MainMenu.GoToScreenshotFolder, action: .goToScreenshotFolder, enabled: true)
        let abLoop = TogglableMenuItem(target: self, title: I18N.MainMenu.ABLoop, action: .abLoop, keyEquivalent: Alphabet.l)
        let fileLoop = TogglableMenuItem(target: self, title: I18N.MainMenu.FileLoop, action: .fileLoop, keyEquivalent: Alphabet.l, keyEquivalentModifierMask: [.command, .shift])
        let showPlaylistPanel = TogglableMenuItem(target: self, title: I18N.MainMenu.ShowPlaylistPanel, action: .showPlaylistPanel, keyEquivalent: Alphabet.p)
        let playlistLoop = TogglableMenuItem(target: self, title: I18N.MainMenu.PlaylistLoop, action: .playlistLoop)
        let playlist = TogglableMenuItem(target: self, title: I18N.MainMenu.Playlist, action: .playlist)
        let playlistMenu = NSMenu(title: I18N.MainMenu.Playlist)
        menu.setSubmenu(playlistMenu, for: playlist)
        playlistMenu.defaultNoneItem()
        playlistMenu.delegate = self
        
        let showChaptersPanel = TogglableMenuItem(target: self, title: I18N.MainMenu.ShowChaptersPanel, action: .showChaptersPanel, keyEquivalent: Alphabet.c)
        let chapter = TogglableMenuItem(target: self, title: I18N.MainMenu.Chapter, action: .chapters)
        let chaptersMenu = NSMenu(title: I18N.MainMenu.Chapter)
        menu.setSubmenu(chaptersMenu, for: chapter)
        chaptersMenu.defaultNoneItem()
        chaptersMenu.delegate = self
        
        let toAdd: [NSMenuItem] = [playPause, stopAndClearPlaylist, .separator(), stepForwardFives, stepBackwardFives, jumpToBeginning, jumpTo, .separator(), takeAScreenshot, goToScreenshotFolder, .separator(), abLoop, fileLoop, .separator(), showPlaylistPanel, playlistLoop, playlist, .separator(), showChaptersPanel, chapter]
        for item in toAdd { menu.addItem(item) }
        
        _itemPool[.playbackMenu(.menu)] = DI.TogglableItemBox(menu: menu)
        _itemPool[.playbackMenu(.playPause)] = DI.TogglableItemBox(menuItem: playPause)
        _itemPool[.playbackMenu(.stopAndClearPlayerlist)] = DI.TogglableItemBox(menuItem: stopAndClearPlaylist)
        
        _itemPool[.playbackMenu(.stepForwardFiveSecond)] = DI.TogglableItemBox(menuItem: stepForwardFives)
        _itemPool[.playbackMenu(.stepBackwardFiveSecond)] = DI.TogglableItemBox(menuItem: stepBackwardFives)
        _itemPool[.playbackMenu(.jumpToBeginning)] = DI.TogglableItemBox(menuItem: jumpToBeginning)
        _itemPool[.playbackMenu(.jumpTo)] = DI.TogglableItemBox(menuItem: jumpTo)
        
        _itemPool[.playbackMenu(.takeAScreenshot)] = DI.TogglableItemBox(menuItem: takeAScreenshot)
        
        _itemPool[.playbackMenu(.abLoop)] = DI.TogglableItemBox(menuItem: abLoop)
        _itemPool[.playbackMenu(.fileLoop)] = DI.TogglableItemBox(menuItem: fileLoop)
        
        _itemPool[.playbackMenu(.showPlaylistPanel)] = DI.TogglableItemBox(menuItem: showPlaylistPanel)
        _itemPool[.playbackMenu(.playlistLoop)] = DI.TogglableItemBox(menuItem: playlistLoop)
        _itemPool[.playbackMenu(.playlist)] = DI.TogglableItemBox(menu: playlistMenu)
        
        _itemPool[.playbackMenu(.showChaptersPanel)] = DI.TogglableItemBox(menuItem: showChaptersPanel)
        _itemPool[.playbackMenu(.chapters)] = DI.TogglableItemBox(menu: chaptersMenu)
    }
    
    private func setupVideoMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        let showVideoQuickSettingsPanel = TogglableMenuItem(target: self, title: I18N.MainMenu.ShowQuickSettingsPanel, action: .showVideoQuickSettingsPanel, keyEquivalent: Alphabet.v, enabled: false)
        let videoTrack = TogglableMenuItem(target: nil, title: I18N.MainMenu.VideoTrack, action: nil)
        let videoTrackMenu = NSMenu(title: I18N.MainMenu.VideoTrack)
        menu.setSubmenu(videoTrackMenu, for: videoTrack)
        videoTrackMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        videoTrackMenu.delegate = self
        
        let halfSize = TogglableMenuItem(target: self, title: I18N.MainMenu.HalfSize, action: .halfSize, keyEquivalent: Numberic.zero, enabled: false)
        let normalSize = TogglableMenuItem(target: self, title: I18N.MainMenu.NormalSize, action: .normalSize, keyEquivalent: Numberic.one, enabled: false)
        let doubleSize = TogglableMenuItem(target: self, title: I18N.MainMenu.DoubleSize, action: .doubleSize, keyEquivalent: Numberic.two, enabled: false)
        let fitToScreen = TogglableMenuItem(target: self, title: I18N.MainMenu.FitToScreen, action: .fitToScreen, keyEquivalent: Numberic.three, enabled: false)
        
        let bigger = TogglableMenuItem(target: self, title: I18N.MainMenu.BiggerSize, action: .biggerSize, keyEquivalent: Key.equal, enabled: false)
        let smaller = TogglableMenuItem(target: self, title: I18N.MainMenu.SmallerSize, action: .smallerSize, keyEquivalent: Key.minus, enabled: false)
        
        let enterFullScreen = TogglableMenuItem(target: self, title: I18N.MainMenu.EnterFullScreen, action: .enterFullScreen, keyEquivalent: Alphabet.f, enabled: false, keyEquivalentModifierMask: [.command, .control])
        let togglePIP = TogglableMenuItem(target: self, title: I18N.Menu.Pip, action: .togglePIP, keyEquivalent: Alphabet.p, enabled: false, keyEquivalentModifierMask: [.command, .control])
        let floatOnTop = TogglableMenuItem(target: self, title: I18N.MainMenu.FloatOnTop, action: .floatOnTop, keyEquivalent: Alphabet.t, enabled: false, keyEquivalentModifierMask: [.command, .control])
        
        let musicMode = TogglableMenuItem(target: self, title: I18N.MainMenu.MusicMode, action: .musicMode, keyEquivalent: Alphabet.m, enabled: false, keyEquivalentModifierMask: [.command, .option])
        
        let aspectRatio = TogglableMenuItem(target: self, title: I18N.MainMenu.AspectRatio, action: nil)
        let aspectRatioMenu = NSMenu(title: I18N.MainMenu.AspectRatio)
        menu.setSubmenu(aspectRatioMenu, for: aspectRatio)
        let items: [String] = [I18N.Inspector.Default, I18N.QuickSetting.FourThree, I18N.QuickSetting.FiveFour, I18N.QuickSetting.SixteenNine, I18N.QuickSetting.SixteenTen, I18N.QuickSetting.OneOne, I18N.QuickSetting.ThreeTwo, I18N.QuickSetting.TwoPointTweetyOneOne, I18N.QuickSetting.TwoPointThirtyFiveOne, I18N.QuickSetting.TwoPointThirtyNineOne]
        for (i, title) in items.enumerated() {
            let item = TogglableMenuItem(target: self, title: title, action: .aspectRatioChange)
            item.tag = i
            if title == I18N.Inspector.Default {
                item.state = .on
                _itemPool[.videoMenu(.selectedAspectRatio)] = DI.TogglableItemBox(menuItem: item)
            }
            aspectRatioMenu.addItem(item)
        }
        
        let crop = TogglableMenuItem(target: self, title: I18N.MainMenu.Crop, action: nil)
        let cropMenu = NSMenu(title: I18N.MainMenu.Crop)
        menu.setSubmenu(cropMenu, for: crop)
        let cropItems: [String] = [I18N.Pref.None, I18N.QuickSetting.FourThree, I18N.QuickSetting.FiveFour, I18N.QuickSetting.SixteenNine, I18N.QuickSetting.SixteenTen, I18N.QuickSetting.OneOne, I18N.QuickSetting.ThreeTwo, I18N.QuickSetting.TwoPointTweetyOneOne, I18N.QuickSetting.TwoPointThirtyFiveOne, I18N.QuickSetting.TwoPointThirtyNineOne]
        for (i, title) in cropItems.enumerated() {
            let item = TogglableMenuItem(target: self, title: title, action: .crop)
            item.tag = i
            if title == I18N.Pref.None {
                item.state = .on
                _itemPool[.videoMenu(.selectedCrop)] = DI.TogglableItemBox(menuItem: item)
            }
            cropMenu.addItem(item)
        }
        
        let rotation = TogglableMenuItem(target: self, title: I18N.MainMenu.Rotation, action: nil)
        let rotationMenu = NSMenu(title: I18N.MainMenu.Rotation)
        menu.setSubmenu(rotationMenu, for: rotation)
        let rotationItems: [String] = [I18N.QuickSetting.ZeroDegree, I18N.QuickSetting.NightZeroDegree, I18N.QuickSetting.OneEightZeroDegree, I18N.QuickSetting.TwoSevenZeroDegree]
        for (i, title) in rotationItems.enumerated() {
            let item = TogglableMenuItem(target: self, title: title, action: .rotation)
            item.tag = i
            if title == I18N.QuickSetting.ZeroDegree {
                item.state = .on
                _itemPool[.videoMenu(.selectedRotation)] = DI.TogglableItemBox(menuItem: item)
            }
            rotationMenu.addItem(item)
        }
        
        let flip = TogglableMenuItem(target: self, title: I18N.MainMenu.Flip, action: nil)
        let flipMenu = NSMenu(title: I18N.MainMenu.Flip)
        menu.setSubmenu(flipMenu, for: flip)
        let flipItems = [I18N.MainMenu.HorizontalMirror, I18N.MainMenu.VerticalFlip]
        for (i, title) in flipItems.enumerated() {
            let item = TogglableMenuItem(target: self, title: title, action: .flip)
            item.tag = i
            flipMenu.addItem(item)
        }
        
        let deinterlace = TogglableMenuItem(target: self, title: I18N.MainMenu.Deinterlace, action: .deinterlace)
        let deLogo = TogglableMenuItem(target: self, title: I18N.MainMenu.DeLogo, action: .deLogo)
        
        let videoFilters = TogglableMenuItem(target: self, title: I18N.MainMenu.VideoFilters, action: .showVideoFilters, enabled: true)
        
        let toAdd: [NSMenuItem] = [showVideoQuickSettingsPanel, .separator(), videoTrack, .separator(), halfSize, normalSize, doubleSize, fitToScreen, .separator(), bigger, smaller, .separator(), enterFullScreen, togglePIP, floatOnTop, .separator(), musicMode, .separator(), aspectRatio, crop, rotation, flip, deinterlace, deLogo, .separator(), videoFilters]
        for item in toAdd { menu.addItem(item) }
        
        _itemPool[.videoMenu(.showQuickSettingsPanel)] = DI.TogglableItemBox(menuItem: showVideoQuickSettingsPanel)
        _itemPool[.videoMenu(.videoTracks)] = DI.TogglableItemBox(menu: videoTrackMenu)
        
        _itemPool[.videoMenu(.halfSize)] = DI.TogglableItemBox(menuItem: halfSize)
        _itemPool[.videoMenu(.normalSize)] = DI.TogglableItemBox(menuItem: normalSize)
        _itemPool[.videoMenu(.doubleSize)] = DI.TogglableItemBox(menuItem: doubleSize)
        _itemPool[.videoMenu(.fitToScreen)] = DI.TogglableItemBox(menuItem: fitToScreen)
        
        _itemPool[.videoMenu(.biggerSize)] = DI.TogglableItemBox(menuItem: bigger)
        _itemPool[.videoMenu(.smallerSize)] = DI.TogglableItemBox(menuItem: smaller)
        
        _itemPool[.videoMenu(.enterFullScreen)] = DI.TogglableItemBox(menuItem: enterFullScreen)
        _itemPool[.videoMenu(.togglePIP)] = DI.TogglableItemBox(menuItem: togglePIP)
        _itemPool[.videoMenu(.floatOnTop)] = DI.TogglableItemBox(menuItem: floatOnTop)
        
        _itemPool[.videoMenu(.musicMode)] = DI.TogglableItemBox(menuItem: musicMode)
        
        _itemPool[.videoMenu(.aspectRatio)] = DI.TogglableItemBox(menu: aspectRatioMenu)
        _itemPool[.videoMenu(.crop)] = DI.TogglableItemBox(menu: cropMenu)
        _itemPool[.videoMenu(.rotation)] = DI.TogglableItemBox(menu: rotationMenu)
        _itemPool[.videoMenu(.flip)] = DI.TogglableItemBox(menu: rotationMenu)
        
        _itemPool[.videoMenu(.deinterlace)] = DI.TogglableItemBox(menuItem: deinterlace)
        _itemPool[.videoMenu(.deLogo)] = DI.TogglableItemBox(menuItem: deLogo)
    }
    
    private func setupAudioMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        let showAudioQuickSettingsPanel = TogglableMenuItem(target: self, title: I18N.MainMenu.ShowQuickSettingsPanel, action: .showAudioQuickSettingsPanel, keyEquivalent: Alphabet.a)
        let audioTrack = TogglableMenuItem(target: nil, title: I18N.MainMenu.AudioTrack, action: nil)
        let audioTrackMenu = NSMenu(title: I18N.MainMenu.AudioTrack)
        menu.setSubmenu(audioTrackMenu, for: audioTrack)
        audioTrackMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        audioTrackMenu.delegate = self
        
        let title = "\(I18N.MainMenu.Volume)100"
        let volume = TogglableMenuItem(title: title, action: nil, keyEquivalent: "")
        let volumePlusFivePercent = TogglableMenuItem(target: self, title: I18N.MainMenu.VolumePlusFivePercent, action: .volumePlusFivePercent, keyEquivalent: Key.up)
        let volumeMinusFivePercent = TogglableMenuItem(target: self, title: I18N.MainMenu.VolumeMinusFivePercent, action: .volumeMinusFivePercent, keyEquivalent: Key.down)
        let mute = TogglableMenuItem(target: self, title: I18N.MainMenu.Mute, action: .mute)
        
        let delayTitle = "\(I18N.MainMenu.AudioDelay)0.00s"
        let delay = TogglableMenuItem(title: delayTitle, action: nil, keyEquivalent: "")
        let audioDelayPlusZeroPointFives = TogglableMenuItem(target: self, title: I18N.MainMenu.AudioDelayPlusZeroPointFives, action: .audioDelayPlusZeroPointFives, keyEquivalent: Key.up)
        let audioDelayMinusZeroPointFives = TogglableMenuItem(target: self, title: I18N.MainMenu.AudioDelayMinusZeroPointFives, action: .audioDelayMinusZeroPointFives, keyEquivalent: Key.down)
        let resetAudioDelay = TogglableMenuItem(target: self, title: I18N.MainMenu.ResetAudioDelay, action: .resetAudioDelay)
        
        let audioHardware = TogglableMenuItem(target: nil, title: I18N.MainMenu.AudioDevice, action: nil)
        let audioHardwareMenu = NSMenu(title: I18N.MainMenu.AudioDevice)
        menu.setSubmenu(audioHardwareMenu, for: audioHardware)
        audioHardwareMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        audioHardwareMenu.delegate = self
        
        let audioFilters = TogglableMenuItem(target: self, title: I18N.MainMenu.AudioFilters, action: .showAudioFilters, enabled: true)
        
        let toAdd: [NSMenuItem] = [showAudioQuickSettingsPanel, .separator(), audioTrack, .separator(), volume, volumePlusFivePercent, volumeMinusFivePercent, mute, .separator(), delay, audioDelayPlusZeroPointFives, audioDelayMinusZeroPointFives, resetAudioDelay, .separator(), audioHardware, .separator(), audioFilters]
        for item in toAdd { menu.addItem(item) }
        
        
        _itemPool[.audioMenu(.showQuickSettingsPanel)] = DI.TogglableItemBox(menuItem: showAudioQuickSettingsPanel)
        _itemPool[.audioMenu(.audioTrack)] = DI.TogglableItemBox(menu: audioTrackMenu)
        _itemPool[.audioMenu(.volume)] = DI.TogglableItemBox(menuItem: volume)
        _itemPool[.audioMenu(.volumePlusFivePercent)] = DI.TogglableItemBox(menuItem: volumePlusFivePercent)
        _itemPool[.audioMenu(.volumeMinusFivePercent)] = DI.TogglableItemBox(menuItem: volumeMinusFivePercent)
        _itemPool[.audioMenu(.mute)] = DI.TogglableItemBox(menuItem: mute)
        _itemPool[.audioMenu(.audioDelayPlusZeroPointFives)] = DI.TogglableItemBox(menuItem: audioDelayPlusZeroPointFives)
        _itemPool[.audioMenu(.audioDelayMinusZeroPointFives)] = DI.TogglableItemBox(menuItem: audioDelayMinusZeroPointFives)
        _itemPool[.audioMenu(.resetAudioDelay)] = DI.TogglableItemBox(menuItem: resetAudioDelay)
        _itemPool[.audioMenu(.audioDevice)] = DI.TogglableItemBox(menu: audioHardwareMenu)
    }
    
    private func setupSubtitleMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        let showSubtitleQuickSettingsPanel = TogglableMenuItem(target: self, title: I18N.MainMenu.ShowQuickSettingsPanel, action: .showSubtitleQuickSettingsPanel, keyEquivalent: Alphabet.s)
        
        let subtitleItem = TogglableMenuItem(target: nil, title: I18N.MainMenu.Subtitle, action: nil)
        let subtitleItemMenu = NSMenu(title: I18N.MainMenu.Subtitle)
        menu.setSubmenu(subtitleItemMenu, for: subtitleItem)
        subtitleItemMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        subtitleItemMenu.delegate = self
        
        let secondSubtitleItem = TogglableMenuItem(target: nil, title: I18N.MainMenu.SecondSubtitle, action: nil)
        let secondSubtitleItemMenu = NSMenu(title: I18N.MainMenu.SecondSubtitle)
        menu.setSubmenu(secondSubtitleItemMenu, for: secondSubtitleItem)
        secondSubtitleItemMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        secondSubtitleItemMenu.delegate = self
        
        let loadExternalSubtitle = TogglableMenuItem(target: self, title: I18N.MainMenu.LoadExternalSubtitle, action: .loadExternalSubtitle)
        
        let findOnlineSubtitles = TogglableMenuItem(target: self, title: I18N.MainMenu.FindOnlineSubtitles, action: .findOnlineSubtitles)
        let saveDownloadedSubtitle = TogglableMenuItem(target: self, title: I18N.MainMenu.SaveDownloadedSubtitle, action: .saveDownloadedSubtitle)
        
        let encodingItem = TogglableMenuItem(target: nil, title: I18N.MainMenu.Encoding, action: nil)
        let encodingItemMenu = NSMenu(title: I18N.MainMenu.Encoding)
        menu.setSubmenu(encodingItemMenu, for: encodingItem)
        encodingItemMenu.addItem(title: I18N.MainMenu.None, action: nil).state = .on
        encodingItemMenu.delegate = self
        
        let scaleUp = TogglableMenuItem(target: self, title: I18N.MainMenu.ScaleUp, action: .scaleUp)
        let scaleDown = TogglableMenuItem(target: self, title: I18N.MainMenu.ScaleDown, action: .scaleDown)
        let resetSubtitleScale = TogglableMenuItem(target: self, title: I18N.MainMenu.ResetSubtitleScale, action: .resetSubtitleScale)
        
        let subtitleDelay = TogglableMenuItem(target: nil, title: "\(I18N.MainMenu.SubtitleDelay)0.00s", action: nil)
        let subtitleDelayPlusZeroPointFives = TogglableMenuItem(target: self, title: I18N.MainMenu.SubtitleDelayPlusZeroPointFives, action: .subtitleDelayPlusZeroPointFiveSecond)
        let subtitleDelayMinusZeroPointFives = TogglableMenuItem(target: self, title: I18N.MainMenu.SubtitleDelayMinusZeroPointFives, action: .subtitleDelayMinusZeroPointFiveSecond)
        let resetSubtitleDelay = TogglableMenuItem(target: self, title: I18N.MainMenu.ResetSubtitleDelay, action: .resetSubtitleDelay)
        
        let showFontSetting = TogglableMenuItem(target: self, title: I18N.MainMenu.Font, action: .showFontList, enabled: true)
        
        
        let toAdd: [NSMenuItem] = [showSubtitleQuickSettingsPanel, .separator(), subtitleItem, secondSubtitleItem, loadExternalSubtitle, .separator(), findOnlineSubtitles, saveDownloadedSubtitle, .separator(), encodingItem, .separator(), scaleUp, scaleDown, resetSubtitleScale, .separator(), subtitleDelay, subtitleDelayPlusZeroPointFives, subtitleDelayMinusZeroPointFives, resetSubtitleDelay, .separator(), showFontSetting]
        for item in toAdd { menu.addItem(item) }
        
        _itemPool[.subtitleMenu(.showQuickSettingsPanel)] = DI.TogglableItemBox(menuItem: showSubtitleQuickSettingsPanel)
        _itemPool[.subtitleMenu(.subtitle)] = DI.TogglableItemBox(menu: subtitleItemMenu)
        _itemPool[.subtitleMenu(.secondSubtitle)] = DI.TogglableItemBox(menu: secondSubtitleItemMenu)
        _itemPool[.subtitleMenu(.loadExternalSubtitle)] = DI.TogglableItemBox(menuItem: loadExternalSubtitle)
        _itemPool[.subtitleMenu(.findOnlineSubtitles)] = DI.TogglableItemBox(menuItem: findOnlineSubtitles)
        _itemPool[.subtitleMenu(.saveDownloadedSubtitle)] = DI.TogglableItemBox(menuItem: saveDownloadedSubtitle)
        _itemPool[.subtitleMenu(.encoding)] = DI.TogglableItemBox(menu: encodingItemMenu)
        _itemPool[.subtitleMenu(.scaleUp)] = DI.TogglableItemBox(menuItem: scaleUp)
        _itemPool[.subtitleMenu(.scaleDown)] = DI.TogglableItemBox(menuItem: scaleDown)
        _itemPool[.subtitleMenu(.resetSubtitleScale)] = DI.TogglableItemBox(menuItem: resetSubtitleScale)
        _itemPool[.subtitleMenu(.subtitleDelay)] = DI.TogglableItemBox(menuItem: subtitleDelay)
        _itemPool[.subtitleMenu(.subtitleDelayPlusZeroPointFives)] = DI.TogglableItemBox(menuItem: subtitleDelayPlusZeroPointFives)
        _itemPool[.subtitleMenu(.subtitleDelayMinusZeroPointFives)] = DI.TogglableItemBox(menuItem: subtitleDelayMinusZeroPointFives)
        _itemPool[.subtitleMenu(.resetSubtitleDelay)] = DI.TogglableItemBox(menuItem: resetSubtitleDelay)
    }
    
    private func setupWindowMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        menu.addItem(title: I18N.MainMenu.Minimize, action: .performMiniaturize, keyEquivalent: Alphabet.m)
        menu.addItem(title: I18N.MainMenu.MinimizeAll, action: .minimizeAll)
        menu.addItem(title: I18N.MainMenu.Zoom, action: .performZoom)
        menu.addItem(.separator())
        let inspector = TogglableMenuItem(target: self, title: I18N.MainMenu.Inspector, action: .inspector, keyEquivalent: Alphabet.i)
        menu.addItem(inspector)
        menu.addItem(.separator())
        menu.addItem(title: I18N.MainMenu.BringAllToFront, action: .arrangeInFront)
        NSApp.windowsMenu = menu
        _itemPool[.windowMenu(.inspector)] = DI.TogglableItemBox(menuItem: inspector)
    }
    
    private func setupHelpMenu(_ value: NSMenu?) {
        guard let menu = value else { return }
        menu.addItem(withTitle: I18N.MainMenu.LeafHelp, action: .showHelp, keyEquivalent: "?")
        menu.addItem(.separator())
        menu.addItem(withTitle: I18N.MainMenu.SetLeafAsTheDefaultApp, action: .setLeafAsTheDefaultApp, keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: I18N.MainMenu.Github, action: .github, keyEquivalent: "").target = self
        menu.addItem(withTitle: I18N.MainMenu.Website, action: .website, keyEquivalent: "").target = self
        NSApp.helpMenu = menu
    }
}
// MARK: - UI update
extension MainMenu {
    private func updatePlayPauseButton() {
        // update play pause button title
        var playPauseTitle = I18N.MainMenu.Playback
        if let playingState = playbackDelegate?.playing() {
            playPauseTitle = playingState ? I18N.MainMenu.Pause : I18N.MainMenu.Playback
        }
        _itemPool[.playbackMenu(.playPause)]?.menuItem?.title = playPauseTitle
    }
    
    private func updatePlaylistMenu() {
        // .playbackMenu(.playlist)
        let playlistenu = _itemPool[.playbackMenu(.playlist)]?.menu
        
        if let playlist = playbackDelegate?.media?.playlist {
            playlistenu?.removeAllItems()
            
            let index = playbackDelegate?.media?.playingListIndex ?? -1
            for (i, item) in playlist.enumerated() {
                let name = item.filenameForDisplay
                let item = NSMenuItem(title: name, action: .selectedPlaylistItem, keyEquivalent: "")
                if i == index { item.state = .on }
                item.target = self
                item.tag = i
                playlistenu?.addItem(item)
            }
        } else {
            playlistenu?.defaultNoneItem()
        }
    }
    
    private func updateChapterMenu() {
        
        // .playbackMenu(.chapters)
        let chaptersMenu = _itemPool[.playbackMenu(.chapters)]?.menu
        if let chapters = playbackDelegate?.media?.chapters {
            chaptersMenu?.removeAllItems()
            let index = playbackDelegate?.media?.playingChapterIndex ?? -1
            for (i, item) in chapters.enumerated() {
                let item = NSMenuItem(title: item.title, action: .selectedChapters, keyEquivalent: "")
                item.target = self
                item.tag = i
                if i == index { item.state = .on }
                chaptersMenu?.addItem(item)
            }
        } else {
            chaptersMenu?.defaultNoneItem()
        }
    }
}

extension MainMenu: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if menu == _itemPool[.playbackMenu(.menu)]?.menu {
            updatePlayPauseButton()
        }
        if menu == _itemPool[.playbackMenu(.playlist)]?.menu {
            updatePlaylistMenu()
        }
        if menu == _itemPool[.playbackMenu(.chapters)]?.menu {
            updateChapterMenu()
        }
    }
}

extension MainMenu: MainMenuResolver {
    
    func playingStateChanged() {
        
    }
    
    func update(item: DI.TogglableMenu, instance: DI.TogglableItemBox?) {
        _itemPool[item] = instance
    }
    
    func update(item: DI.TogglableMenu, handler: (DI.TogglableItemBox?) -> Void) {
        let box = _itemPool[item]
        handler(box)
    }
}

// MARK: - NSSharingServiceDelegate
//extension MainMenu: NSSharingServicePickerDelegate {
//    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
//        print("a")
//    }
//
//    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
//
//    }
//}
// MARK: - Event Handler
extension MainMenu {
    // MARK:  Application
    @objc fileprivate func checkUpdate() {
        // TODO: checkUpdate
    }
    @objc fileprivate func preferences() {
        // TODO: preferences
    }
    // MARK:  File
    @objc fileprivate func openInNewWindow() {
        // TODO: openInNewWindow
    }
    @objc fileprivate func openURLInNewWindow() {
        // TODO: openURLInNewWindow
    }
    @objc fileprivate func playbackHistory() {
        // TODO: playbackHistory
    }
    
    @objc fileprivate func deleteCurrentFile() {
        guard let url = playbackDelegate?.media?.currentURL else { return }
        do {
            playbackDelegate?.removeCurrentFileFromPlayList()
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch let error {
            NotificationCenter.showError(with: I18N.Alert.Playlist.ErrorDeleting(value1: error.localizedDescription))
        }
    }
    
    @objc fileprivate func saveCurrentPlaylist() {
        NSSavePanel.quickSavePanel(title: "Save to playlist", types: ["m3u8"]) {[unowned self] (url) in
            guard url.isFileURL, let list = self.playbackDelegate?.media?.playlist else { return }
            var playlist = ""
            for item in list { playlist.append((item.filename + "\n")) }
            do {
                try playlist.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                NotificationCenter.showError(with: I18N.Alert.ErrorSavingFile(value1: "playlist", error.localizedDescription))
            }
            
        }
    }
    @objc fileprivate func share() { }
    
    @objc fileprivate func showShare(sender: NSButton) {
//        guard let url = playbackDelegate?.url, let view = NSApp.windows.last?.contentView else { return }
//        let picker = NSSharingServicePicker(items: [url])
//        //        picker.delegate = self
//        picker.show(relativeTo: view.frame, of: view, preferredEdge: NSRectEdge.maxY)
    }
    
    // MARK: Playback
    @objc fileprivate func playPause() {
        playbackDelegate?.togglePlayPause()
    }
    
    @objc fileprivate func stopAndClearPlaylist() {
        playbackDelegate?.stop()
        playbackDelegate?.clearPlaylist()
    }
    @objc fileprivate func stepForwardFives() {
        playbackDelegate?.seekRelative(second: 5, extra: nil)
    }
    @objc fileprivate func stepBackwardFives() {
        playbackDelegate?.seekRelative(second: -5, extra: nil)
    }
    @objc fileprivate func jumpToBeginning() {
        playbackDelegate?.seekAbsolute(second: 0)
    }
    @objc fileprivate func jumpTo() {
        // TODO: jumpTo
    }
    @objc fileprivate func takeAScreenshot() {
        // TODO: takeAScreenshot
    }
    @objc fileprivate func goToScreenshotFolder() {
        // TODO: goToScreenshotFolder
    }
    @objc fileprivate func abLoop() {
        // TODO: abLoop
    }
    @objc fileprivate func fileLoop() {
        // TODO: fileLoop
    }
    @objc fileprivate func showPlaylistPanel() {
        // TODO: showPlaylistPanel
    }
    @objc fileprivate func playlistLoop() {
        // TODO: playlistLoop
    }
    @objc fileprivate func playlist() {
        // TODO: playlist
    }
    @objc fileprivate func selectedPlaylistItem(sender: NSMenuItem) {
        if sender.menu?.selectedItem.contains(sender) == true { return }
        playbackDelegate?.playChapter(at: sender.tag)
        sender.menu?.selectedItem.forEach { $0.state = .off }
        sender.state = .on
    }
    @objc fileprivate func showChaptersPanel() {
        // TODO: showChaptersPanel
    }
    @objc fileprivate func chapters() {
        // TODO: chapters
    }
    @objc fileprivate func selectedChapters(sender: NSMenuItem) {
        if sender.menu?.selectedItem.contains(sender) == true { return }
        playbackDelegate?.playChapter(at: sender.tag)
        sender.menu?.selectedItem.forEach { $0.state = .off }
        sender.state = .on
    }
    // MARK: Video
    @objc fileprivate func showVideoQuickSettingsPanel() {
        // TODO: chapters
    }
    
    @objc fileprivate func halfSize() {
        // TODO: chapters
    }
    @objc fileprivate func normalSize() {
        // TODO: chapters
    }
    @objc fileprivate func doubleSize() {
        // TODO: chapters
    }
    @objc fileprivate func fitToScreen() {
        // TODO: chapters
    }
    @objc fileprivate func biggerSize() {
        // TODO: chapters
    }
    @objc fileprivate func smallerSize() {
        // TODO: chapters
    }
    @objc fileprivate func enterFullScreen() {
        // TODO: chapters
    }
    @objc fileprivate func togglePIP() {
        // TODO: chapters
    }
    @objc fileprivate func floatOnTop() {
        // TODO: chapters
    }
    @objc fileprivate func musicMode() {
        // TODO: chapters
    }
    
    @objc fileprivate func aspectRatioChange(sender: TogglableMenuItem) {
        guard let oldValue: MainMenuResolver = DI.referrence(for: .mainMenu) else { return }
        let key: DI.TogglableMenu = .videoMenu(.selectedAspectRatio)
        oldValue.update(item: key, handler: { $0?.menuItem?.state = .off })
        sender.state = .on
//        print("value selected:\(MainMenu.Constant.aspectValue(at: sender.tag))")
        oldValue.update(item: key, instance: DI.TogglableItemBox(menuItem: sender))
    }
    
    @objc fileprivate func crop(sender: TogglableMenuItem) {
        guard let oldValue: MainMenuResolver = DI.referrence(for: .mainMenu) else { return }
        let key: DI.TogglableMenu = .videoMenu(.selectedCrop)
        oldValue.update(item: key, handler: { $0?.menuItem?.state = .off })
        sender.state = .on
        oldValue.update(item: key, instance: DI.TogglableItemBox(menuItem: sender))
    }
    
    @objc fileprivate func rotation(sender: TogglableMenuItem) {
        guard let oldValue: MainMenuResolver = DI.referrence(for: .mainMenu) else { return }
        let key: DI.TogglableMenu = .videoMenu(.selectedRotation)
        oldValue.update(item: key, handler: { $0?.menuItem?.state = .off })
        sender.state = .on
        oldValue.update(item: key, instance: DI.TogglableItemBox(menuItem: sender))
    }
    
    @objc fileprivate func flip(sender: TogglableMenuItem) {
        guard let oldValue: MainMenuResolver = DI.referrence(for: .mainMenu) else { return }
        let key: DI.TogglableMenu = .videoMenu(.selectedFlip)
        var boxNew = DI.TogglableItemBox(menuItem: sender)
        oldValue.update(item: key, handler: { box in
            if box?.menuItem == sender {
                boxNew = DI.TogglableItemBox()
            }
            box?.menuItem?.state = .off
        })
        boxNew.menuItem?.state = .on
        oldValue.update(item: key, instance: boxNew)
    }
    
    @objc fileprivate func deinterlace() {
        
    }
    
    @objc fileprivate func deLogo() {
        
    }
    
    @objc fileprivate func showVideoFilters() {
        
    }
    
    // MARK: Video
    @objc fileprivate func showAudioQuickSettingsPanel() {
        // TODO: chapters
    }
    @objc fileprivate func volumePlusFivePercent() {
        // TODO: chapters
    }
    @objc fileprivate func volumeMinusFivePercent() {
        // TODO: chapters
    }
    @objc fileprivate func mute() {
        // TODO: chapters
    }
    
    @objc fileprivate func audioDelayPlusZeroPointFives() {
        // TODO: chapters
    }
    
    @objc fileprivate func audioDelayMinusZeroPointFives() {
        // TODO: chapters
    }
    
    @objc fileprivate func resetAudioDelay() {
        // TODO: chapters
    }
    
    @objc fileprivate func showAudioFilters() {
        // TODO: chapters
    }
    // MARK: Subtitle
    @objc fileprivate func showSubtitleQuickSettingsPanel() {
        
    }
    @objc fileprivate func loadExternalSubtitle() {
        
    }
    @objc fileprivate func findOnlineSubtitles() {
        
    }
    @objc fileprivate func saveDownloadedSubtitle() {
        
    }
    @objc fileprivate func scaleUp() {
        
    }
    @objc fileprivate func scaleDown() {
        
    }
    @objc fileprivate func resetSubtitleScale() {
        
    }
    
    @objc fileprivate func subtitleDelayPlusZeroPointFiveSecond() {
        
    }
    @objc fileprivate func subtitleDelayMinusZeroPointFiveSecond() {
        
    }
    
    @objc fileprivate func resetSubtitleDelay() {
        
    }
    @objc fileprivate func showFontList() {
        
    }

    
    
    // MARK: Window
    @objc fileprivate func inspector() {
        // TODO: inspector
    }
    // MARK: Help
    @objc fileprivate func setLeafAsTheDefaultApp() {
        // TODO: setLeafAsTheDefaultApp
    }
    @objc fileprivate func github() {
        // TODO: github
    }
    @objc fileprivate func website() {
        // TODO: website
    }
}


private extension Selector {
    
    // Application
    static let about       = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
    static let hide        = #selector(NSApplication.hide(_:))
    static let hideOthers  = #selector(NSApplication.hideOtherApplications(_:))
    static let unhideAll   = #selector(NSApplication.unhideAllApplications(_:))
    static let terminate   = #selector(NSApplication.terminate(_:))
    
    static let checkUpdate = #selector(MainMenu.checkUpdate)
    static let preferences = #selector(MainMenu.preferences)
    
    // File
    static let openInNewWindow      = #selector(MainMenu.openInNewWindow)
    static let openURLInNewWindow   = #selector(MainMenu.openURLInNewWindow)
    static let clearRecentDocuments = #selector(NSDocumentController.clearRecentDocuments(_:))
    static let playbackHistory      = #selector(MainMenu.playbackHistory)
    static let performClose         = #selector(NSWindow.performClose(_:))
    static let deleteCurrentFile    = #selector(MainMenu.deleteCurrentFile)
    static let saveCurrentPlaylist  = #selector(MainMenu.saveCurrentPlaylist)
    static let share                = #selector(MainMenu.share)
    static let showShare            = #selector(MainMenu.showShare(sender:))
    // Playback
    static let playPause            = #selector(MainMenu.playPause)
    static let stopAndClearPlaylist = #selector(MainMenu.stopAndClearPlaylist)
    static let stepForwardFives     = #selector(MainMenu.stepForwardFives)
    static let stepBackwardFives    = #selector(MainMenu.stepBackwardFives)
    static let jumpToBeginning      = #selector(MainMenu.jumpToBeginning)
    static let jumpTo               = #selector(MainMenu.jumpTo)
    static let takeAScreenshot      = #selector(MainMenu.takeAScreenshot)
    static let goToScreenshotFolder = #selector(MainMenu.goToScreenshotFolder)
    static let abLoop               = #selector(MainMenu.abLoop)
    static let fileLoop             = #selector(MainMenu.fileLoop)
    static let showPlaylistPanel    = #selector(MainMenu.showPlaylistPanel)
    static let playlistLoop         = #selector(MainMenu.playlistLoop)
    static let playlist             = #selector(MainMenu.playlist)
    static let selectedPlaylistItem = #selector(MainMenu.selectedPlaylistItem(sender:))
    static let showChaptersPanel    = #selector(MainMenu.showChaptersPanel)
    static let chapters             = #selector(MainMenu.chapters)
    static let selectedChapters     = #selector(MainMenu.selectedChapters(sender:))
    
    // Video
    static let showVideoQuickSettingsPanel  = #selector(MainMenu.showVideoQuickSettingsPanel)
    static let halfSize                     = #selector(MainMenu.halfSize)
    static let normalSize                   = #selector(MainMenu.normalSize)
    static let doubleSize                   = #selector(MainMenu.doubleSize)
    static let fitToScreen                  = #selector(MainMenu.fitToScreen)
    static let biggerSize                   = #selector(MainMenu.biggerSize)
    static let smallerSize                  = #selector(MainMenu.smallerSize)
    static let enterFullScreen              = #selector(MainMenu.enterFullScreen)
    static let togglePIP                    = #selector(MainMenu.togglePIP)
    static let floatOnTop                   = #selector(MainMenu.floatOnTop)
    static let musicMode                    = #selector(MainMenu.musicMode)
    static let aspectRatioChange            = #selector(MainMenu.aspectRatioChange(sender:))
    static let crop                         = #selector(MainMenu.crop(sender:))
    static let rotation                     = #selector(MainMenu.rotation(sender:))
    static let flip                         = #selector(MainMenu.flip(sender:))
    static let deinterlace                  = #selector(MainMenu.deinterlace)
    static let deLogo                       = #selector(MainMenu.deLogo)
    static let showVideoFilters             = #selector(MainMenu.showVideoFilters)
    
    //Audio
    static let showAudioQuickSettingsPanel      = #selector(MainMenu.showAudioQuickSettingsPanel)
    static let volumePlusFivePercent            = #selector(MainMenu.volumePlusFivePercent)
    static let volumeMinusFivePercent           = #selector(MainMenu.volumeMinusFivePercent)
    static let mute                             = #selector(MainMenu.mute)
    static let audioDelayPlusZeroPointFives     = #selector(MainMenu.audioDelayPlusZeroPointFives)
    static let audioDelayMinusZeroPointFives    = #selector(MainMenu.audioDelayMinusZeroPointFives)
    static let resetAudioDelay                  = #selector(MainMenu.resetAudioDelay)
    static let showAudioFilters                 = #selector(MainMenu.showAudioFilters)
    
    // Subtitle
    static let showSubtitleQuickSettingsPanel   = #selector(MainMenu.showSubtitleQuickSettingsPanel)
    static let loadExternalSubtitle             = #selector(MainMenu.loadExternalSubtitle)
    static let findOnlineSubtitles              = #selector(MainMenu.findOnlineSubtitles)
    static let saveDownloadedSubtitle           = #selector(MainMenu.saveDownloadedSubtitle)
    static let scaleUp                          = #selector(MainMenu.scaleUp)
    static let scaleDown                        = #selector(MainMenu.scaleDown)
    static let resetSubtitleScale               = #selector(MainMenu.resetSubtitleScale)
    static let resetSubtitleDelay               = #selector(MainMenu.resetSubtitleDelay)
    static let showFontList                     = #selector(MainMenu.showFontList)
    static let subtitleDelayPlusZeroPointFiveSecond     = #selector(MainMenu.subtitleDelayPlusZeroPointFiveSecond)
    static let subtitleDelayMinusZeroPointFiveSecond    = #selector(MainMenu.subtitleDelayMinusZeroPointFiveSecond)
    
    
    // Window
    static let performMiniaturize = #selector(NSWindow.performMiniaturize(_:))
    static let performZoom        = #selector(NSWindow.performZoom(_:))
    static let minimizeAll        = #selector(NSApplication.miniaturizeAll(_:))
    static let arrangeInFront     = #selector(NSApplication.arrangeInFront(_:))
    static let inspector          = #selector(MainMenu.inspector)
    
    // Help
    static let showHelp                 = #selector(NSApplication.showHelp(_:))
    static let setLeafAsTheDefaultApp   = #selector(MainMenu.setLeafAsTheDefaultApp)
    static let github                   = #selector(MainMenu.github)
    static let website                  = #selector(MainMenu.website)
}
// MARK: - inner classes
extension MainMenu {
    
    public final class TogglableMenuItem: NSMenuItem, TogglableMenuItemResolver {
        
        public override init(title string: String, action selector: Selector?, keyEquivalent charCode: String) {
            super.init(title: string, action: selector, keyEquivalent: charCode)
        }
        
        public required init(coder decoder: NSCoder) {
            super.init(coder: decoder)
        }
        
        public convenience init(target: AnyObject?, title string: String, action selector: Selector?, keyEquivalent charCode: String = "", enabled: Bool = false, keyEquivalentModifierMask mask: NSEvent.ModifierFlags = [.command]) {
            self.init(title: string, action: selector, keyEquivalent: charCode)
            self.target = target
            toggleTo(enabled: enabled)
            keyEquivalentModifierMask = mask
        }
        
        public convenience init<T: RawRepresentable>(target: AnyObject?, title string: String, action selector: Selector?, keyEquivalent charCode: T, enabled: Bool = false, keyEquivalentModifierMask mask: NSEvent.ModifierFlags = [.command]) where T.RawValue == String {
            self.init(title: string, action: selector, keyEquivalent: charCode.rawValue)
            self.target = target
            toggleTo(enabled: enabled)
            keyEquivalentModifierMask = mask
        }
        
        private var _originalAction: Selector? = nil
        
        public func toggleTo(enabled: Bool) {
            if enabled == false {
                if let sel = action { _originalAction = sel }
                action = nil
            } else if let sel = _originalAction { action = sel }
        }
    }
    
}
extension Array {
    subscript(le_safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
extension MainMenu {
    fileprivate struct Constant {
        private static let aspectValues: [Float] = [0.0, 4.0/3.0, 5.0/4.0, 16.0/9.0, 16.0/10.0, 1.0/1.0, 3.0/2.0, 2.21/1.0, 2.35/1.0, 2.39/1.0]
        private static let cropValues: [Float] = aspectValues
        private static let rotationValues: [Float] = [0.0, 90.0, 180.0, 270.0]
        fileprivate static func aspectValue(at index: Int) -> Float? { return aspectValues[le_safe: index] }
        fileprivate static func cropValue(at index: Int) -> Float? { return cropValues[le_safe: index] }
        fileprivate static func rotationValue(at index: Int) -> Float? { return rotationValues[le_safe: index] }
    }
    
    public enum Numberic: String { case zero = "0", one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9"}
    public enum Alphabet: String { case a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z }
    
    public enum Key: String {
        case spacebar = " "
        case minus = "-"
        case equal = "="
        ///
        case empty = ""
        /// ,
        case comma = ","
        /// .
        case dot = "."
        /// ⌘
        case command = "⌘"
        /// ↩︎
        case enter = "↩︎"
        /// ⇧
        case shift = "⇧"
        /// ⌥
        case alt = "⌥"
        /// ⌃
        case ctrl = "⌃"
        /// ␣
        case space = "␣"
        /// ⌫
        case bs = "⌫"
        /// ⌦
        case del = "⌦"
        /// ⇥
        case tab = "⇥"
        /// ⎋
        case esc = "⎋"
        /// ↑
        case up = "↑"
        /// ↓
        case down = "↓"
        /// ←
        case left = "←"
        /// →
        case right = "→"
        /// ⇞
        case pgup = "⇞"
        /// ⇟
        case pgdwn = "⇟"
        /// ↖︎
        case home = "↖︎"
        /// ↘︎
        case end = "↘︎"
        /// ▶︎\u{2006}❙\u{200A}❙
        case play = "▶︎\u{2006}❙\u{200A}❙"
        /// ◀︎◀︎
        case prev = "◀︎◀︎"
        /// ▶︎▶︎
        case next = "▶︎▶︎"
    }
}
extension I18N.QuickSetting {
    // 1:1
    static let OneOne: String = "1:1"
    // 2.21:1
    static let TwoPointTweetyOneOne: String = "2.21:1"
    // 2.35:1
    static let TwoPointThirtyFiveOne: String = "2.35:1"
    // 2.39:1
    static let TwoPointThirtyNineOne: String = "2.39:1"
}

extension NSMenu {
    @discardableResult fileprivate func addItem(title string: String, action selector: Selector?, target: AnyObject? = nil, keyEquivalent charCode: String = "") -> NSMenuItem {
        let item = addItem(withTitle: string, action: selector, keyEquivalent: charCode)
        item.target = target
        return item
    }
    
    @discardableResult fileprivate func addItem<T: RawRepresentable>(title string: String, action selector: Selector?, target: AnyObject? = nil, keyEquivalent charCode: T) -> NSMenuItem where T.RawValue == String {
        let item = addItem(withTitle: string, action: selector, keyEquivalent: charCode.rawValue)
        item.target = target
        return item
    }
    
    fileprivate func addSeparator() {
        addItem(.separator())
    }
    
    public func toggleAllItem(enabled: Bool) {
        items.forEach { (item) in
            (item as? MainMenu.TogglableMenuItem)?.toggleTo(enabled: enabled)
        }
    }
    var selectedItem: [NSMenuItem] {
        var selected: [NSMenuItem]  = []
        for item in items {
            guard item.state == .on else { continue }
            selected.append(item)
        }
        return selected
    }
}

extension NSSavePanel {
    fileprivate enum AlertMode {
        case modal
        case nonModal
        case sheet
        case sheetModal
    }
    fileprivate static func quickSavePanel(title: String, types: [String],
                                       mode: AlertMode = .nonModal, sheetWindow: NSWindow? = nil,
                                       ok: @escaping (URL) -> Void) {
        let panel = NSSavePanel()
        panel.title = title
        panel.canCreateDirectories = true
        panel.allowedFileTypes = types
        let handler: (NSApplication.ModalResponse) -> Void = { result in
            guard result == .OK, let url = panel.url else { return }
            ok(url)
        }
        switch mode {
        case .modal:
            let response = panel.runModal()
            handler(response)
        case .nonModal: panel.begin(completionHandler: handler)
        case .sheet:
            guard let sheetWindow = sheetWindow else {
                print("No sheet window")
                fatalError()
            }
            panel.beginSheet(sheetWindow, completionHandler: handler)
        default: print("quickSavePanel: Unsupported mode")
        }
    }
}


