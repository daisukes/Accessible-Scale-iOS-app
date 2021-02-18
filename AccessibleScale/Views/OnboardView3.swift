//
//  OnboardView3.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI

struct OnboardView3: View {
    @EnvironmentObject var modelData:ModelData

    let title = "Date of Birth"

    var body: some View {
        VStack {
            Text(String(format:"Step 3 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text("Input your date of birth")
                .padding()

            DatePicker(selection: $modelData.date_of_birth, displayedComponents: [.date]) {
            }
            .datePickerStyle(WheelDatePickerStyle())
            .padding()

            HStack {
                Spacer()
                NavigationLink(destination: OnboardView4()
                                .environmentObject(modelData)) {
                    Text("Next")
                        .padding()
                }
            }
        }
        .padding()
        .navigationTitle(title)
    }
}

struct OnboardView3_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext:  PersistenceController.empty.container.viewContext)
        OnboardView3()
            .environmentObject(modelData)
    }
}
