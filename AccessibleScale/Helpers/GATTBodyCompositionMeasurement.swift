//
//  GATTBodyCompositionMeasurement.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation

struct GATTBodyCompositionMeasurement {

    let measurementUnit: ScaleUnit
    let fatPercentage: Float
    let timestamp: Date?
    let userID: UInt8?
    let baselMetabolism: UInt16?
    let musclePercentage: Float?
    let muscleMass: Float?
    let fatFreeMass: Float?
    let softLeanMass: Float?
    let bodyWaterMass: Float?
    let impedance: UInt16?
    let weight: Float?
    let height: Float?
    let multiplePacket: Bool

    let measurementUnitBit = 1
    let timestampBit = 2
    let userIDBit = 3
    let baselMetabolismBit = 4
    let musclePercentageBit = 5
    let muscleMassBit = 6
    let fatFreeMassBit = 7
    let softLeanMassBit = 8
    let bodyWaterMassBit = 9
    let impedanceBit = 10
    let weightBit = 11
    let heightBit = 12
    let multiplePacketBit = 13


    init(data: Data) {
        var index = 0
        let flag = GATTUtil.uint16(data, &index)
        let length = data.count

        measurementUnit = GATTUtil.flag(flag, measurementUnitBit) ? ScaleUnit.Pound : ScaleUnit.Kilogram
        let massFactor = GATTUtil.flag(flag, measurementUnitBit) ? Float(0.01) : Float(0.05)
        let percentFactor = Float(0.1)
        let heightFactor = GATTUtil.flag(flag, measurementUnitBit) ? Float(0.01) : Float(1)

        fatPercentage = GATTUtil.float16(data, &index) * percentFactor
        multiplePacket = GATTUtil.flag(flag, multiplePacketBit)

        timestamp =        (GATTUtil.flag(flag, timestampBit) && index + 7 < length) ?        GATTDate(data: data, start: &index).date : nil
        userID =           (GATTUtil.flag(flag, userIDBit) && index + 1 < length) ?           GATTUtil.uint8(data, &index) : nil
        baselMetabolism =  (GATTUtil.flag(flag, baselMetabolismBit) && index + 2 < length) ?  GATTUtil.uint16(data, &index) : nil
        musclePercentage = (GATTUtil.flag(flag, musclePercentageBit) && index + 2 < length) ? GATTUtil.float16(data, &index) * percentFactor : nil
        muscleMass =       (GATTUtil.flag(flag, muscleMassBit) && index + 2 < length) ?       GATTUtil.float16(data, &index) * massFactor : nil
        fatFreeMass =      (GATTUtil.flag(flag, fatFreeMassBit) && index + 2 < length) ?      GATTUtil.float16(data, &index) * massFactor : nil
        softLeanMass =     (GATTUtil.flag(flag, softLeanMassBit) && index + 2 < length) ?     GATTUtil.float16(data, &index) * massFactor : nil
        bodyWaterMass =    (GATTUtil.flag(flag, bodyWaterMassBit) && index + 2 < length) ?    GATTUtil.float16(data, &index) * massFactor : nil
        impedance =        (GATTUtil.flag(flag, impedanceBit) && index + 2 < length) ?        GATTUtil.uint16(data, &index) : nil
        weight =           (GATTUtil.flag(flag, weightBit) && index + 2 < length) ?           GATTUtil.float16(data, &index) * massFactor : nil
        height =           (GATTUtil.flag(flag, heightBit) && index + 2 < length) ?           GATTUtil.float16(data, &index) * heightFactor : nil
    }
}