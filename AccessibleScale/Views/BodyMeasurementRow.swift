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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relativeDate = formatter.localizedString(for: measurement.timestamp!,
                                                     relativeTo: Date())
        return HStack {
            Text(String(format:"%.2f \(measurement.label!)", measurement.weight))
            
            if let fat_free_mass = measurement.composite?.fat_free_mass {
                let fat_rate = (1.0 - fat_free_mass / measurement.weight) * 100
                Text(String(format:"%.2f %%", fat_rate))
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
        let items:[BodyMeasurement] = try! testData.getRows(count: 1)
        let item = items[0]
        
        return BodyMeasurementRow(measurement: item)
            .previewLayout(.fixed(width: 300, height: 40))
    }
}