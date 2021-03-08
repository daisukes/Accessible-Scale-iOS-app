//
//  GATTWeightMeasurement.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation

struct GATTWeightMeasurement {

    let measurementUnit: ScaleUnit
    let weight: Double
    let timestamp: Date?
    let userID: UInt8?
    let bmi: Double?

    let measurementUnitBit = 1
    let timestampBit = 2
    let userIDBit = 3
    let bmiBit = 4

}

//0E       16 05 E5 07 02 14 07 19 38 03 00 00 00 00
//0E = 00001110 (bmiBit: 1, userIDBit: 1, timestampBit: 1, unitBit: 0 = kilogram, factor=0.05)
//16 05 = 05*256 + 16 = 1302 = 1302*0.05 = 65.1
//E5 07 = 2021 (year), 02 = 02 (month), 14 = 20 (day), 07 =07 (hour), 19 = 25 (min), 38 = 56 (sec)
//03 = userID 03
//2E 16 05 E5 07 02 14 07 16 1B 03 F8 00 A2 00
//2E = 00101110 (unknownbit: 1 0, bmiBit: 1, userIDBit: 1, timestampBit: 1, unitBit: 0 = kilogram, factor=0.05)
//F8 00: BMI = 248 * 0.1 (factor) = 24.8
//A2 00: maybe height = 162

extension GATTWeightMeasurement {
    init(data: Data) {
        var index = 0
        let flag = GATTUtil.uint8(data, &index)
        let length = data.count
        
        measurementUnit = GATTUtil.flag(flag, measurementUnitBit) ? ScaleUnit.Pound : ScaleUnit.Kilogram
        let massFactor = GATTUtil.flag(flag, measurementUnitBit) ? 0.01 : 0.05
        let bmiFactor = 0.1

        weight =     Double(GATTUtil.uint16(data, &index)) * massFactor
        timestamp = (GATTUtil.flag(flag, timestampBit) && index + 7 < length) ? GATTDate(data: data, start: &index).date : nil
        userID =    (GATTUtil.flag(flag, userIDBit) && index + 1 < length) ?    GATTUtil.uint8(data, &index) : nil
        bmi =       (GATTUtil.flag(flag, bmiBit) && index + 2 < length) ?       Double(GATTUtil.uint16(data, &index)) * bmiFactor : nil
    }
}
