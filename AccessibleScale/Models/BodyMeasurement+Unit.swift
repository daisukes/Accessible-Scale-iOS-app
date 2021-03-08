//
//  BodyMeasurement+Unit.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/22/21.
//

import Foundation


extension BodyMeasurement{

    func weight(inUnit: ScaleUnit) -> Double {
        return value(weight, inUnit: inUnit)
    }
    func muscle_mass(inUnit: ScaleUnit) -> Double {
        return value(muscle_mass, inUnit: inUnit)
    }
    func fat_free_mass(inUnit: ScaleUnit) -> Double {
        return value(fat_free_mass, inUnit: inUnit)
    }
    func soft_lean_mass(inUnit: ScaleUnit) -> Double {
        return value(soft_lean_mass, inUnit: inUnit)
    }
    func body_water_mass(inUnit: ScaleUnit) -> Double {
        return value(body_water_mass, inUnit: inUnit)
    }
    func bone_mass(inUnit: ScaleUnit) -> Double {
        return value(bone_mass, inUnit: inUnit)
    }

    func value(_ value: Double, inUnit: ScaleUnit) -> Double {
        if let raw_unit = unit {
            if let base_unit = ScaleUnit(rawValue: raw_unit) {
                if base_unit != inUnit {
                    if inUnit == .Kilogram {
                        return ScaleUnit.toKilogram(pound: value)
                    }
                    if inUnit == .Pound{
                        return ScaleUnit.toPound(kilogram: value)
                    }
                }
            }
        }
        return value
    }
}
