//
//  Persistence.swift
//  AccessibleScale
//
//  Created by Daisuke Sato on 2021/02/14.
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let user = User(context: viewContext)
        user.unit = ScaleUnit.Kilogram.rawValue
        user.date_of_birth = SimpleDate.date19700101
        user.height = 165
        user.gender = Gender.Female.rawValue
        user.display_difference = true
        user.display_measurement = true

        for i in 0..<20 {
            let newItem = BodyMeasurement(context: viewContext)
            newItem.weight = Double.random(in: 1..<5.0)+60.0
            newItem.timestamp = Date().advanced(by: TimeInterval(-Int.random(in: 100...100000)))
            newItem.unit = ScaleUnit.Kilogram.rawValue
            newItem.user = user

            if Int.random(in: 0...1) < 2 {
                newItem.body_mass_index = Double.random(in: 1..<5.0)+20.0
                newItem.fat_percentage = Double.random(in: 1..<5.0)+15.0
                newItem.basal_metabolism = Int32.random(in: 1500..<2000)
                newItem.body_water_mass = Double.random(in: 1..<5.0)+30.0
                newItem.fat_free_mass = Double.random(in: 1..<5.0)+50.0
                newItem.impedance = Int32.random(in: 400..<500)
                newItem.muscle_mass =  Double.random(in: 1..<5.0)+50.0
                newItem.muscle_percentage = Double.random(in: 1..<5.0)+35.0
                newItem.soft_lean_mass =  Double.random(in: 1..<5.0)+50.0
            }
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    static var empty: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AccessibleScale")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
