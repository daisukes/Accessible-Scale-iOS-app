//
//  BodyMeasurementRow.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/16/21.
//

import SwiftUI
import CoreData

struct BodyMeasurementRow: View {
    
    var measurement: BodyMeasurement
    
    var body: some View {
        let label = ScaleUnit(rawValue: measurement.unit!)!.label()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relativeDate = formatter.localizedString(for: measurement.timestamp!,
                                                     relativeTo: Date())

        return HStack {
            Text(String(format: "%.2f %@", measurement.weight, label))

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
        let ctx = PersistenceController.preview.container.viewContext

        let testData = DataHelper(context: ctx, entityName: "BodyMeasurement")
        let items:[BodyMeasurement] = try! testData.getRows(count: 2)

        BodyMeasurementRow(measurement: items[0])
            .previewLayout(.fixed(width: 300, height: 40))
        BodyMeasurementRow(measurement: items[1])
            .previewLayout(.fixed(width: 300, height: 40))
    }
}
