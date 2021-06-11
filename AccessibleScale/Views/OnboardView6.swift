//
//  OnboardView6.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI
import os.log

struct OnboardView6: View {
    @EnvironmentObject var modelData:ModelData
    
    let scale = Scale.shared

    let title = "Device"

    var body: some View {
        VStack {
            Text(String(format:"Step 6 out of %d", OnboardView1.number_of_steps))
                .padding()

            if modelData.connected {
                if modelData.userRegistered {
                    Text("The scale is connected! Congraturations, you've done initial setting!")
                        .padding()
                }
                else {
                    Text("User registraion was failed.")
                        .padding()
                    Button("Try to delete all users") {
                        os_log("Try to delete all users")
                        scale.allowDeletingAllUsers()
                        scale.start()
                    }
                }
            } else {
                Text("Place the scale on a flat hard surface. Then step on with a foot for a second to turn it on.")
                    .padding()

            }


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
            if modelData.previewing == false {
                scale.start()
            }
        }
    }
}

struct OnboardView6_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext).preview()
        let modelData2 = ModelData(viewContext: PersistenceController.preview.container.viewContext).preview()

        modelData2.connected = true
        modelData2.userRegistered = false

        let modelData3 = ModelData(viewContext: PersistenceController.preview.container.viewContext).preview()

        modelData3.connected = true
        modelData3.userRegistered = true

        return ViewBuilder.buildBlock(
            OnboardView6()
                .environmentObject(modelData)
                .previewDevice("iPhone 12 Pro")
                .previewDisplayName("Normal"),

            OnboardView6()
                .environmentObject(modelData2)
                .previewDevice("iPhone 12")
                .previewDisplayName("Connected error"),

            OnboardView6()
                .environmentObject(modelData3)
                .previewDevice("iPhone 12")
                .previewDisplayName("Connected okay")
        )
    }
}
