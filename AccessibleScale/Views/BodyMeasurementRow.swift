//
//  BodyMeasurementRow.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/16/21.
//

import SwiftUI
import CoreData

struct BodyMeasurementRow: View {

    @EnvironmentObject var modelData: ModelData

    var measurement: BodyMeasurement

    var body: some View {
        let unit = modelData.unit
        let timestamp = measurement.timestamp ?? Date()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relativeDate = formatter.localizedString(for: timestamp, relativeTo: Date())

        return HStack {
            Text(String(format: "%.2f %@", measurement.weight(inUnit: unit), unit.label()))

            if measurement.fat_percentage > 0 {
                Text(String(format:"%.1f %%", measurement.fat_percentage ))
            }

            Spacer()
            Text(relativeDate)
        }
    }
}

struct BodyMeasurementRow_Previews: PreviewProvider {
    static var previews: some View {
        let modelData = ModelData(viewContext: PersistenceController.preview.container.viewContext)
        let ctx = PersistenceController.preview.container.viewContext

        let testData = DataHelper(context: ctx, entityName: "BodyMeasurement")
        let items:[BodyMeasurement] = try! testData.getRows(count: 2)

        return BodyMeasurementRow(measurement: items[0])
            .environmentObject(modelData)
            .previewLayout(.fixed(width: 300, height: 40))
        //BodyMeasurementRow(measurement: items[1], user: user)
            //.previewLayout(.fixed(width: 300, height: 40))
    }
}
