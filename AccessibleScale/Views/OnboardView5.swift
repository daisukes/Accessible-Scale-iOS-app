//
//  OnboardView5.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI
import CoreBluetooth
import UserNotifications


struct OnboardView5: View {
    @EnvironmentObject var modelData:ModelData

    let scale = Scale.shared

    let title = "Settings"

    var body: some View {

        return VStack {
            Text(String(format:"Step 5 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text("Please allow the app to access the Bluetooth device to connect to the scale and use notification.")
                .padding()

            Button(action: {
                if let user = modelData.createUser() {
                    scale.requestAuthorization(user: user)
                }
            }) {
                switch(modelData.bluetoothState) {
                case .unknown:
                    Label("Enable Bluetooth", systemImage: "circle")
                case .unauthorized:
                    Label("Bluetooth Denied", systemImage: "multiply.circle")
                case .poweredOn:
                    Label("Bluetooth Enabled", systemImage: "checkmark.circle")
                case .poweredOff:
                    Label("Bluetooth is Off", systemImage: "circle")
                default:
                    Text("bluetoothState error")
                }
            }
            .padding()
            .disabled(modelData.bluetoothState != .unknown)
            .frame(width:250, alignment: .leading)

            Button(action: {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options:[UNAuthorizationOptions.alert,
                                                     UNAuthorizationOptions.sound]) {
                    (granted, error) in
                    modelData.notificationState = granted ? .Granted : .Denied
                }
            }) {
                switch(modelData.notificationState) {
                case .Init:
                    Label("Enable Notification", systemImage:"circle")
                case .Granted:
                    Label("Notification Enabled", systemImage:"checkmark.circle")
                case .Denied:
                    Label("Notification Denied", systemImage:"multiply.circle")
                case .Off:
                    Label("ERROR", systemImage:"multiply.circle")
                }
            }
            .padding()
            .disabled(modelData.notificationState != .Init)
            .frame(width:250, alignment: .leading)

            HStack {
                Spacer()
                NavigationLink(destination: OnboardView6()
                                .environmentObject(modelData)) {
                    Text("Next")
                        .padding()
                }
                .disabled(modelData.bluetoothState != .poweredOn || modelData.notificationState == .Init)
            }
        }
        .padding()
        .navigationTitle(title)
    }
}

struct OnboardView5_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData()

        OnboardView5()
            .environmentObject(modelData)
            .previewDevice("iPhone 12 Pro")
            .previewDisplayName("Normal")
    }
}
