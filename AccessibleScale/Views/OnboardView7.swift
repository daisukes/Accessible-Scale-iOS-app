//
//  OnboardView7.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/21/21.
//

import Foundation
import SwiftUI
import HealthKit

struct OnboardView7: View {
    @EnvironmentObject var modelData:ModelData

    let title = "Apple Health"

    var body: some View {
        VStack {
            Text(String(format:"Step 7 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text("Please allow the app to access your Apple Health data to save your measurement")
                .padding()

            Button(action: {
                modelData.authorizeHealthkit()
            }) {
                switch(modelData.healthKitState) {
                case .Init:
                    Label("Enable Apple Health", systemImage: "circle")
                case .Denied:
                    Label("Apple Health Had Error", systemImage: "multiply.circle")
                case .Granted:
                    Label("Apple Health Checked", systemImage: "checkmark.circle")
                default:
                    Text("healthKitState error")
                }
            }
            .padding()
            .disabled(modelData.healthKitState != .Init)
            .frame(width:250, alignment: .leading)

            HStack {
                Spacer()
                Button("Next") {
                    modelData.displayedScene = .Scale
                }
                .padding()
                .disabled(modelData.healthKitState == .Init)
            }
        }
        .onAppear() {
        }
    }
}

struct OnboardView7_Previews: PreviewProvider {
    static var previews: some View {
        OnboardView7()
    }
}
