//
//  GATTUserData.swift
//  AccessibleScale
//
//  Created by CAL Cabot on 2/19/21.
//

import Foundation
import os.log

class GATTUserData {

}

class GATTGender {
    enum Gender: UInt8 {
        case Male = 0x00
        case Female = 0x01
        case Unspecified = 0x02
        case Unknown = 0xFF
    }

    let gender: Gender

    init(gender: Gender) {
        self.gender = gender
    }

    func compose() -> Data {
        var data = Data()
        data.append(self.gender.rawValue)
        return data
    }
}

class GATTHeight {
    let height: Float

    init(height: Float) {
        self.height = height
    }

    func compose() -> Data {
        var data = Data()
        GATTUtil.append(&data, UInt16(self.height))
        return data
    }
}

class GATTAge {
    let age: UInt8

    init(age: UInt8) {
        self.age = age
    }

    init(date_of_birth: Date) {
        self.age = SimpleDate.age(from: date_of_birth)
    }

    func compose() -> Data {
        var data = Data()
        data.append(self.age)
        return data
    }
}

class GATTDateOfBirth {
    let date: Date

    let year: UInt16
    let month: UInt8
    let day: UInt8
    
    init(date: Date) {
        self.date = date
        let components = SimpleDate.makeComponent(date: date)
        year = UInt16(components.year!)
        month = UInt8(components.month!)
        day = UInt8(components.day!)
    }

    func compose() -> Data {
        var data = Data()
        GATTUtil.append(&data, year)
        data.append(month)
        data.append(day)
        return data
    }
}


class GATTUserControlPoint {
    enum Operation: UInt8 {
        case RegisterNewUser = 0x01
        case Consent = 0x02
        case DeleteUser = 0x03
        case ListAllUsers = 0x04
        case DeleteUsers = 0x05
        case Response = 0x20
        case Unknown = 0xFF
    }

    class Response {
        enum Value: UInt8 {
            case Success = 0x01
            case NotSuppored = 0x02
            case InvalidParameter = 0x03
            case OperationFailed = 0x04
            case NotAuthorized = 0x05
            case Unknown = 0xFF
        }

        let operation: Operation
        let value: Value
        let parameter: UInt8?
        //let parameter: Data? - can be 0 - 17 octets, but only 1 byte is used for now

        init(_ data: Data, _ index: inout Int) {
            let opCode = GATTUtil.uint8(data, &index)
            if let operation = Operation(rawValue: opCode) {
                self.operation = operation
            } else {
                os_log("Unknown response operation code %x", log: .gatt, opCode)
                self.operation = .Unknown
            }
            let valCode = GATTUtil.uint8(data, &index)
            if let value = Value(rawValue: valCode) {
                self.value = value
            } else {
                self.value = .Unknown
            }
            if index < data.count{
                self.parameter = GATTUtil.uint8(data, &index)
            } else {
                self.parameter = nil
            }
        }
    }

    let operation: Operation
    let parameter: Data?
    let response: Response?

    init(operation: Operation, parameter: Data?) {
        self.operation = operation
        self.parameter = parameter
        self.response = nil
    }

    init(data: Data) {
        var index = 0
        let opCode = GATTUtil.uint8(data, &index)
        if let operation = Operation(rawValue: opCode) {
            self.operation = operation
        } else {
            fatalError(String(format: "Unknown operation code %x", opCode))
        }

        guard self.operation == .Response else {
            fatalError("This init func is intended only for response")
        }

        self.parameter = nil
        self.response = Response(data, &index)
    }

    func compose() -> Data {
        var data = Data()
        GATTUtil.append(&data, operation.rawValue)
        if let parameter = parameter {
            data.append(parameter)
        }
        return data
    }

    static func registerNewUser(passcode: UInt16) -> GATTUserControlPoint {
        var data = Data()
        GATTUtil.append(&data, passcode)
        return GATTUserControlPoint(operation: .RegisterNewUser, parameter: data)
    }

    static func consent(userID: UInt8, passcode: UInt16) -> GATTUserControlPoint {
        var data = Data()
        GATTUtil.append(&data, userID)
        GATTUtil.append(&data, passcode)
        return GATTUserControlPoint(operation: .Consent, parameter: data)
    }

    static func deleteUser() -> GATTUserControlPoint {
        return GATTUserControlPoint(operation: .DeleteUser, parameter: nil)
    }

    static func deleteAllUsers() -> GATTUserControlPoint {
        var data = Data()
        for i in 1...17 {
            data.append(UInt8(i))
        }
        return GATTUserControlPoint(operation: .DeleteUsers, parameter: data)
    }
}
