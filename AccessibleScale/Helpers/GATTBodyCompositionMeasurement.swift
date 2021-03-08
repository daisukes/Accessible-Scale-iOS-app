//
//  GATTBodyCompositionMeasurement.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation

struct GATTBodyCompositionMeasurement {

    let measurementUnit: ScaleUnit
    let fatPercentage: Double
    let timestamp: Date?
    let userID: UInt8?
    let basalMetabolism: Double?
    let musclePercentage: Double?
    let muscleMass: Double?
    let fatFreeMass: Double?
    let softLeanMass: Double?
    let bodyWaterMass: Double?
    let impedance: Double?
    let weight: Double?
    let height: Double?
    let multiplePacket: Bool

    let measurementUnitBit = 1
    let timestampBit = 2
    let userIDBit = 3
    let basalMetabolismBit = 4
    let musclePercentageBit = 5
    let muscleMassBit = 6
    let fatFreeMassBit = 7
    let softLeanMassBit = 8
    let bodyWaterMassBit = 9
    let impedanceBit = 10
    let weightBit = 11
    let heightBit = 12
    let multiplePacketBit = 13


    let boneMass: Double?
    let subcutaneousFat: Double?
    let protein: Double?
    let metabolicAge: Int?
    let customBit = 15

    // 7E 53 8C 00 E5 07 02 14 06 25 26 03 2D 06 2C 02 2A 04 62 04 6D 02 F9 01 F0 01 38 00 04 7E 00 C4 00 23 00 BE 03 04 00
    // 7E 53 8B 00 E5 07 02 14 06 13 30 03 2C 06 2C 02 28 04 60 04 6E 02 FD 01 FB 01 38 00 04 7D 00 C4 00 23 00 BC 03 04 00
    // 7E 53 06 01 E5 07 03 07 0F 15 28 04 1E 05 AE 01 32 03 66 03 FA 01 FE 01 F4 01 34 00 04 F6 00 AE 00 3B 00 96 03 04 00
    // 7E 53: 0101001101111110 (unknown: 0 1 0, mp: 1, height: 0, weight: 0, imp: 1, bwm: 1, flm: 0, ffm: 1, mm: 1, mp: 1, bm: 1, userID: 1, timestamp: 1, unit: 0)
    // 06 01: fat percentage (factor=0.1) 262 = 26.2%
    // E5 07 03 07 0F 15 28: timestamp
    // 04: userid
    // 1E 05: bm 1310
    // AE 01: mp 430 = 43.0%
    // 32 03: mm 818 = 40.9kg
    // 66 03: ffm 870 = 43.5kg
    // FA 01: bwm 506 = 25.3kg  -  presented as % (50.6)
    // FE 01: imp, 510 Ohm
    //
    // F4 01 34 00 04 F6 00 AE 00 3B 00 96 03 04 00: unknown remaining data
    // F4 01: 500       - another impedance?
    // 34 00: 52   2.6  - bone mass
    // 04:              - visceral fat?
    // F6 00: 246  24.6 - subcutaneous fat
    // AE 00: 174  17.4 - protein
    // 3B 00: 59        - metabolic age
    // 96 03: 918  45.9 - Unknown value?
    // 04 00: 4         - visceral fat?

    init(data: Data) {
        var index = 0
        let flag = GATTUtil.uint16(data, &index)
        let length = data.count

        measurementUnit = GATTUtil.flag(flag, measurementUnitBit) ? ScaleUnit.Pound : ScaleUnit.Kilogram
        let massFactor = GATTUtil.flag(flag, measurementUnitBit) ? 0.01 : 0.05
        let percentFactor = 0.1
        let heightFactor = GATTUtil.flag(flag, measurementUnitBit) ? 0.01 : 1

        fatPercentage = Double(GATTUtil.uint16(data, &index)) * percentFactor
        multiplePacket = GATTUtil.flag(flag, multiplePacketBit)

        timestamp =        (GATTUtil.flag(flag, timestampBit) && index + 7 < length) ?        GATTDate(data: data, start: &index).date : nil
        userID =           (GATTUtil.flag(flag, userIDBit) && index + 1 < length) ?           GATTUtil.uint8(data, &index) : nil
        basalMetabolism =  (GATTUtil.flag(flag, basalMetabolismBit) && index + 2 < length) ?  Double(GATTUtil.uint16(data, &index)) : nil
        musclePercentage = (GATTUtil.flag(flag, musclePercentageBit) && index + 2 < length) ? Double(GATTUtil.uint16(data, &index)) * percentFactor : nil
        muscleMass =       (GATTUtil.flag(flag, muscleMassBit) && index + 2 < length) ?       Double(GATTUtil.uint16(data, &index)) * massFactor : nil
        fatFreeMass =      (GATTUtil.flag(flag, fatFreeMassBit) && index + 2 < length) ?      Double(GATTUtil.uint16(data, &index)) * massFactor : nil
        softLeanMass =     (GATTUtil.flag(flag, softLeanMassBit) && index + 2 < length) ?     Double(GATTUtil.uint16(data, &index)) * massFactor : nil
        bodyWaterMass =    (GATTUtil.flag(flag, bodyWaterMassBit) && index + 2 < length) ?    Double(GATTUtil.uint16(data, &index)) * massFactor : nil
        impedance =        (GATTUtil.flag(flag, impedanceBit) && index + 2 < length) ?        Double(GATTUtil.uint16(data, &index)) : nil
        weight =           (GATTUtil.flag(flag, weightBit) && index + 2 < length) ?           Double(GATTUtil.uint16(data, &index)) * massFactor : nil
        height =           (GATTUtil.flag(flag, heightBit) && index + 2 < length) ?           Double(GATTUtil.uint16(data, &index)) * heightFactor : nil

        _ =               (GATTUtil.flag(flag, customBit) && index + 2 < length) ?         Double(GATTUtil.uint16(data, &index)) : nil
        boneMass =        (GATTUtil.flag(flag, customBit) && index + 2 < length) ?         Double(GATTUtil.uint16(data, &index)) : nil
        _ =               (GATTUtil.flag(flag, customBit) && index + 1 < length) ?         GATTUtil.uint8(data, &index) : nil
        subcutaneousFat = (GATTUtil.flag(flag, customBit) && index + 2 < length) ?         Double(GATTUtil.uint16(data, &index)) * percentFactor : nil
        protein =         (GATTUtil.flag(flag, customBit) && index + 2 < length) ?         Double(GATTUtil.uint16(data, &index)) * percentFactor : nil
        metabolicAge =    (GATTUtil.flag(flag, customBit) && index + 2 < length) ?         Int(GATTUtil.uint16(data, &index)) : nil
        // three more bytes
    }
}
