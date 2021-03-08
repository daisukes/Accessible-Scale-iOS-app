//
//  MeasurementDetail.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI

struct MeasurementDetail: View {

    @EnvironmentObject var modelData: ModelData

    @State var measurement: BodyMeasurement
    
    var body: some View {
        let unit = modelData.unit

        ScrollView {
            VStack {
                HStack {
                    Text(SimpleDateTime().string(from: measurement.timestamp ?? Date()))
                }
                HStack {
                    Text("Weight")
                    Spacer()
                    Text(String(format: "%.2f %@", measurement.weight(inUnit: unit), unit.label()))
                }
                .padding()

                optionalPart
                optionalPart2
            }
        }
        .padding()
    }

    var optionalPart: some View {
        let unit = modelData.unit

        return VStack {
            if measurement.fat_percentage > 0 {
                HStack {
                    Text("Fat Percentage")
                    Spacer()
                    Text(String(format:"%.1f %%", measurement.fat_percentage ))
                }
                .padding()
            }

            if measurement.body_mass_index > 0 {
                HStack {
                    Text("Body Mass Index")
                    Spacer()
                    Text(String(format:"%.1f", measurement.body_mass_index ))
                }
                .padding()
            }

            if measurement.basal_metabolism > 0 {
                HStack {
                    Text("Resting Energy")
                    Spacer()
                    Text(String(format:"%d Cal", measurement.basal_metabolism ))
                }
                .padding()
            }

            if measurement.muscle_mass > 0 {
                HStack {
                    Text("Muscle Mass")
                    Spacer()
                    Text(String(format:"%.2f %@", measurement.muscle_mass(inUnit: unit), unit.label() ))
                }
                .padding()
            }

            if measurement.muscle_percentage > 0 {
                HStack {
                    Text("Muscle Percentage")
                    Spacer()
                    Text(String(format:"%.1f %%", measurement.muscle_percentage ))
                }
                .padding()
            }

            if measurement.fat_free_mass > 0 {
                HStack {
                    Text("Fat Free Mass")
                    Spacer()
                    Text(String(format:"%.2f %@", measurement.fat_free_mass(inUnit: unit), unit.label() ))
                }
                .padding()
            }

            if measurement.soft_lean_mass > 0 {
                HStack {
                    Text("Soft Lean Mass")
                    Spacer()
                    Text(String(format:"%.2f %@", measurement.soft_lean_mass(inUnit: unit), unit.label() ))
                }
                .padding()
            }

            if measurement.body_water_mass > 0 {
                HStack {
                    Text("Body Water Mass")
                    Spacer()
                    Text(String(format:"%.2f %@", measurement.body_water_mass(inUnit: unit), unit.label() ))
                }
                .padding()
            }

            if measurement.impedance > 0 {
                HStack {
                    Text("Impedance")
                    Spacer()
                    Text(String(format:"%d Ohm", measurement.impedance ))
                }
                .padding()
            }
        }
    }

    var optionalPart2: some View {
        let unit = modelData.unit

        return VStack {
            if measurement.bone_mass > 0 {
                HStack {
                    Text("Bone Mass")
                    Spacer()
                    Text(String(format:"%.2f %@", measurement.bone_mass(inUnit: unit), unit.label() ))
                }
                .padding()
            }

            if measurement.subcutaneous_fat > 0 {
                HStack {
                    Text("Subcutaneous Fat")
                    Spacer()
                    Text(String(format:"%.2f %%", measurement.subcutaneous_fat ))
                }
                .padding()
            }

            if measurement.protein > 0 {
                HStack {
                    Text("Protein")
                    Spacer()
                    Text(String(format:"%.2f %%", measurement.protein ))
                }
                .padding()
            }

            if measurement.metabolic_age > 0 {
                HStack {
                    Text("Metabolic Age")
                    Spacer()
                    Text(String(format:"%d", measurement.metabolic_age ))
                }
                .padding()
            }
        }
    }
}

struct MeasurementDetail_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        //modelData.unit = ScaleUnit.Pound
        let ctx = PersistenceController.preview.container.viewContext

        let testData = DataHelper(context: ctx, entityName: "BodyMeasurement")
        let items:[BodyMeasurement] = try! testData.getRows(count: 2)

        return MeasurementDetail(measurement: items[0])
            .environmentObject(modelData)
    }
}
