//
//  ModelData.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import Foundation

final class ModelData: ObservableObject {
    @Published var viewData: ViewData = ViewData()
}

enum Unit: String {
    case KiloGram = "kilo grams"
    case Pound = "pounds"

    func label() -> String {
        switch(self) {
        case Unit.KiloGram:
            return "kg"
        case Unit.Pound:
            return "lb"
        }
    }
}

struct ViewData {
    var weight: Float = 0
    var fat: Float = 0
    var unit: Unit = .KiloGram

    func localizedWeightString() -> String {
        return String(format: "%.1f %@", weight, unit.rawValue)
    }
    func localizedFatString() -> String {
        return String(format: "%.1f %", fat)
    }
}
