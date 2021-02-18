//
//  GATTCustom.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation

class GATTCustomAthleteMode {
    enum Mode: UInt16 {
        case Normal = 0x0004
        case Athlete = 0x000E
    }
    let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func compose() -> Data {
        var data = Data()
        GATTUtil.append(&data, self.mode.rawValue)
        return data
    }
}

class GATTCustomScaleUnit {
    enum Mode: UInt8 {
        case Kilogram = 0x01
        case Pound = 0x02
        case Stone = 0x03
    }

    let mode: Mode

    init(unit: ScaleUnit) {
        switch(unit) {
        case .Kilogram:
            mode = Mode.Kilogram
            break
        case .Pound:
            mode = Mode.Pound
            break
        }
    }

    func compose() -> Data {
        var data = Data()
        data.append(0x03)
        data.append(0x00)
        data.append(mode.rawValue)
        data.append(0x03+mode.rawValue) // maybe checksum
        return data
    }
}
