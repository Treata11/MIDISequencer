//
//  UtilityExtensions.swift
//
//
//  Created by Treata Norouzi on 12/28/23.
//

import AVFoundation
#if canImport(AppKit)
import AppKit
#endif

#if os(macOS)
extension NSAlert {
    class func runModal(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }
}
#endif

extension String {
    func fullRange() -> NSRange {
        return NSRange(location: 0, length: NSString(string: self).length)
    }

    func hyperlink(with url: URL) -> NSAttributedString {
        let stringRange = self.fullRange()
        let attrString = NSMutableAttributedString(string: self)
        attrString.addAttribute(NSAttributedString.Key.link, value: url, range: stringRange)
        return attrString
    }

    #if os(macOS)
    func addColor(in range: NSRange, color: NSColor) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: self)
        attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        return attrString
    }
    #endif
}

// This extension makes it possible to throw raw strings as Errors
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

#if os(macOS)
extension NSMutableAttributedString {
    func setFontFace(font: NSFont, color: NSColor? = nil) {
        beginEditing()
        self.enumerateAttribute(.font, in: self.string.fullRange()) { (value, range, _) in
            if let f = value as? NSFont, let familyName = font.familyName {
                let newFontDescriptor = f.fontDescriptor.withFamily(familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits).withSize(f.pointSize)
                guard let newFont = NSFont(descriptor: newFontDescriptor, size: font.pointSize) else {
                    fatalError("Could not create new font object")
                }
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color = color {
                    removeAttribute(.foregroundColor, range: range)
                    addAttribute(.foregroundColor, value: color, range: range)
                }
            }
        }
        endEditing()
    }
}
#endif

extension Float {
    func rounded(toDecimalPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

#if os(macOS)
extension NSWindow {
    var titlebarHeight: CGFloat {
        let contentHeight = self.contentRect(forFrameRect: self.frame).height
        return self.frame.height - contentHeight
    }
}
#endif

extension AVAudioFormat {
    var commonFormat: AVAudioCommonFormat {
        let streamDescription = self.streamDescription.pointee

        switch streamDescription.mBitsPerChannel {
        case 16:
            return .pcmFormatInt16
        case 32:
            if streamDescription.mFormatFlags & kLinearPCMFormatFlagIsFloat == 1 {
                return .pcmFormatFloat32
            } else {
                return .pcmFormatInt32
            }
        case 64:
            return .pcmFormatFloat64
        default:
            return .otherFormat
        }
    }
}

extension BinaryFloatingPoint {
    
    func asTimeString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = style
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self)) ?? "" //formatter.string(from: self) ?? ""
    }
}
