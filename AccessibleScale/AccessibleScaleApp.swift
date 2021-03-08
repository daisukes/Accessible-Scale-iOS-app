//
//  AccessibleScaleApp.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import CoreBluetooth
import HealthKit
import os.log

@main
struct AccessibleScaleApp: App, ScaleDelegate {
    @Environment(\.scenePhase) var scenePhase

    static let debug: Bool = false
    let scale = Scale.shared
    var center = UNUserNotificationCenter.current()
    var modelData: ModelData = debug ? ModelData(viewContext:  PersistenceController.preview.container.viewContext) : ModelData()
    static var backgroundTaskID: UIBackgroundTaskIdentifier?

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
                if AccessibleScaleApp.debug {
                    DispatchQueue.global().async {
                         // Request the task assertion and save the ID.
                        AccessibleScaleApp.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks") {
                            UIApplication.shared.endBackgroundTask(AccessibleScaleApp.backgroundTaskID!)
                            AccessibleScaleApp.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                         }

                        DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                            modelData.displayMeasurement = true
                            modelData.displayDifference = false
                            modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 65, fatPercentage: 25, metabolicAge: 40)
                            self.notifyMeasurement(state: .WeightMeasured)
                        }
                        Timer.scheduledTimer(withTimeInterval: 13, repeats: false) { timer in
                            modelData.displayMeasurement = true
                            modelData.displayDifference = true
                            modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 65, fatPercentage: 25, metabolicAge: 40)
                            self.notifyMeasurement(state: .WeightMeasured)
                        }
                        }
                    }
                }
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
            modelData.scaleConnected()
            break
        case .NotConnected:
            modelData.scaleDisconnected()
            break
        case .WeightMeasured:
            notifyMeasurement(state: state)
            break
        case .CompositeMeasured:
            notifyMeasurement(state: state)
            break
        case .Idle:
            break
        }
    }

    func updated(weight: GATTWeightMeasurement) {
        modelData.updated(weight: weight)
    }

    func updated(bodyComposition: GATTBodyCompositionMeasurement) {
        modelData.updated(bodyComposition: bodyComposition)
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
                    os_log("%@", log: .connection, theError.localizedDescription)
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
                    os_log("%@", log:.error, theError.localizedDescription)
                }
            }
        }
    }

    private func notifyMeasurement(state: Scale.State) {

        // Weight is measured first
        if state == .WeightMeasured && modelData.measurement.weight ?? 0 > 0 {
            if modelData.measurement.fatPercentage == nil {
                // measured before fat
                let message = modelData.notificationWeightString()
                let sound = UNNotificationSound.default
                notify(message, sound: sound)
                modelData.lastWeightNotify = Date().timeIntervalSince1970
            } else {
                // measured after fat
                let message = modelData.notificationWeightFatString()
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
                    let message = modelData.notificationFatString()
                    let sound = UNNotificationSound.default
                    notify(message, sound: sound)
                } else {
                    // measured before weight
                    // do nothing
                }
            } else {
                // Error
                let message = "Fat measurement error"
                let sound = UNNotificationSound.default
                notify(message, sound: sound)
            }
        }
    }


}
