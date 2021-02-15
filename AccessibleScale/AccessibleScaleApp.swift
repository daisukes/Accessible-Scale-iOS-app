//
//  AccessibleScaleApp.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import UserNotifications

@main
struct AccessibleScaleApp: App, ScaleDelegate {
    @Environment(\.scenePhase) var scenePhase
    let modelData = ModelData()

    var scale: Scale = RenphoScale()
    var center = UNUserNotificationCenter.current()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                             actions: [],
                                                             intentIdentifiers: [],
                                                             options: [.allowAnnouncement])
                center.setNotificationCategories([generalCategory])
                center.requestAuthorization(options: [UNAuthorizationOptions.alert,
                                                      UNAuthorizationOptions.sound]) { (granted, error) in
                }
                scale.delegate = self
                break
            @unknown default:
                break
            }
        }
    }

    // MARK: ScaleDelegate

    func updated(state: Scale.State) {
        if UIApplication.shared.applicationState != .background {
            return
        }

        switch(state) {
        case .Connected:
            DispatchQueue.main.async {
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Scale Connected", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "You can step on the scale now", arguments: nil)
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
        case .NotConnected:
            break
        case .WeightMeasured:
            if modelData.viewData.weight == 0 {
                break
            }
            DispatchQueue.main.async {
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Measure Completed", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "Your weight is \(modelData.viewData.localizedWeightString())", arguments: nil)
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
            break
        case .Idle:
            break
        }
    }

    func updated(weight: Float32, unit: Unit) {
        modelData.viewData.weight = weight
        modelData.viewData.unit = unit
        _ = modelData.$viewData.share()
    }

    func updated(fat: Float32) {
    }

}
