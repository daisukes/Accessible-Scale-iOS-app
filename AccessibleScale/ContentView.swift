//
//  ContentView.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    @State private var measureFat = false

    var body: some View {
        VStack (alignment: .trailing) {
            Toggle(isOn: $measureFat) {
                Text("Measure Body Composite")
            }
            .padding()
            .hidden()

            HStack {
                Text(String(format: "%05.2f", modelData.viewData.weight))
                    .font(.system(size: 60))
                Text(modelData.viewData.unit.label())
                    .font(.largeTitle)
                    .frame(width: 50.0)
                    .fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
            }
            .accessibilityLabel(modelData.viewData.localizedWeightString())

            HStack {
                Text(String(format: "%04.1f", modelData.viewData.fat))
                    .font(.system(size: 60))
                Text("%")
                    .font(.largeTitle)
                    .frame(width: 50.0)
                    .fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
            }
            .accessibilityLabel(modelData.viewData.localizedFatString())
            .isHidden(!measureFat)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
            .environmentObject(ModelData())
    }
}
