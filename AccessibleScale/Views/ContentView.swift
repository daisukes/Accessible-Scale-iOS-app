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
            Spacer()
            
            HStack {
                Spacer().frame(width: 50.0)
                Text(String(format: "%05.2f", modelData.weight))
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
                Text(String(format: "%05.2f", modelData.fat))
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
                    NavigationLink (destination: MeasurementDetail()) {
                        BodyMeasurementRow(measurement: measurement)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink (destination: UserDetail()
                                    .environmentObject(modelData)) {
                    Label("Your account", systemImage: "person.crop.circle")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if modelData.connected {
                    Label("Connected", systemImage: "dot.radiowaves.left.and.right")
                }
            }
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
        let modelData = ModelData()
        modelData.weight = 54.25
        modelData.fat = 19.2
        
        return ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(modelData)
    }
}
