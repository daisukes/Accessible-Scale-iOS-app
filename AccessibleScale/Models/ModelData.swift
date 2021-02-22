//
//  ModelData.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import Foundation
import CoreData
import CoreBluetooth
import UserNotifications
import Combine

struct Measurement {
    var measurementUnit: ScaleUnit?
    var weight: Double?
    var fatPercentage: Double?
    var bodyMassIndex: Double?
    var basalMetabolism: Int?
    var musclePercentage: Double?
    var muscleMass: Double?
    var fatFreeMass: Double?
    var softLeanMass: Double?
    var bodyWaterMass: Double?
    var impedance: Int?
}

extension Measurement {
    func value(forKey: String, inUnit: ScaleUnit) -> Double {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if child.label == forKey {
                if let value = child.value as? Double {
                    if measurementUnit != inUnit {
                        if inUnit == .Kilogram {
                            return ScaleUnit.toKilogram(pound: value)
                        }
                        if inUnit == .Pound{
                            return ScaleUnit.toPound(kilogram: value)
                        }
                    } else {
                        return value
                    }
                }
            }
        }
        return 0
    }
}

final class ModelData: ObservableObject {
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var notificationState: GrantState = .Init
    @Published var healthKitState: GrantState = .Init

    @Published var connected: Bool = false
    @Published var userRegistered: Bool = false

    @Published var unit: ScaleUnit = .Kilogram
    @Published var height: Int = 165
    @Published var date_of_birth: Date = SimpleDate.date19700101
    @Published var gender: Gender = Gender.Female

    @Published var measurement = Measurement()

    @Published var displayedScene: DisplayedScene = .Onboard

    // Core Data
    var bodyMeasurementData: BodyMeasurement?
    var lastWeightNotify: TimeInterval = 0

    var viewContext: NSManagedObjectContext!
    lazy var userHelper: UserHelper? = UserHelper(context: viewContext)
    private var cancellableSet: Set<AnyCancellable> = []

    // ToDo: can be cleaner
    private var heightUnitChanged: AnyPublisher<Int, Never> {
        $unit
            .map { input in
                return Int(round(ScaleUnit.length(Double(self.height), from: input, to: self.unit)))
            }
            .eraseToAnyPublisher()
    }

    convenience init() {
        self.init(viewContext: PersistenceController.shared.container.viewContext)
    }

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        checkUser()
        if let user = mainUser() {
            unit = ScaleUnit(rawValue: user.unit!)!
            height = Int(user.height)
            date_of_birth = user.date_of_birth!
            gender = Gender(rawValue: user.gender!)!
        }

        heightUnitChanged
            .receive(on: RunLoop.main)
            .assign(to: \.height, on: self)
            .store(in: &cancellableSet)
    }

    func weightInUserUnit() -> Double {
        measurement.value(forKey: "weight", inUnit: unit)
    }

    func localizedWeightString() -> String {
        let weight = measurement.weight ?? 0
        return String(format: "%.1f %@", weight, unit.rawValue)
    }

    func localizedFatString() -> String {
        let fatPercentage = measurement.fatPercentage ?? 0
        return String(format: "%.1f %%", fatPercentage)
    }

    func localizedWeightFatString() -> String {
        return String(format: "%@, %@", localizedWeightString(), localizedFatString())
    }

    func prepareBodyMeasurement() -> BodyMeasurement? {
        let now = Date()
        if let bodyMeasurement = self.bodyMeasurementData {
            if let timestamp = bodyMeasurement.timestamp {
                if now.timeIntervalSince(timestamp) > 10 {
                    self.bodyMeasurementData = nil
                }
            }
        }

        if self.bodyMeasurementData == nil {
            bodyMeasurementData = BodyMeasurement(context: self.viewContext)
            bodyMeasurementData!.timestamp = now
        }
        return bodyMeasurementData
    }

    // MARK: User related functions

    func checkUser() {
        if let userHelper = self.userHelper {
            displayedScene = userHelper.count() > 0 ? .Scale : .Onboard
        }
    }

    func users() -> [User] {
        guard let userHelper = userHelper else {
            return []
        }
        do {
            return try userHelper.getRows() as! [User]
        } catch {
        }
        return []
    }

    func mainUser() -> User? {
        let users = self.users()
        if users.count > 0 {
            return users[0]
        }
        return nil
    }

    func createUser() -> User? {
        let user = User(context: self.viewContext)
        user.unit = unit.rawValue
        user.height = Int16(height)
        user.date_of_birth = date_of_birth
        user.gender = gender.rawValue

        do {
            try viewContext.save()
            return user
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return nil
    }

    func saveUser() {
        let users = self.users()
        let user = users[0]
        var changed = false
        if user.unit != unit.rawValue {
            user.unit = unit.rawValue
            changed = true
        }
        if user.height != height {
            user.height = Int16(height)
            changed = true
        }
        if user.date_of_birth != date_of_birth {
            user.date_of_birth = date_of_birth
            changed = true
        }
        if user.gender != gender.rawValue {
            user.gender = gender.rawValue
            changed = true
        }
        if changed {
            user.written = false
            do {
                print("saving change")
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

}

// MARK: Enums and Utilities

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

class SimpleDate: DateFormatter {
    override init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    static func makeDate(year: UInt16, month: UInt8, day: UInt8,
                         hour: UInt8, minute: UInt8, second: UInt8) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: Int(year), month: Int(month), day: Int(day),
                                        hour: Int(hour), minute: Int(minute), second: Int(second))
        return calendar.date(from: components)!
    }

    static func makeComponent(date: Date) -> DateComponents {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    static func age(from: Date) -> UInt8 {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: from, to: now)
        return UInt8(ageComponents.year!)
    }

    static let date19700101: Date = SimpleDate().date(from: "1970-01-01")!
}


class SimpleDateTime: DateFormatter {
    override init() {
        super.init()
        self.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
