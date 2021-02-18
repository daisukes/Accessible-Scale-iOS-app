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

final class ModelData: ObservableObject {
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var notificationState: NotificationCenterState = .Init
    @Published var connected: Bool = false
    @Published var userRegistered: Bool = false
    @Published var weight: Float = 0
    @Published var fat: Float = 0
    @Published var unit: ScaleUnit = .Kilogram
    @Published var displayedScene: DisplayedScene = .Onboard

    @Published var date_of_birth: Date = SimpleDate.date19700101
    @Published var height: Int = 165
    @Published var gender: Gender = Gender.Female

    private var cancellableSet: Set<AnyCancellable> = []

    // ToDo: can be cleaner
    private var heightUnitChanged: AnyPublisher<Int, Never> {
        $unit
            .map { input in
                let unit = self.unit
                let height = self.height

                if input == .Pound && unit == .Kilogram {
                    print(Int(round(Double(height) / 2.54)))
                    return Int(round(Double(height) / 2.54))
                }
                if input == .Kilogram && unit == .Pound {
                    print(Int(round(Double(height) * 2.54)))
                    return Int(round(Double(height) * 2.54))
                }
                return height
            }
            .eraseToAnyPublisher()
    }
    private var weightUnitChanged: AnyPublisher<Float, Never> {
        $unit
            .map { input in
                let unit = self.unit
                let weight = self.weight

                if input == .Pound && unit == .Kilogram {
                    print(round(weight / 0.453592))
                    return round(weight / 0.453592)
                }
                if input == .Kilogram && unit == .Pound {
                    print(round(weight * 0.453592))
                    return round(weight * 0.453592)
                }
                return weight
            }
            .eraseToAnyPublisher()
    }



    var viewContext: NSManagedObjectContext!
    lazy var userHelper: UserHelper? = UserHelper(context: viewContext)

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
        weightUnitChanged
            .receive(on: RunLoop.main)
            .assign(to: \.weight, on: self)
            .store(in: &cancellableSet)
    }

    func localizedWeightString() -> String {
        return String(format: "%.1f %@", weight, unit.rawValue)
    }

    func localizedFatString() -> String {
        return String(format: "%.1f %%", fat)
    }

    func save() {
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

enum NotificationCenterState {
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
