//
//  DataHelper.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/17/21.
//

import Foundation
import CoreData

protocol DataProtocol {
    var context: NSManagedObjectContext {get}
    var entityName: String {get}
    func getRows() throws -> [Any]?
    func count() -> Int
}

class DataHelper: DataProtocol {
    var context: NSManagedObjectContext
    
    var entityName: String
    
    init(context: NSManagedObjectContext, entityName: String) {
        self.context = context
        self.entityName = entityName
    }
    
    func getRows() throws -> [Any]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        return try? context.fetch(fetchRequest)
    }
    
    func getRows<T>(count: Int) throws -> [T] {
        let fullList: [T] = try self.getRows() as! [T]
        return Array(fullList.prefix(count))
    }

    func count() -> Int {
        do {
            if let rows = try getRows() {
                return rows.count
            }
        } catch {
        }
        return 0
    }
}

class UserHelper: DataHelper {
    init(context: NSManagedObjectContext) {
        super.init(context: context, entityName: "User")
    }
 }
