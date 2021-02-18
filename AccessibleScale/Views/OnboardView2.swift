//
//  OnboardView2.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI

struct OnboardView2: View {
    @EnvironmentObject var modelData:ModelData

    let title = "Height"

    var body: some View {
        VStack {
            Text(String(format:"Step 2 out of %d", OnboardView1.number_of_steps))
                .padding()

            Text("Select your height")
                .padding()

            Picker ("Height", selection: $modelData.height) {
                if modelData.unit == .Kilogram {
                    ForEach (1...200, id: \.self) { h in
                        Text(String(format: "%d cm", h))
                            .tag(h)
                            .accessibilityLabel(String(format:"%d centi meters", h))
                    }
                } else {
                    ForEach (1...80, id: \.self) { h in
                        Text(String(format: "%d' %d\"", h/12, h%12))
                            .tag(h)
                            .accessibilityLabel(String(format:"%d feets and %d inches", h/12, h%12))
                    }
                }
            }.padding()
            
            HStack {
                Spacer()
                NavigationLink(destination: OnboardView3()
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

struct OnboardView2_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext:  PersistenceController.empty.container.viewContext)
        OnboardView2()
            .environmentObject(modelData)

        OnboardView2()
            .environmentObject(modelData)
    }
}
