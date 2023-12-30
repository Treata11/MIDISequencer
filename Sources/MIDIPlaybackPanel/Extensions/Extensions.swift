//
//  Extensions.swift
//
//
//  Created by Treata Norouzi on 12/30/23.
//

import Foundation

extension BinaryFloatingPoint {
    
    func asTimeString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = style
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self)) ?? "" //formatter.string(from: self) ?? ""
    }
}
