//
//  AbstractScale.swift
//  AScale
//
//  Created by Daisuke Sato on 2021/02/12.
//

import Foundation
import CoreBluetooth
import AVFoundation
import os.log


protocol ScaleDelegate {
    func updated(bluetoothState: CBManagerState)
    func updated(state: Scale.State)
    func updated(weight: GATTWeightMeasurement)
    func updated(bodyComposition: GATTBodyCompositionMeasurement)
}

class Scale: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = Scale()

    enum State {
        case NotConnected
        case UserRegistered
        case Connected
        case WeightMeasured
        case CompositeMeasured
        case Idle
    }

    // Weight service and characteristics
    let WEIGHT_SCALE_SERVICE_UUID =      CBUUID(string: "0000181D-0000-1000-8000-00805f9b34fb")
    let WEIGHT_SCALE_FEATURE_CHAR_UUID = CBUUID(string: "00002A9E-0000-1000-8000-00805f9b34fb")
    let WEIGHT_MEASUREMENT_CHAR_UUID =   CBUUID(string: "00002A9D-0000-1000-8000-00805f9b34fb")

    // Body Composition service and characteristics
    let BODY_COMPOSITION_SERVICE_UUID =          CBUUID(string: "0000181B-0000-1000-8000-00805f9b34fb")
    let BODY_COMPOSITION_MEASUREMENT_CHAR_UUID = CBUUID(string: "00002A9C-0000-1000-8000-00805f9b34fb")
    let BODY_COMPOSITION_CUSTOM1_CHAR_UUID =     CBUUID(string: "0000FFE1-0000-1000-8000-00805f9b34fb") // notify
    let BODY_COMPOSITION_CUSTOM2_CHAR_UUID =     CBUUID(string: "0000FFE2-0000-1000-8000-00805f9b34fb") // custom write (unit - 03, unknown - 05)

    // User Data service and characteristics
    let USER_DATA_SERVICE_UUID =        CBUUID(string: "0000181C-0000-1000-8000-00805f9b34fb")
    let USER_AGE_CHAR_UUID =            CBUUID(string: "00002A80-0000-1000-8000-00805f9b34fb")
    let USER_DATE_OF_BIRTH_CHAR_UUID =  CBUUID(string: "00002A85-0000-1000-8000-00805f9b34fb")
    let USER_GENDER_CHAR_UUID =         CBUUID(string: "00002A8C-0000-1000-8000-00805f9b34fb")
    let USER_HEIGHT_CHAR_UUID =         CBUUID(string: "00002A8E-0000-1000-8000-00805f9b34fb")
    let USER_CONTROL_POINT_CHAR_UUID =  CBUUID(string: "00002A9F-0000-1000-8000-00805f9b34fb")
    let USER_CUSTOM_ATHLETE_MODE_UUID = CBUUID(string: "00002AFF-0000-1000-8000-00805f9b34fb")

    var delegate: ScaleDelegate?

    let RESTORE_KEY = UUID().uuidString
    let PERIPHERAL_KEY = 5939990259

    var manager: CBCentralManager!
    var scale: CBPeripheral?
    var services: [CBService] = []
    var chars: [CBUUID: CBCharacteristic] = [:]

    var index: Int = 0
    var lastIndex: Int = 0
    var weight: Float = 0
    var unit: ScaleUnit = .Kilogram
    var processTimer: Timer?
    var notifyTimer: Timer?
    var user: User?
    var connected: Bool = false
    var weightNotified: Date?
    var deleteUsersAllowed: Bool = true

    func requestAuthorization(user: User?, andScan: Bool = false) {
        os_log("requestAuthorization", log:.connection)
        self.user = user
        if self.manager == nil {
            os_log("instanciate CBCentralManager", log:.connection)
            self.manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: RESTORE_KEY])
        }
        if andScan && self.manager.state == .poweredOn {
            start()
        }
    }

    func start() {
        os_log("start", log:.connection)
        if self.scale == nil {
            if self.manager.isScanning == false {
                self.manager.scanForPeripherals(withServices: [self.WEIGHT_SCALE_SERVICE_UUID], options: nil)
            }
        } else {
            connect()
        }
    }

    // MARK: CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        os_log("didUpdatedState", log:.connection)
        if central.state == .poweredOn {
            start()
        }

        guard let delegate = self.delegate else { return }
        delegate.updated(bluetoothState: central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("didDiscover", log:.connection)

        peripheral.delegate = self
        scale = peripheral

        central.stopScan()
        connect()
    }

    private func connect() {
        os_log("connect", log:.connection)
        guard let manager = self.manager else { return }
        guard let scale = self.scale else { return }

        manager.connect(scale, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey : NSNumber(value: PERIPHERAL_KEY),
        ])
    }

    func allowDeletingAllUsers() {
        self.delegate?.updated(state: .NotConnected)
        deleteUsersAllowed = true
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("central didConnect", log:.connection)
        guard let scale = self.scale else { return }

        index = 0

        if scale.services == nil {
            scale.discoverServices([BODY_COMPOSITION_SERVICE_UUID, USER_DATA_SERVICE_UUID, WEIGHT_SCALE_SERVICE_UUID])
        } else {
            if let services = scale.services {
                for service in services {
                    if let chars = service.characteristics {
                        for char in chars {
                            self.chars[char.uuid] = char
                        }
                    }
                }
            }
            checkCharsReady()
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("central didDisconnect", log:.connection)
        guard let delegate = self.delegate else { return }
        connected = false
        chars = [:]
        delegate.updated(state: .NotConnected)

        // restart for next measurement
        start()
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        os_log("central willRestore", log:.connection)
        if let scales = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            if scales.count > 0 {
                scales[0].delegate = self
                self.scale = scales[0]
            }
            start()
        }
    }

    // MARK: CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        os_log("peripheral didDiscoverServices", log:.connection)

        guard let scale = self.scale else { return }
        guard let services = scale.services else { return }

        for service in services {
            scale.discoverCharacteristics([], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        os_log("peripheral didDiscoverCharacteristicsFor", log:.connection)
        guard let chars = service.characteristics else { return }

        for char in chars {
            self.chars[char.uuid] = char
        }

        checkCharsReady()
    }

    func checkCharsReady() {
        if self.chars[BODY_COMPOSITION_MEASUREMENT_CHAR_UUID] != nil &&
            self.chars[WEIGHT_MEASUREMENT_CHAR_UUID] != nil &&
            self.chars[USER_CONTROL_POINT_CHAR_UUID] != nil &&
            self.chars[BODY_COMPOSITION_CUSTOM1_CHAR_UUID] != nil &&
            self.chars[BODY_COMPOSITION_CUSTOM2_CHAR_UUID] != nil &&
            self.chars[USER_GENDER_CHAR_UUID] != nil &&
            self.chars[USER_HEIGHT_CHAR_UUID] != nil &&
            self.chars[USER_DATE_OF_BIRTH_CHAR_UUID] != nil &&
            self.chars[USER_AGE_CHAR_UUID] != nil &&
            self.chars[USER_CUSTOM_ATHLETE_MODE_UUID] != nil &&
            connected == false{
            index = 1
            lastIndex = 0
            os_log("Start timer", log:.connection)
            processTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
    }

    @objc func fireTimer() {
        nextStep()
    }

    var startTime: TimeInterval = 0

    func nextStep() {
        guard index != lastIndex else { return }
        guard let delegate = self.delegate else { return }
        guard let scale = self.scale else { return }
        guard let user = self.user else { return }
        let now = Date().timeIntervalSince1970

        lastIndex = index
        switch(index) {
        case 1:
            startTime = now
            os_log("#1 custom char notify", log:.connection)
            scale.setNotifyValue(true, for: chars[BODY_COMPOSITION_CUSTOM1_CHAR_UUID]!)
            break
        case 2:
            os_log("#2 custom unit write", log:.connection)
            scale.writeValue(GATTCustomScaleUnit(unit: ScaleUnit(rawValue: user.unit!)!).compose(),
                             for: chars[BODY_COMPOSITION_CUSTOM2_CHAR_UUID]!, type: .withResponse)
            break
        case 3:
            os_log("#3 user control point notify", log:.connection)
            scale.setNotifyValue(true, for: chars[USER_CONTROL_POINT_CHAR_UUID]!)
            break
        case 4:
            if user.userid == 0 {
                os_log("#4 register an user", log:.connection)
                user.passcode = Int16.random(in: 0...9999)
                let data = GATTUserControlPoint.registerNewUser(passcode: UInt16(user.passcode)).compose()
                os_log("%@", log:.data, data.hexEncodedString(options: .upperCase))
                scale.writeValue(data, for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)
            } else {
                os_log("#4 user is already registered", log:.connection)
                index += 1
            }
        case 5:
            os_log("#5 user control point consent write", log:.connection)
            let consent = GATTUserControlPoint.consent(userID: UInt8(user.userid), passcode: UInt16(user.passcode))
            scale.writeValue(consent.compose(), for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)

            if user.written == false {
                // Gender
                os_log("#5-1 gender write", log:.connection)
                let gender = Gender(rawValue: user.gender!)
                let gattgender = GATTGender.init(gender: (gender == .Male) ? GATTGender.Gender.Male : GATTGender.Gender.Female)
                scale.writeValue(gattgender.compose(), for: chars[USER_GENDER_CHAR_UUID]!, type: .withResponse)

                // Height
                os_log("#5-2 height write", log:.connection)
                let heightFactor = (ScaleUnit(rawValue: user.unit!)! == .Kilogram) ? 1 : Float(2.54)
                let gattheight = GATTHeight.init(height: Float(user.height) * heightFactor)
                scale.writeValue(gattheight.compose(), for: chars[USER_HEIGHT_CHAR_UUID]!, type: .withResponse)

                // Date of Birth
                os_log("#5-3 date of birth write", log:.connection)
                let gattdob = GATTDateOfBirth.init(date: user.date_of_birth!)
                scale.writeValue(gattdob.compose(), for: chars[USER_DATE_OF_BIRTH_CHAR_UUID]!, type: .withResponse)

                // Age
                os_log("#5-4 age write", log:.connection)
                let gattage = GATTAge.init(date_of_birth: user.date_of_birth!)
                scale.writeValue(gattage.compose(), for: chars[USER_AGE_CHAR_UUID]!, type: .withResponse)

                // Athlete Mode
                os_log("#5-5 athlete mode write", log:.connection)
                let gattathlete = GATTCustomAthleteMode.init(mode: GATTCustomAthleteMode.Mode.Normal)
                scale.writeValue(gattathlete.compose(), for: chars[USER_CUSTOM_ATHLETE_MODE_UUID]!, type: .withResponse)

                user.written = true
                do {
                    try user.managedObjectContext!.save()
                } catch {
                }
            }

            break
        case 6:
            os_log("#6 body composition measurement notify", log:.connection)
            scale.setNotifyValue(true, for: chars[BODY_COMPOSITION_MEASUREMENT_CHAR_UUID]!)
            break
        case 7:
            os_log("#7 weight measurement notify", log:.connection)
            scale.setNotifyValue(true, for: chars[WEIGHT_MEASUREMENT_CHAR_UUID]!)
            break
        default:
            os_log("Connection procedure complete in %.2f sec", log:.connection, now - startTime)
            connected = true
            delegate.updated(state: .Connected)
            processTimer?.invalidate()
            return
        }
    }

    var bodyCompositionMeasurementBuffer: Data?

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        guard let delegate = self.delegate else { return }
        guard let user = self.user else { return }

        let uuid = characteristic.uuid
        let hex = data.hexEncodedString(options: .upperCase)
        os_log("%@, %@", log:.data, uuid, hex)
        if characteristic.uuid == USER_CONTROL_POINT_CHAR_UUID {
            let controlPoint = GATTUserControlPoint(data: data)
            guard let response = controlPoint.response else {
                fatalError("Error parsing response")
            }
            if response.operation == .RegisterNewUser {
                if response.value == .Success {
                    if let param = response.parameter {
                        os_log("User is registered %d", log:.connection, param)
                        user.userid = Int16(param)
                        do {
                            try user.managedObjectContext!.save()
                        } catch {
                            os_log("Error registering user", log:.connection)
                        }
                        delegate.updated(state: .UserRegistered)
                        index += 1
                    }
                } else {
                    os_log("Registration failed", log:.connection)

                    if self.deleteUsersAllowed {
                        guard let scale = self.scale else { return }
                        let data = GATTUserControlPoint.deleteAllUsers().compose()
                        os_log("%@", log:.data, data.hexEncodedString(options: .upperCase))
                        scale.writeValue(data, for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)
                        self.deleteUsersAllowed = false
                    }
                }
            } else if response.operation == .DeleteUsers {
                if response.value == .Success {
                    os_log("All users deleted", log:.connection)
                    user.userid = 0
                    user.passcode = 0
                    user.written = false
                    do {
                        try user.managedObjectContext!.save()
                    } catch {
                    }
                    // retry user registration trick
                    lastIndex = 0
                } else {
                    os_log("All users not deleted", log:.connection)
                }
            } else if response.operation == .Consent {
                if response.value == .Success {
                    os_log("User consent success", log:.connection)
                    index += 1
                } else {
                    os_log("User consent not success", log:.connection)
                    user.userid = 0
                    do {
                        try user.managedObjectContext?.save()
                    } catch {
                    }
                    index = 1
                }
            }
        } else if characteristic.uuid == WEIGHT_MEASUREMENT_CHAR_UUID {
            let measurement = GATTWeightMeasurement(data: data)
            delegate.updated(weight: measurement)

            if notifyTimer != nil {
                notifyTimer?.invalidate()
            }

            notifyTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                         selector: #selector(measured), userInfo: nil, repeats: false)
        } else if characteristic.uuid == BODY_COMPOSITION_MEASUREMENT_CHAR_UUID {
            if bodyCompositionMeasurementBuffer == nil {
                let flag = GATTUtil.uint16(data[0], data[1])
                if GATTUtil.flag(flag, 13) { // multipacket flag
                    bodyCompositionMeasurementBuffer = data
                } else {
                    delegate.updated(bodyComposition:GATTBodyCompositionMeasurement(data: data))
                }
            } else {
                bodyCompositionMeasurementBuffer!.append(data)
                let bodyComposition = GATTBodyCompositionMeasurement(data: bodyCompositionMeasurementBuffer!)
                delegate.updated(bodyComposition: bodyComposition)
                delegate.updated(state: .CompositeMeasured)
                bodyCompositionMeasurementBuffer = nil
            }
            os_log("composition %@", log:.data, characteristic.value!.hexEncodedString(options: [.upperCase]))
        } else if characteristic.uuid == BODY_COMPOSITION_CUSTOM1_CHAR_UUID {
            index += 1
        } else {
            os_log("%@", log:.data, characteristic.value!.hexEncodedString(options: [.upperCase]))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateNotificationStateFor", log:.connection)
        index+=1
    }

    @objc func measured() {
        guard let notifyDelegate = self.delegate else { return }

        if let last = weightNotified {
            if (Date().timeIntervalSince(last) < 10) {
                os_log("Too many notification", log:.data)
                return
            }
        }

        notifyDelegate.updated(state: .WeightMeasured)
        weightNotified = Date()
    }

}
