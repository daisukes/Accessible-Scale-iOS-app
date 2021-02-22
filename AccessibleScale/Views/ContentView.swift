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
    
    @State private var measureFat = false

    let scale = Scale.shared
    
    var body: some View {
        let users = modelData.users()
        return VStack {
            Label("Connected", systemImage: "dot.radiowaves.left.and.right")
                .isHidden(!modelData.connected)

            HStack {
                Spacer().frame(width: 50.0)
                Text(String(format: "%05.2f", modelData.weightInUserUnit()))
                    .font(.system(size: 60))
                Text(modelData.unit.label())
                    .font(.largeTitle)
                    .frame(width: 50.0)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .accessibilityLabel(modelData.localizedWeightString())
            .padding()
            
            HStack {
                Spacer().frame(width: 50.0)
                Text(String(format: "%05.2f", modelData.measurement.fatPercentage ?? 0))
                    .font(.system(size: 60))
                Text("%")
                    .font(.largeTitle)
                    .frame(width: 50.0)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .accessibilityLabel(modelData.localizedWeightString())
            .padding()
            
            Text("History")
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
                .font(.headline)

            if let measurements = users[0].measurements?.allObjects as? [BodyMeasurement] {
                List (measurements.sorted { $0.timestamp! > $1.timestamp! }) { measurement in
                    NavigationLink (destination: MeasurementDetail(measurement: measurement)) {
                        BodyMeasurementRow(measurement: measurement)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink (destination: UserDetail()
                                    .environmentObject(modelData)) {
                    Label("Your account", systemImage: "person.crop.circle")
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
            if modelData.users().count > 0 {
                scale.requestAuthorization(user: users[0], andScan: true)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        preview1
        preview2
    }

    static var preview1: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData.measurement = Measurement(measurementUnit: .Kilogram, weight: 54.25, fatPercentage: 19.9)

        return ContentView()
            .environmentObject(modelData)
    }

    static var preview2: some View {
        let modelData2 = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        modelData2.measurement = Measurement()
        
        return ContentView()
            .environmentObject(modelData2)
    }
}
