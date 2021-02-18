//
//  OnboardView4.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI

struct OnboardView4: View {
    @EnvironmentObject var modelData:ModelData

    let title = "gender"

    var body: some View {
        VStack {
            Text(String(format:"Step 4 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text("Select your gender")
                .padding()

            Picker(selection: $modelData.gender, label: Text("gender")) {
                Text("Female").tag(Gender.Female)
                Text("Male").tag(Gender.Male)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            HStack {
                Spacer()
                NavigationLink (
                    destination: OnboardView5()
                        .environmentObject(modelData)) {
                    Text("Next")
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle(title)
    }
}

struct OnboardView4_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext:  PersistenceController.empty.container.viewContext)
        OnboardView4()
            .environmentObject(modelData)
    }
}
