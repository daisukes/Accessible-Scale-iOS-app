//
//  ModelDataTypes.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/22/21.
//

import Foundation
import HealthKit

enum ScaleUnit: String {
    case Kilogram = "kilo grams"
    case Pound = "pounds"

    func label() -> String {
        switch(self) {
        case ScaleUnit.Kilogram:
            return "kg"
        case ScaleUnit.Pound:
            return "lb"
        }
    }

    static let poundToKilogram = UnitConverterLinear(coefficient: 2.20462)

    static func toPound(kilogram: Double) -> Double {
        return poundToKilogram.baseUnitValue(fromValue: kilogram)
    }

    static func toKilogram(pound: Double) -> Double {
        return poundToKilogram.value(fromBaseUnitValue: pound)
    }

    static let inchToCm = UnitConverterLinear(coefficient: 2.54)

    static func toInch(cm: Double) -> Double {
        return inchToCm.baseUnitValue(fromValue: cm)
    }

    static func toCm(inch: Double) -> Double {
        return inchToCm.value(fromBaseUnitValue: inch)
    }

    static func length(_ value:Double, from:ScaleUnit, to:ScaleUnit) -> Double {
        if from == .Kilogram && to == .Pound {
            return toInch(cm: value)
        }
        if from == .Pound && to == .Kilogram {
            return toCm(inch: value)
        }
        return value
    }
}

enum MeasurementTypeIdentifier: String {
    case weight = "weight"
    case fatPercentage = "fatPercentage"
    case bodyMassIndex = "bodyMassIndex"
    case basalMetabolism = "basalMetabolism"
    case musclePercentage = "musclePercentage"
    case muscleMass = "muscleMass"
    case fatFreeMass = "fatFreeMass"
    case softLeanMass = "softLeanMass"
    case bodyWaterMass = "bodyWaterMass"
    case impedance = "impedance"
}

struct Measurement {
    var measurementUnit: ScaleUnit?
    var weight: Double?
    var fatPercentage: Double?
    var bodyMassIndex: Double?
    var basalMetabolism: Double?
    var musclePercentage: Double?
    var muscleMass: Double?
    var fatFreeMass: Double?
    var softLeanMass: Double?
    var bodyWaterMass: Double?
    var impedance: Double?
}

extension Measurement {
    func weight(inUnit: ScaleUnit) -> Double {
        return value(weight ?? 0, inUnit: inUnit)
    }
    func muscleMass(inUnit: ScaleUnit) -> Double {
        return value(muscleMass ?? 0, inUnit: inUnit)
    }
    func fatFreeMass(inUnit: ScaleUnit) -> Double {
        return value(fatFreeMass ?? 0, inUnit: inUnit)
    }
    func softLeanMass(inUnit: ScaleUnit) -> Double {
        return value(softLeanMass ?? 0, inUnit: inUnit)
    }
    func bodyWaterMass(inUnit: ScaleUnit) -> Double {
        return value(bodyWaterMass ?? 0, inUnit: inUnit)
    }

    func value(_ value: Double, inUnit: ScaleUnit) -> Double {
        if measurementUnit != inUnit {
            if inUnit == .Kilogram {
                return ScaleUnit.toKilogram(pound: value)
            }
            if inUnit == .Pound{
                return ScaleUnit.toPound(kilogram: value)
            }
        }
        return value
    }

    func value(_ value: Double, inHKUnit: HKUnit) -> Double {
        switch(inHKUnit) {
        case .gram():
            return self.value(value, inUnit: .Kilogram) * 1000
        case .percent():
            return value / 100
        default:
            return value
        }
    }

    func value(forKey: MeasurementTypeIdentifier, inHKUnit: HKUnit) -> Double {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if forKey.rawValue == child.label {
                if let childValue = child.value as? Double {
                    return self.value(childValue, inHKUnit: inHKUnit)
                }
            }
        }
        // no value
        return 0
    }
}

enum Gender: String {
    case Male = "Male"
    case Female = "Female"
    case Unknown = "Unknown"
}

enum DisplayedScene {
    case Onboard
    case Scale
}

enum GrantState {
    case Init
    case Granted
    case Denied
    case Off
}

