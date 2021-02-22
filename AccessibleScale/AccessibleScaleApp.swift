//
//  AccessibleScaleApp.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import CoreBluetooth
import HealthKit

@main
struct AccessibleScaleApp: App, ScaleDelegate {
    @Environment(\.scenePhase) var scenePhase

    let scale = Scale.shared
    var center = UNUserNotificationCenter.current()
    var modelData: ModelData = ModelData()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(modelData)
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                scale.delegate = self
                self.initNotification()
                break
            @unknown default:
                break
            }
        }
    }

    func initNotification() {
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                     actions: [],
                                                     intentIdentifiers: [],
                                                     options: [.allowAnnouncement])
        center.setNotificationCategories([generalCategory])
    }

    // MARK: ScaleDelegate

    func updated(bluetoothState: CBManagerState) {
        modelData.bluetoothState = bluetoothState
    }

    func updated(state: Scale.State) {
        switch(state) {
        case .UserRegistered:
            modelData.userRegistered = true
            break
        case .Connected:
            notifyConnected()
            modelData.connected = true
            modelData.measurement = Measurement()
            modelData.lastWeightNotify = 0
            break
        case .NotConnected:
            modelData.connected = false
            break
        case .WeightMeasured:
            notifyMeasurement(state: state)
            updateCoreData(state: state)
            updateHealthKit(state: state)
            break
        case .CompositeMeasured:
            notifyMeasurement(state: state)
            updateCoreData(state: state)
            updateHealthKit(state: state)
            break
        case .Idle:
            break
        }
    }

    func updated(weight: GATTWeightMeasurement) {
        modelData.measurement.measurementUnit = weight.measurementUnit
        modelData.measurement.weight = weight.weight
        modelData.measurement.bodyMassIndex = weight.bmi ?? 0
    }

    func updated(bodyComposition: GATTBodyCompositionMeasurement) {
        modelData.measurement.fatPercentage = bodyComposition.fatPercentage
        modelData.measurement.basalMetabolism = bodyComposition.basalMetabolism.map{Int($0)}
        modelData.measurement.bodyWaterMass = bodyComposition.bodyWaterMass
        modelData.measurement.fatFreeMass = bodyComposition.fatFreeMass
        modelData.measurement.impedance = bodyComposition.impedance.map{Int($0)}
        modelData.measurement.muscleMass = bodyComposition.muscleMass
        modelData.measurement.musclePercentage = bodyComposition.musclePercentage
        modelData.measurement.softLeanMass = bodyComposition.softLeanMass
    }

    // MARK: private functions
    // MARK: Notification

    private func notifyConnected() {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                UIAccessibility.post(notification: .announcement, argument: "Please step on the scale")
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Please step on the scale"
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { (error: Error?) in
                if let theError = error {
                    print(theError.localizedDescription)
                }
            }
        }
    }

    private func notify(_ message:String, sound: UNNotificationSound) {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                UIAccessibility.post(notification: .announcement, argument: message)
                return
            }
            let content = UNMutableNotificationContent()
            content.title = message
            content.sound = sound

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { (error: Error?) in
                if let theError = error {
                    print(theError.localizedDescription)
                }
            }
        }
    }

    private func notifyMeasurement(state: Scale.State) {

        // Weight is measured first
        if state == .WeightMeasured && modelData.measurement.weight ?? 0 > 0 {
            if modelData.measurement.fatPercentage == nil {
                // measured before fat
                let message = modelData.localizedWeightString()
                let sound = UNNotificationSound.default
                notify(message, sound: sound)
                modelData.lastWeightNotify = Date().timeIntervalSince1970
            } else {
                // measured after fat
                let message = modelData.localizedWeightFatString()
                let sound = UNNotificationSound.default
                notify(message, sound: sound)
                modelData.lastWeightNotify = Date().timeIntervalSince1970
            }
        }

        if state == .CompositeMeasured {
            if modelData.measurement.fatPercentage ?? 0 > 0 {
                // Non Error
                if modelData.lastWeightNotify > 0 {
                    // measured after weight
                    let message = modelData.localizedFatString()
                    let sound = UNNotificationSound.default
                    notify(message, sound: sound)
                } else {
                    // measured before weight
                    // do nothing
                }
            } else {
                // Error
                let message = "Fat percentage measurement error"
                let sound = UNNotificationSound.default
                notify(message, sound: sound)
            }
        }
    }

    // MARK: Core Data

    private func updateCoreData(state: Scale.State) {
        guard modelData.measurement.weight ?? 0 > 0 else { return }
        guard let bodyMeasuremnt = modelData.prepareBodyMeasurement() else { return }
        let unit = modelData.unit
        let measurement = modelData.measurement

        if let user = modelData.user {
            bodyMeasuremnt.user = user
        }

        if state == .WeightMeasured {
            bodyMeasuremnt.unit = unit.rawValue
            bodyMeasuremnt.weight = measurement.weight(inUnit: modelData.unit)
            bodyMeasuremnt.body_mass_index = measurement.bodyMassIndex ?? 0
        }

        if state == .CompositeMeasured {
            bodyMeasuremnt.fat_percentage = measurement.fatPercentage ?? 0
            bodyMeasuremnt.basal_metabolism = Int32(measurement.basalMetabolism ?? 0)
            bodyMeasuremnt.body_water_mass = measurement.bodyWaterMass(inUnit: unit)
            bodyMeasuremnt.fat_free_mass = measurement.fatFreeMass(inUnit: unit)
            bodyMeasuremnt.impedance = Int32(measurement.impedance ?? 0)
            bodyMeasuremnt.muscle_mass = measurement.muscleMass(inUnit: unit)
            bodyMeasuremnt.muscle_percentage = measurement.musclePercentage ?? 0
            bodyMeasuremnt.soft_lean_mass = measurement.softLeanMass(inUnit: unit)
        }

        modelData.save()
    }

    // MARK: Apple Healthkit

    private let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    private let fatPercentageType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!

    private func updateHealthKit(state: Scale.State) {
        guard modelData.measurement.weight ?? 0 > 0 else { return }

        if HKHealthStore.isHealthDataAvailable() {
            // Add code to use HealthKit here.
            let healthStore = HKHealthStore()
            let now = Date()

            if state == .WeightMeasured {
                let status = healthStore.authorizationStatus(for: bodyMassType)
                if status == .sharingAuthorized {
                    let unit: HKUnit = (modelData.unit == .Kilogram) ? .gram() : .pound()
                    let value = modelData.measurement.weight(inUnit: modelData.unit) * (modelData.unit == .Kilogram ? 1000 : 1)
                    let weight = HKQuantity(unit: unit, doubleValue: Double(value))
                    let sample = HKQuantitySample(type: bodyMassType, quantity: weight, start: now, end: now)
                    healthStore.save(sample) { (success, error) in
                    }
                }
            }

            if state == .CompositeMeasured {
                let status = healthStore.authorizationStatus(for: fatPercentageType)
                if status == .sharingAuthorized {
                    let unit: HKUnit = .percent()
                    let value = modelData.measurement.fatPercentage! / 100
                    let weight = HKQuantity(unit: unit, doubleValue: Double(value))
                    let sample = HKQuantitySample(type: fatPercentageType, quantity: weight, start: now, end: now)
                    healthStore.save(sample) { (success, error) in
                    }
                }
            }
        }
    }


}
