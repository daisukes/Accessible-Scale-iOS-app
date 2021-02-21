//
//  GATTBase.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation

class GATTUtil {
    static func flag<T: UnsignedInteger>(_ byte: T, _ bit: Int) -> Bool {
        let mask = 1 << (bit - 1)
        return (byte & T(mask)) == T(mask)
    }

    static func uint8(_ data: Data, _ start: inout Int) -> UInt8 {
        let i1 = start
        start += 1
        return data[i1]
    }

    static func uint16(_ data: Data, _ start:inout Int) -> UInt16 {
        let i1 = start
        let i2 = start+1
        start += 2
        return uint16(data[i1], data[i2])
    }

    // little endian
    static func uint16(_ b1: UInt8, _ b2: UInt8) -> UInt16 {
        return UInt16(b1) + UInt16(b2) * 256
    }

    static func uint32(_ data: Data, _ start:inout Int) -> UInt32 {
        let i1 = start
        let i2 = start+1
        let i3 = start+2
        let i4 = start+3
        start += 4
        return uint32(data[i1], data[i2], data[i3], data[i4])
    }

    // little endian
    static func uint32(_ b1: UInt8, _ b2: UInt8, _ b3: UInt8, _ b4: UInt8) -> UInt32 {
        return UInt32(b1) | UInt32(b2) << 8 | UInt32(b3) << 16 | UInt32(b4) << 24
    }

    static func append(_ data: inout Data, _ item: UInt8) {
        data.append(item)
    }

    static func append(_ data: inout Data, _ item: UInt16) {
        data.append(UInt8(item & 0xFF))
        data.append(UInt8(item >> 8))
    }
}

struct GATTDate {
    let date: Date

    let year: UInt16
    let month: UInt8
    let day: UInt8
    let hour: UInt8
    let minute: UInt8
    let second: UInt8

    init(data:Data) {
        var index = 0
        year = GATTUtil.uint16(data, &index)
        month = GATTUtil.uint8(data, &index)
        day = GATTUtil.uint8(data, &index)
        hour = GATTUtil.uint8(data, &index)
        minute = GATTUtil.uint8(data, &index)
        second = GATTUtil.uint8(data, &index)

        date = SimpleDate.makeDate(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    }

    init(data:Data, start: inout Int) {
        let s = start
        let e = start+7
        start = e
        self.init(data: data.subdata(in: Data.Index(s)..<Data.Index(e)))
    }

    init(date: Date) {
        self.date = date
        let components = SimpleDate.makeComponent(date: date)
        year = UInt16(components.year!)
        month = UInt8(components.month!)
        day = UInt8(components.day!)
        hour = UInt8(components.hour!)
        minute = UInt8(components.minute!)
        second = UInt8(components.second!)
    }

    func compose() -> Data {
        var data = Data()
        GATTUtil.append(&data, year)
        data.append(month)
        data.append(day)
        data.append(hour)
        data.append(minute)
        data.append(second)
        return data
    }
}
