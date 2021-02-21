//
//  UserDetail.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/16/21.
//

import SwiftUI

struct UserDetail: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        VStack{
            Picker(selection: $modelData.unit, label: Text("Unit")) {
                Text("lb - inch").tag(ScaleUnit.Pound)
                Text("kg - cm").tag(ScaleUnit.Kilogram)
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker ("Height", selection: $modelData.height) {
                if modelData.unit == ScaleUnit.Kilogram {
                    ForEach (1...200, id: \.self) { h in
                        Text(String(format: "%d cm", h))
                            .tag(Int16(h))
                            .accessibilityLabel(String(format:"%d centi meters", h))
                    }
                } else {
                    ForEach (1...80, id: \.self) { h in
                        Text(String(format: "%d' %d\"", h/12, h%12))
                            .tag(h)
                            .accessibilityLabel(String(format:"%d feets and %d inches", h/12, h%12))
                    }
                }
            }

            Text("Date of birth")
            DatePicker(selection: $modelData.date_of_birth, displayedComponents: [.date]) {
            }
            .datePickerStyle(WheelDatePickerStyle())

            Picker(selection: $modelData.gender, label: Text("gender")) {
                Text("Female").tag(Gender.Female)
                Text("Male").tag(Gender.Male)
            }
            .pickerStyle(SegmentedPickerStyle())

            Spacer()
        }
        .padding()
        .navigationTitle("User")
        .onDisappear() {
            modelData.saveUser()
        }
    }
}

struct UserDetail_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(weight: 56.78, fatPercentage: 19.80)

        return UserDetail()
            .environmentObject(modelData)
    }
}
