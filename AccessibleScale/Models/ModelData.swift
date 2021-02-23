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
import HealthKit
import os.log


final class ModelData: ObservableObject {

    // authorization status
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var notificationState: GrantState = .Init
    @Published var healthKitState: GrantState = .Init

    // app status
    @Published var connected: Bool = false
    @Published var userRegistered: Bool = false
    @Published var displayedScene: DisplayedScene = .Onboard

    // user preference
    @Published var unit: ScaleUnit = .Kilogram
    @Published var height: Int = 165
    @Published var date_of_birth: Date = SimpleDate.date19700101
    @Published var gender: Gender = Gender.Female
    @Published var user: User?

    // measurement
    @Published var measurement = Measurement()
    @Published var lastUpdated: Date = Date()

    // Core Data
    var viewContext: NSManagedObjectContext!
    var bodyMeasurementData: BodyMeasurement?
    lazy var userHelper: UserHelper? = UserHelper(context: viewContext)

    // Notification
    var lastWeightNotify: TimeInterval = 0

    // Unit conversion based on preference
    private var cancellableSet: Set<AnyCancellable> = []

    private var heightUnitChanged: AnyPublisher<Int, Never> {
        $unit
            .map { input in
                return Int(round(ScaleUnit.length(Double(self.height), from: input, to: self.unit)))
            }
            .eraseToAnyPublisher()
    }

    // MARK: Initializer
    convenience init() {
        self.init(viewContext: PersistenceController.shared.container.viewContext)
    }

    init(viewContext: NSManagedObjectContext) {
        os_log("initialize viewContext %@", log:.data, viewContext)
        self.viewContext = viewContext

        // show onboard view if there is no user
        if let userHelper = self.userHelper {
            displayedScene = userHelper.count() > 0 ? .Scale : .Onboard
        }
        // get main user
        if let user = mainUser() {
            unit = ScaleUnit(rawValue: user.unit!)!
            height = Int(user.height)
            date_of_birth = user.date_of_birth!
            gender = Gender(rawValue: user.gender!)!
            self.user = user
        }

        // set unit change event
        heightUnitChanged
            .receive(on: RunLoop.main)
            .assign(to: \.height, on: self)
            .store(in: &cancellableSet)
    }

    func weightInUserUnit() -> Double {
        measurement.weight(inUnit: unit)
    }

    // TODO Localize
    func localizedWeightString() -> String {
        let weight = measurement.weight(inUnit: unit)
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
        let bodyMeasurementData = BodyMeasurement(context: self.viewContext)
        bodyMeasurementData.timestamp = Date()
        return bodyMeasurementData
    }

    func scaleConnected() {
        os_log("Scale Connected", log:.connection)
        connected = true
        lastWeightNotify = 0
    }

    func scaleDisconnected() {
        os_log("Scale Disconnected", log:.connection)
        updateCoreDataAndHealthKit()
        connected = false
        measurement = Measurement()
    }

    func updated(weight: GATTWeightMeasurement) {
        measurement.measurementUnit = weight.measurementUnit
        measurement.weight = weight.weight
        measurement.bodyMassIndex = weight.bmi ?? 0
    }

    func updated(bodyComposition: GATTBodyCompositionMeasurement) {
        measurement.fatPercentage = bodyComposition.fatPercentage
        measurement.basalMetabolism = bodyComposition.basalMetabolism
        measurement.bodyWaterMass = bodyComposition.bodyWaterMass
        measurement.fatFreeMass = bodyComposition.fatFreeMass
        measurement.impedance = bodyComposition.impedance
        measurement.muscleMass = bodyComposition.muscleMass
        measurement.musclePercentage = bodyComposition.musclePercentage
        measurement.softLeanMass = bodyComposition.softLeanMass
    }


    // MARK: User related functions

    private func users() -> [User] {
        guard let userHelper = userHelper else {
            return []
        }
        do {
            return try userHelper.getRows() as! [User]
        } catch {
        }
        return []
    }

    private func mainUser() -> User? {
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

        self.user = user

        do {
            try viewContext.save()
            return user
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            os_log("Unresolved error \(nsError), \(nsError.userInfo)")
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
            saveCoreData()
        }
    }

    // MARK: CoreData and HealthKit

    func saveCoreData() {
        do {
            os_log("saving change", log:.data)
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            os_log("Unresolved error %@, %@", log:.error, nsError, nsError.userInfo)
        }
        lastUpdated = Date()
    }

    func delete(data: BodyMeasurement) {
        if let entries = data.stored_entries?.allObjects as? [StoredEntry] {
            let healthStore = HKHealthStore()

            for entry in entries {
                if let uuid = entry.uuid {
                    let predicate = HKQuery.predicateForObject(with: uuid)

                    for type in allHKTypes() {
                        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
                            if let samples = samples {
                                for sample in samples {
                                    healthStore.delete(sample) {_,_ in

                                    }
                                }
                            }
                        }
                        healthStore.execute(query)
                    }
                }
            }
        }
        data.user = nil
        self.viewContext.delete(data)
    }

    struct Mapping {
        var typeIdentifier: MeasurementTypeIdentifier
        var hkunit: HKUnit
    }

    private let dataMapping: [HKQuantityTypeIdentifier: Mapping] =
        [
            .bodyMass: Mapping(typeIdentifier: .weight, hkunit: .gram()),
            .bodyFatPercentage: Mapping(typeIdentifier: .fatPercentage, hkunit: .percent()),
            // this should not be synch with Apple Health, because this value estimates basal energy for a day
            // but Apple Health assumes that the value is a for a short time frame, usually provided by phone or watch
            //.basalEnergyBurned: Mapping(typeIdentifier: .basalMetabolism, hkunit: .kilocalorie()),
            .bodyMassIndex: Mapping(typeIdentifier: .bodyMassIndex, hkunit: .count()),
            .leanBodyMass: Mapping(typeIdentifier: .fatFreeMass, hkunit: .gram())
        ]

    private func allHKTypes() -> Set<HKSampleType> {
        Set(dataMapping.map { (key, value) -> HKSampleType in
            HKObjectType.quantityType(forIdentifier: key)!
        })
    }

    func authorizeHealthkit() {
        if HKHealthStore.isHealthDataAvailable() {
            let healthStore = HKHealthStore()

            let allTypes = allHKTypes()

            healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
                // todo
                // this returns sucess even if the user denied

                DispatchQueue.main.async {
                    self.healthKitState = success ? .Granted : .Denied
                }
                if !success {

                }
            }
        }
    }

    func updateCoreDataAndHealthKit() {
        guard measurement.weight ?? 0 > 0 else { return }
        guard let user = user else { return }
        guard let bodyMeasurement = prepareBodyMeasurement() else { return }

        os_log("updateCoreData", log:.data)

        bodyMeasurement.user = user
        bodyMeasurement.unit = unit.rawValue
        bodyMeasurement.weight = measurement.weight(inUnit: unit)
        bodyMeasurement.body_mass_index = measurement.bodyMassIndex ?? 0

        bodyMeasurement.fat_percentage = measurement.fatPercentage ?? 0
        bodyMeasurement.basal_metabolism = Int32(measurement.basalMetabolism ?? 0)
        bodyMeasurement.body_water_mass = measurement.bodyWaterMass(inUnit: unit)
        bodyMeasurement.fat_free_mass = measurement.fatFreeMass(inUnit: unit)
        bodyMeasurement.impedance = Int32(measurement.impedance ?? 0)
        bodyMeasurement.muscle_mass = measurement.muscleMass(inUnit: unit)
        bodyMeasurement.muscle_percentage = measurement.musclePercentage ?? 0
        bodyMeasurement.soft_lean_mass = measurement.softLeanMass(inUnit: unit)

        let healthStore = HKHealthStore()
        let now = Date()

        os_log("updateHealthKit", log:.data)

        // do not save if .CompositeMeasured comes first
        dataMapping.forEach { identifier, mapping in
            let type = HKObjectType.quantityType(forIdentifier: identifier)!
            let status = healthStore.authorizationStatus(for: type)
            if status == .sharingAuthorized {
                let hkunit = mapping.hkunit
                let value = measurement.value(forKey: mapping.typeIdentifier, inHKUnit: hkunit)
                if value > 0 {
                    let quantity = HKQuantity(unit: hkunit, doubleValue: value)
                    let sample = HKQuantitySample(type: type, quantity: quantity, start: now, end: now)
                    healthStore.save(sample) { (success, error) in
                    }

                    let entry = StoredEntry(context: viewContext)
                    entry.uuid = sample.uuid
                    entry.measurement = bodyMeasurement
                }
            }
        }
        // to save Health data UUID entries
        saveCoreData()
    }
}
