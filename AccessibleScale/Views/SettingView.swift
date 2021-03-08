//
//  UserDetail.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/16/21.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        Form {
            appSetting
            userSetting
        }
        .navigationTitle("Settings")
        .onDisappear() {
            modelData.saveUser()
        }
    }

    var appSetting: some View {
        Section(header: Text("App setting")) {
            Toggle("Display Measurement", isOn: $modelData.displayMeasurement)
                .disabled(modelData.displayDifference == false)

            Toggle("Display Difference", isOn: $modelData.displayDifference)
                .disabled(modelData.displayMeasurement == false)

            Toggle("Display Age Difference", isOn: $modelData.displayMetabolicAgeDifference)
        }
    }

    var userSetting: some View {
        Section(header: Text("User setting")) {
            Picker("Unit", selection: $modelData.unit) {
                Text("lb - inch").tag(ScaleUnit.Pound)
                Text("kg - cm").tag(ScaleUnit.Kilogram)
            }
            .pickerStyle(DefaultPickerStyle())

            Picker("Gender", selection: $modelData.gender) {
                Text("Female").tag(Gender.Female)
                Text("Male").tag(Gender.Male)
            }
            .pickerStyle(DefaultPickerStyle())

            VStack {
                HStack {
                    Text("Height")
                    Spacer()
                }
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
                .pickerStyle(InlinePickerStyle())
            }

            VStack {
                HStack {
                    Text("Date of Birth")
                    Spacer()
                }
                DatePicker(selection: $modelData.date_of_birth, displayedComponents: [.date]) {
                }
                //.pickerStyle(DefaultPickerStyle())
                .datePickerStyle(WheelDatePickerStyle())
            }
        }
    }
}

struct UserDetail_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(weight: 56.78, fatPercentage: 19.80)

        return SettingView()
            .environmentObject(modelData)
    }
}
