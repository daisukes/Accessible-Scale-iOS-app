//
//  AccessibleScaleApp.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import CoreBluetooth

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
            modelData.connected = true
            modelData.weight = 0
            modelData.fat = 0
            break
        case .NotConnected:
            modelData.connected = false
            break
        case .WeightMeasured:
            if modelData.weight == 0 {
                break
            }
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState != .background {
                    UIAccessibility.post(notification: .announcement, argument: modelData.localizedWeightString())
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = modelData.localizedWeightString()
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { (error: Error?) in
                    if let theError = error {
                        print(theError.localizedDescription)
                    }
                }
            }
            break
        case .CompositeMeasured:
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState != .background {
                    UIAccessibility.post(notification: .announcement, argument: modelData.localizedFatString())
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = "\(modelData.localizedFatString())"
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { (error: Error?) in
                    if let theError = error {
                        print(theError.localizedDescription)
                    }
                }
            }
            break
        case .Idle:
            break
        }
    }

    func updated(weight: GATTWeightMeasurement) {
        let massFactor = (modelData.unit == .Kilogram) ? 1 : Float(0.453592)
        modelData.weight = weight.weight / massFactor
    }

    func updated(bodyComposition: GATTBodyCompositionMeasurement) {
        modelData.fat = bodyComposition.fatPercentage
    }

}
