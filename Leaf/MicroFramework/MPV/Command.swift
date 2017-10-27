//
//  Command.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/17.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Foundation

extension MPV {
    
    /// List of Input Commands
    ///
    public enum Command {
        /**
         Use this to "block" keys that should be unbound, and do nothing. Useful for disabling default bindings, without disabling all bindings with  `--no-input-default-bindings`.
         */
        //        case ignore
        /**
         
         seek
         
         **SeekMode**: *mode for seek*
         
         **Double**: *value for seek percentage/seconds*
         
         **SeekModeExtra**: *Extra command for mode*
         
         ---
         
         - Note:
         Change the playback position. By default, seeks by a relative amount of seconds.
         The second argument consists of flags controlling the seek mode:
         
         **relative**: *Seek relative to current position (a negative value seeks backwards).*
         
         **absolute**: *Seek to a given time (a negative value starts from the end of the file).*
         
         **absolute-percent**: *Seek to a given percent position.*
         
         **relative-percent**: *Seek relative to current position in percent.*
         
         **keyframes**: *Always restart playback at keyframe boundaries (fast).*
         
         **exact**: *Always do exact/hr/precise seeks (slow).*
         
         Multiple flags can be combined, e.g.: absolute+keyframes.
         
         By default, keyframes is used for relative seeks, and exact is used for absolute seeks.
         
         Before mpv 0.9, the keyframes and exact flags had to be passed as 3rd parameter (essentially using a space instead of +). The 3rd parameter is still parsed, but is considered deprecated.
         */
        case seek(SeekMode, Double, SeekModeExtra?)
        public enum SeekMode: String { case relative, relativePercent = "relative-percent", absolute, absolutePercent = "absolute-percent" }
        public enum SeekModeExtra: String { case exact, keyframes }
        /** revert-seek [mode] */
        //        case revertSeek// = "revert-seek"
        /** Play one frame, then pause. Does nothing with audio-only playback. */
        case frameStep
        /**
         Go back by one frame, then pause. Note that this can be very slow (it tries to be precise, not fast), and sometimes fails to behave as expected. How well this works depends on whether precise seeking works correctly (e.g. see the --hr-seek-demuxer-offset option). Video filters or other video post-processing that modifies timing of frames (e.g. deinterlacing) should usually work, but might make backstepping silently behave incorrectly in corner cases. Using `--hr-seek-framedrop=no` should help, although it might make precise seeking slower.
         
         This does not work with audio-only playback.
         */
        case frameBackStep
        /** Set the given property to the given value.*/
        case set(Option.Equalizer, Int)
        /** add <property> [<value>] */
//        case add
        /** cycle <property> [up|down] */
//        case cycle
        /** multiply <property> <factor> */
//        case multiply
        public enum ScreenshotMode: String {
            /// Save the video image, in its original resolution, and with subtitles. Some video outputs may still include the OSD in the output under certain circumstances.
            case subtitles
            /// Like subtitles, but typically without OSD or subtitles. The exact behavior depends on the selected video output.
            case video
        }
        /** Take a screenshot. */
        case screenshot(ScreenshotMode)
        /** screenshot-to-file "<filename>" [subtitles|video|window] */
//        case screenshotToFile// = "screenshot-to-file"
        /**
         Go to the next entry on the playlist.
         
         weak (default)
         If the last file on the playlist is currently played, do nothing.
         */
        case playlistNext
        /**
         Go to the previous entry on the playlist.
         
         weak (default)
         If the first file on the playlist is currently played, do nothing.
         */
        case playlistPrev
        public enum LoadFileMode: String { case replace, append, appendPlay = "append-play" }
        /**
         Load the given file and play it.
         
         **LoadFileMode**: *mode for loadfile*
         
         **String**: *path for resources*
         
         */
        case loadfile(LoadFileMode, String)
        /** loadlist "<playlist>" [replace|append] */
//        case loadlist
        /** Clear the playlist, except the currently played file. */
        case playlistClear
        /** playlist-remove current|<index> */
        case playlistRemove(String)// = "playlist-remove"
        /**
         Move the playlist entry at index1, so that it takes the place of the entry index2. (Paradoxically, the moved playlist entry will not have the index value index2 after moving if index1 was lower than index2, because index2 refers to the target entry, not the index the entry will have after moving.)
         
         **UInt**: *move from this index*
         
         **UInt**: *move to this index*
         */
        case playlistMove(UInt, UInt)
        /** Shuffle the playlist. This is similar to what is done on start if the  --shuffle option is used.*/
        case playlistShuffle// = "playlist-shuffle"
        /** run "command" "arg1" "arg2" ... */
//        case run
        /** Exit the player. If an argument is given, it's used as process exit code. */
        case quit
        /** Exit player, and store current playback position. Playing that file later will seek to the previous position on start. The (optional) argument is exactly as in the quit command. */
//        case quitWatchLater
        /**
         Load the given subtitle file. It is selected as current subtitle after loading.
         sub-add "<file>" [<flags> [<title> [<lang>]]]
         
         **URL**: *subtitle's url*
         */
        case subAdd(URL)
        /** sub-remove [<id>] */
//        case subRemove// = "sub-remove"
        /**
         Reload the given subtitle tracks. If the id argument is missing, reload the current track. (Works on external subtitle files only.)
         
         This works by unloading and re-adding the subtitle track.
         
         **Int**: *subtitle's id*
         */
        case subReload(Int)
        /** sub-step <skip> */
//        case subStep// = "sub-step"
        /** sub-seek <skip> */
//        case subSeek// = "sub-seek"
        /** print-text "<string>" */
//        case printText// = "print-text"
        /** show-text "<string>" [<duration>|- [<level>]] */
//        case showText// = "show-text"
        /** expand-text "<string>" */
//        case expandText// = "expand-text"
        /** show-progress */
//        case showProgress// = "show-progress"
        /** Write the resume config file that the quit-watch-later command writes, but continue playback normally. */
        case writeWatchLaterConfig// = "write-watch-later-config"
        /** Stop playback and clear playlist. With default settings, this is essentially like quit. Useful for the client API: playback can be stopped without terminating the player. */
        case stop
        /** mouse <x> <y> [<button> [single|double]] */
//        case mouse
        /** Send a key event through mpv's input handler, triggering whatever behavior is configured to that key. key_name uses the input.conf naming scheme for keys and modifiers. Useful for the client API: key events can be sent to libmpv to handle internally.
         
         **String**: * string of key*
         */
        case keypress(String)
        /** keydown <key_name> */
//        case keydown
        /** keyup [<key_name>] */
//        case keyup
        /**
         Load the given audio file. See sub-add command.
         audio-add "<file>" [<flags> [<title> [<lang>]]]
         
         **URL**: *audio's url*
         */
        case audioAdd(URL)// = "audio-add"
        /** audio-remove [<id>] */
//        case audioRemove// = "audio-remove"
        /** audio-reload [<id>] */
//        case audioReload// = "audio-reload"
        /** rescan-external-files [<mode>] */
//        case rescanExternalFiles// = "rescan-external-files"
        // FIXME: Normalize Audio Filter
        /**
         af set|add|toggle|del|clr "filter1=params,filter2,..."
         Change audio filter chain. See vf command.
         */
//        case af(String)
        /**
         vf set|add|toggle|del|clr "filter1=params,filter2,..."
         Change video filter chain.
         
         The first argument decides what happens:
         
         **set**: *Overwrite the previous filter chain with the new one.*
         
         **add**: *Append the new filter chain to the previous one.*
         
         **toggle**:
         *Check if the given filter (with the exact parameters) is already in the video chain. If yes, remove the filter. If no, add the filter. (If several filters are passed to the command, this is done for each filter.)*
         
         *A special variant is combining this with labels, and using @name without filter name and parameters as filter entry. This toggles the enable/disable flag.*
         
         **del**: *Remove the given filters from the video chain. Unlike in the other cases, the second parameter is a comma separated list of filter names or integer indexes. 0 would denote the first filter. Negative indexes start from the last filter, and -1 denotes the last filter.*
         
         **clr**: *Remove all filters. Note that like the other sub-commands, this does not control automatically inserted filters.*
         
         The argument is always needed. E.g. in case of clr use vf clr "".
         
         You can assign labels to filter by prefixing them with @name: (where name is a user-chosen arbitrary identifier). Labels can be used to refer to filters by name in all of the filter chain modification commands. For add, using an already used label will replace the existing filter.
         
         The vf command shows the list of requested filters on the OSD after changing the filter chain. This is roughly equivalent to  show-text ${vf}. Note that auto-inserted filters for format conversion are not shown on the list, only what was requested by the user.
         
         Normally, the commands will check whether the video chain is recreated successfully, and will undo the operation on failure. If the command is run before video is configured (can happen if the command is run immediately after opening a file and before a video frame is decoded), this check can't be run. Then it can happen that creating the video chain fails.
         
         
         ## Example for input.conf
         
                 a vf set flip turn video upside-down on the a key
                 b vf set "" remove all video filters on b
                 c vf toggle lavfi=gradfun toggle debanding on c
         
         ## Example how to toggle disabled filters at runtime
         
                 Add something vf-add=@deband:!lavfi=[gradfun] to mpv.conf. The @deband: is the label, and deband is an arbitrary, user-given name for this filter entry. The ! before the filter name disables the filter by default. Everything after this is the normal filter name and the filter parameters.
                 Add a vf toggle @deband to input.conf. This toggles the "disabled" flag for the filter identified with deband.
         */
        // FIXME: Normalize Video Filter
//        case vf(String)
        /** cycle-values ["!reverse"] <property> "<value1>" "<value2>" ... */
//        case cycleValues// = "cycle-values"
        /** enable-section "<section>" [flags] */
//        case enableSection// = "enable-section"
        /** disable-section "<section>" */
//        case disableSection// = "disable-section"
        /** define-section "<section>" "<contents>" [default|force] */
//        case defineSection// = "define-section"
        /** overlay-add <id> <x> <y> "<file>" <offset> "<fmt>" <w> <h> <stride> */
//        case overlayAdd// = "overlay-add"
        /** overlay-remove <id> */
//        case overlayRemove// = "overlay-remove"
        /** script-message "<arg1>" "<arg2>" ... */
//        case scriptMessage// = "script-message"
        /** script-message-to "<target>" "<arg1>" "<arg2>" ... */
//        case scriptMessageTo// = "script-message-to"
        /** script-binding "<name>" */
//        case scriptBinding// = "script-binding"
        /**
         ab-loop
         
         Cycle through A-B loop states. The first command will set the A point (the ab-loop-a property); the second the B point, and the third will clear both points.
         */
        case abLoop// = "ab-loop"
        /** drop-buffers */
//        case dropBuffers// = "drop-buffers"
        /** screenshot-raw [subtitles|video|window] */
//        case screenshotRaw// = "screenshot-raw"
        /** vf-command "<label>" "<cmd>" "<args>" */
//        case vfCommand// = "vf-command"
        /** af-command "<label>" "<cmd>" "<args>" */
//        case afCommand// = "af-command"
        /** apply-profile "<name>" */
//        case applyProfile// = "apply-profile"
        /** load-script "<path>" */
//        case loadScript// = "load-script"
        
        public var commands: [String?] {
            var total: [String?] = []
            switch self {
            case .abLoop: total = ["ab-loop"]
//            case let .af(filter): total = ["af", filter]
            case let .audioAdd(url): total = ["audio-add", "\(url.path)"]
            case .frameBackStep:  total = ["frame-back-step"]
            case .frameStep: total = ["frame-step"]
            case let .keypress(code): total = ["keypress", code]
            case let .loadfile(mode, url): total = ["loadfile", "\(url)", "\(mode.rawValue)"]
            case .playlistClear: total = ["playlist-clear"]
            case let .playlistRemove(index): total = ["playlist-remove", index]
            case let .playlistMove(from, to): total = ["playlist-move", "\(from)", "\(to)"]
            case .playlistNext: total = ["playlist-next"]
            case .playlistPrev: total = ["playlist-prev"]
            case .playlistShuffle: total = ["playlist-shuffle"]
            case .quit: total = ["quit"]
            case let .screenshot(mode): total = ["screenshot", "\(mode.rawValue)"]
            case let .seek(mode, value, extra):
                total = ["seek", "\(mode.rawValue)", "\(value)"]
                if let string = extra?.rawValue { total.append(string) }
            case let .set(property, value): total = ["set", "\(property.rawValue)", "\(value)"]
            case .stop: total = ["stop"]
            case let .subAdd(url): total = ["sub-add", "\(url.path)"]
            case let .subReload(index): total = ["sub-reload", "\(index)"]
//            case let .vf(filter): total = ["vf", filter]
            case .writeWatchLaterConfig: total = ["write-watch-later-config"]
            }
            total.append(nil)//nil for end
            return total
        }
    }
    
}
