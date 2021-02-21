//
//  OnboardView6.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI

struct OnboardView6: View {
    @EnvironmentObject var modelData:ModelData
    
    let scale = Scale.shared

    let title = "Device"

    var body: some View {
        VStack {
            Text(String(format:"Step 6 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text(modelData.connected ?
                    "The scale is connected! Congraturations, you've done initial setting!":
                    "Place the scale on a flat hard surface. Then step on with a foot for a second to turn it on.")
                .padding()

            HStack {
                Spacer()
                NavigationLink(destination: OnboardView7()
                                .environmentObject(modelData)) {
                    Text("Next")
                        .padding()
                }
                .disabled(!modelData.userRegistered)
            }
        }
        .padding()
        .navigationTitle(title)
        .onAppear {
            scale.start()
        }
    }
}

struct OnboardView6_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData()

        OnboardView6()
            .environmentObject(modelData)
    }
}
