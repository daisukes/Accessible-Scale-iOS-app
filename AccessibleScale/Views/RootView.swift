//
//  RootView.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import SwiftUI
import CoreData

struct RootView: View {
    @EnvironmentObject var modelData: ModelData

    var body: some View {
        NavigationView {
            if modelData.displayedScene == .Onboard {
                OnboardView1()
                    .environmentObject(modelData)
            } else {
                ContentView()
                    .environmentObject(modelData)

            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environment(\.managedObjectContext, PersistenceController.empty.container.viewContext)
            .environmentObject(ModelData(viewContext:  PersistenceController.empty.container.viewContext))
    }
}
