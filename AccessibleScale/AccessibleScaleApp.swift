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


}
