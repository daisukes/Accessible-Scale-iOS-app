//
//  OnboardView.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI
import CoreData

struct OnboardView1: View {
    static let number_of_steps: Int = 6
    @EnvironmentObject var modelData:ModelData

    let title = "Welcome"

    var body: some View {
        VStack{
            Text("Please select your preferred scale unit.")
                .padding()

            Picker(selection: $modelData.unit, label: Text("Unit")) {
                Text("lb - inch").tag(ScaleUnit.Pound).accessibilityLabel("Pounds and Inches")
                Text("kg - cm").tag(ScaleUnit.Kilogram).accessibilityLabel("Kilograms and Centimeters")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            HStack {
                Spacer()
                NavigationLink (
                    destination: OnboardView2()
                        .environmentObject(modelData)) {
                    Text("Next")
                }
                .padding()
            }
        }
        .padding()
        .navigationBarTitle(title, displayMode: .inline)
    }
}

struct OnboardView1_Previews: PreviewProvider {
    static var previews: some View {
        OnboardView1()
            .environmentObject(ModelData(viewContext:  PersistenceController.empty.container.viewContext))
    }
}
