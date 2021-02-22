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
