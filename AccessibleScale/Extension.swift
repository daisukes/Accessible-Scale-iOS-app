//
//  Extension.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import Foundation
import SwiftUI
import DarwinGATT
import CoreBluetooth

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX " : "%02hhx "
        return map { String(format: format, $0) }.joined()
    }
}

extension View {
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

func dataWithHexString(hex: String, checksum: Bool = true) -> Data {
    var hex = hex.replacingOccurrences(of: " ", with: "")
    var data = Data()
    while(hex.count > 0) {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        var ch: UInt64 = 0
        Scanner(string: c).scanHexInt64(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}
	
