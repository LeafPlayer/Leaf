//
//  MPV+Extension.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/17.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
import libmpv
import ResourcesManager

extension Int32 {
    public func checkError() throws {
        guard self < 0 else { return }
        throw MPV.ActionError.error("\(String(cString: mpv_error_string(self))), return:\(self)")
    }
}

extension Double {
    func constrain(min: Double, max: Double) -> Double {
        var value = self
        if self < min { value = min }
        if self > max { value = max }
        return value
    }
}
extension FileManager {
    static func createDirIfNotExist(url: URL) {
        let path = url.path
        // check exist
        if FileManager.default.fileExists(atPath: path) == false {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Cannot create folder in Application Support directory")
                fatalError()
            }
        }
    }
}
extension NSMenu {
    func defaultNoneItem() {
        removeAllItems()
        addItem(withTitle: I18N.MainMenu.None, action: nil, keyEquivalent: "").state = .on
    }
}
extension NSColor {
    public var colorHex: MPV.Preference.ColorHex {
        let color = usingColorSpace(NSColorSpace.deviceRGB)!
        return MPV.Preference.ColorHex(r: color.redComponent, g: color.greenComponent, b: color.blueComponent, a: color.alphaComponent)
    }
}


extension UnsafeMutableRawPointer {
    func to<T : AnyObject>(object: T.Type) -> T {
        return Unmanaged<T>.fromOpaque(self).takeUnretainedValue()
    }
    static func from<T: AnyObject>(object: T) -> UnsafeMutableRawPointer {
        return Unmanaged<T>.passUnretained(object).toOpaque()
    }
}
extension NSSize {
    var aspect: CGFloat { return width / height }
    /** Resize to no smaller than a min size while keeping same aspect */
    func satisfyMinSizeWithSameAspectRatio(_ minSize: NSSize) -> NSSize {
        if width >= minSize.width && height >= minSize.height {  // no need to resize if larger
            return self
        } else {
            return grow(toSize: minSize)
        }
    }
    
    /** Resize to no larger than a max size while keeping same aspect */
    func satisfyMaxSizeWithSameAspectRatio(_ maxSize: NSSize) -> NSSize {
        if width <= maxSize.width && height <= maxSize.height {  // no need to resize if smaller
            return self
        } else {
            return shrink(toSize: maxSize)
        }
    }
    
    /**
     Given another size S, returns a size that:
     
     - maintains the same aspect ratio;
     - has same height or/and width as S;
     - always bigger than S.
     
     - parameter toSize: The given size S.
     
     ```
     +--+------+--+
     |  |      |  |
     |  |  S   |  |<-- The result size
     |  |      |  |
     +--+------+--+
     ```
     */
    func grow(toSize size: NSSize) -> NSSize {
        let sizeAspect = size.aspect
        if aspect > sizeAspect {  // self is wider, grow to meet height
            return NSSize(width: size.height * aspect, height: size.height)
        } else {
            return NSSize(width: size.width, height: size.width / aspect)
        }
    }
    
    /**
     Given another size S, returns a size that:
     
     - maintains the same aspect ratio;
     - has same height or/and width as S;
     - always smaller than S.
     
     - parameter toSize: The given size S.
     
     ```
     +--+------+--+
     |  |The   |  |
     |  |result|  |<-- S
     |  |size  |  |
     +--+------+--+
     ```
     */
    func shrink(toSize size: NSSize) -> NSSize {
        let  sizeAspect = size.aspect
        if aspect < sizeAspect { // self is taller, shrink to meet height
            return NSSize(width: size.height * aspect, height: size.height)
        } else {
            return NSSize(width: size.width, height: size.width / aspect)
        }
    }
}
extension NSRect {
    func centeredResize(to newSize: NSSize) -> NSRect {
        return NSRect(x: origin.x - (newSize.width - size.width) / 2,
                      y: origin.y - (newSize.height - size.height) / 2,
                      width: newSize.width,
                      height: newSize.height)
    }
}
extension NSData {
    func md5() -> NSString {
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)
        
        CC_MD5(bytes, CC_LONG(length), md5Buffer)
        
        let output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
        for i in 0..<digestLength {
            output.appendFormat("%02x", md5Buffer[i])
        }
        
        return NSString(format: output)
    }
}
extension String {
    var md5: String { return self.data(using: .utf8)!.md5 }
}
extension Data {
    var md5: String { return (self as NSData).md5() as String }
}
extension NSWindow {
    /** Calculate the window frame from a parsed struct of mpv's `geometry` option. */
    func windowFrame(from value: MPV.Geometry?, newSize: NSSize? = nil) -> NSRect? {
        // set geometry. using `!` should be safe since it passed the regex.
        guard let screenFrame = NSScreen.main?.visibleFrame, let geometry = value else { return nil }
        
        var winFrame = frame
        if let ns = newSize {
            winFrame.size.width = ns.width
            winFrame.size.height = ns.height
        }
        let winAspect = winFrame.size.aspect
        var widthOrHeightIsSet = false
        // w and h can't take effect at same time
        if let strw = geometry.w, strw != "0" {
            let w: CGFloat
            if strw.hasSuffix("%") {
                w = CGFloat(Double(String(strw.dropLast()))! * 0.01 * Double(screenFrame.width))
            } else {
                w = CGFloat(Int(strw)!)
            }
            winFrame.size.width = w
            winFrame.size.height = w / winAspect
            widthOrHeightIsSet = true
        } else if let strh = geometry.h, strh != "0" {
            let h: CGFloat
            if strh.hasSuffix("%") {
                h = CGFloat(Double(String(strh.dropLast()))! * 0.01 * Double(screenFrame.height))
            } else {
                h = CGFloat(Int(strh)!)
            }
            winFrame.size.height = h
            winFrame.size.width = h * winAspect
            widthOrHeightIsSet = true
        }
        // x, origin is window center
        if let strx = geometry.x, let xSign = geometry.xSign {
            let x: CGFloat
            if strx.hasSuffix("%") {
                x = CGFloat(Double(String(strx.dropLast()))! * 0.01 * Double(screenFrame.width)) - winFrame.width / 2
            } else {
                x = CGFloat(Int(strx)!)
            }
            winFrame.origin.x = (xSign == "+" ? x : screenFrame.width - x) + screenFrame.origin.x
            // if xSign equals "-", need set right border as origin
            if (xSign == "-") {
                winFrame.origin.x -= winFrame.width
            }
        }
        // y
        if let stry = geometry.y, let ySign = geometry.ySign {
            let y: CGFloat
            if stry.hasSuffix("%") {
                y = CGFloat(Double(String(stry.dropLast()))! * 0.01 * Double(screenFrame.height)) - winFrame.height / 2
            } else {
                y = CGFloat(Int(stry)!)
            }
            winFrame.origin.y = (ySign == "+" ? y : screenFrame.height - y) + screenFrame.origin.y
            if (ySign == "-") {
                winFrame.origin.y -= winFrame.height
            }
        }
        // if x and y not specified
        if geometry.x == nil && geometry.y == nil && widthOrHeightIsSet {
            winFrame.origin.x = (screenFrame.width - winFrame.width) / 2
            winFrame.origin.y = (screenFrame.height - winFrame.height) / 2
        }
        // return
        return winFrame
    }
}
extension String: PreferenceValueCompatible { public var stringValue: String? { return self } }
extension Double: PreferenceValueCompatible { public var doubleValue: Double? { return self } }
extension Float: PreferenceValueCompatible { public var doubleValue: Double? { return Double(self) } }
extension Int: PreferenceValueCompatible { public var intValue: Int? { return self } }
extension Bool: PreferenceValueCompatible {
    public var boolValue: Bool? { return self }
    public var mpvString: String { return self ? MPV.ExOptValue.yes.rawValue : MPV.ExOptValue.no.rawValue }
}

public protocol PreferenceValueCompatible {
    var stringValue: String? { get }
    var intValue: Int? { get }
    var doubleValue: Double? { get }
    var boolValue: Bool? { get }
}
extension PreferenceValueCompatible {
    public var stringValue: String? { return nil }
    public var intValue: Int? { return nil }
    public var doubleValue: Double? { return nil }
    public var boolValue: Bool? { return nil }
    public var colorValue: String? { return nil }
}
