//
//  ContentView.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData

    let scale = Scale.shared
    
    var body: some View {
        VStack {
            Label("Connected", systemImage: "dot.radiowaves.left.and.right")
                .isHidden(!modelData.connected)

            if modelData.displayMeasurement {
                HStack {
                    Spacer().frame(width: 50.0)
                    Text(String(format: "%05.2f", modelData.weightInUserUnit()))
                        .font(.system(size: 60))
                        .accessibility(label: Text(modelData.localizedWeightString()))
                    Text(modelData.unit.label())
                        .font(.largeTitle)
                        .frame(width: 50.0)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibility(hidden: true)
                }
            }
            if modelData.displayDifference {
                HStack {
                    Spacer().frame(width: 50.0)
                    Text(String(format: "%+04.2f", modelData.weightDiffInUserUnit()))
                        .font(.system(size: 60))
                        .accessibility(label: Text(modelData.localizedWeightDiffString()))
                    Text(modelData.unit.label())
                        .font(.largeTitle)
                        .frame(width: 50.0)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibility(hidden: true)
                }
            }

            if modelData.displayMeasurement {
                HStack {
                    Spacer().frame(width: 50.0)
                    Text(String(format: "%05.2f", modelData.fat()))
                        .font(.system(size: 60))
                        .accessibilityLabel(modelData.localizedFatString())
                    Text("%")
                        .font(.largeTitle)
                        .frame(width: 50.0)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibility(hidden: true)
                }
            }

            if modelData.displayDifference {
                HStack {
                    Spacer().frame(width: 50.0)
                    Text(String(format: "%+04.2f", modelData.fatDiff()))
                        .font(.system(size: 60))
                        .accessibilityLabel(modelData.localizedFatDiffString())
                    Text("%")
                        .font(.largeTitle)
                        .frame(width: 50.0)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibility(hidden: true)
                }
            }

            if modelData.displayMetabolicAgeDifference {
                HStack {
                    Spacer().frame(width: 50.0)
                    Text(String(format: "%+02d", modelData.metabolicAgeDiff()))
                        .font(.system(size: 60))
                        .accessibilityLabel(modelData.localizedMetabolicAgeDiffString())
                    Text("y")
                        .font(.largeTitle)
                        .frame(width: 50.0)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibility(hidden: true)
                }
            }

            NavigationLink(destination: HistoryView()) {
                Text("Measurement Record")
                    .padding()
            }

            Spacer()
        }
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink (destination: SettingView()
                                    .environmentObject(modelData)) {
                    HStack {
                        Text("")
                            .accessibilityHidden(true)

                        Image(systemName: "gearshape")
                            .accessibilityElement()
                            .accessibilityLabel("Settings")
                    }
                }
            }

            /*
             When UserDetail view is present and modelData.connected is changed
             somehow the second UserDetail is present
            ToolbarItem(placement: .navigationBarLeading) {
                Label("Connected", systemImage: "dot.radiowaves.left.and.right")
                    .isHidden(!modelData.connected)
            }
             */
        }
        .onAppear {
            if let user = modelData.user {
                scale.requestAuthorization(user: user, andScan: true)
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        VStack {
            if let measurements = modelData.user?.measurements?.allObjects as? [BodyMeasurement] ?? [] {
                List {
                    ForEach (measurements.sorted { $0.timestamp! > $1.timestamp! }, id: \.self) { measurement in
                        NavigationLink (destination: MeasurementDetail(measurement: measurement)
                                            .environmentObject(modelData)) {
                            BodyMeasurementRow(measurement: measurement)
                                .environmentObject(modelData)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Record")
    }

    func delete(at offsets: IndexSet) {
        if let user = modelData.user {
            if let measurements = user.measurements?.allObjects as? [BodyMeasurement] {
                let sorted = measurements.sorted { $0.timestamp! > $1.timestamp! }

                for offset in offsets {
                    modelData.delete(data: sorted[offset])
                }
                modelData.saveCoreData()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        preview0
        preview0_2
        preview1
        preview2
        preview3
    }

    static var preview0: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 63.00, fatPercentage: 19.9)
        modelData.displayDifference = false

        return ContentView()
            .environmentObject(modelData)
    }

    static var preview0_2: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 13.00, fatPercentage: 0.0)
        modelData.displayMeasurement = false

        return ContentView()
            .environmentObject(modelData)
    }

    static var preview1: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 63.00, fatPercentage: 19.9)

        return ContentView()
            .environmentObject(modelData)
    }

    static var preview2: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement()
        
        return ContentView()
            .environmentObject(modelData)
    }

    static var preview3: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement()
        modelData.displayDifference = false

        return ContentView()
            .environmentObject(modelData)
    }

}
