//
//  AbstractScale.swift
//  AScale
//
//  Created by Daisuke Sato on 2021/02/12.
//

import Foundation
import CoreBluetooth
import AVFoundation

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

    let RESTORE_KEY = "accessibility-scale-ble-restore-key-1"
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

    func requestAuthorization(user: User?, andScan: Bool = false) {
        print("requestAuthorization")
        self.user = user
        if self.manager == nil {
            self.manager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: RESTORE_KEY])
        }
        if andScan && self.manager.state == .poweredOn {
            start()
        }
    }

    func start() {
        print("start")
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
        guard let delegate = self.delegate else { return }
        print("didUpdatedState")
        delegate.updated(bluetoothState: central.state)

        if central.state == .poweredOn {
            start()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let manager = self.manager else { return }
        print("didDiscover")

        peripheral.delegate = self
        scale = peripheral

        manager.stopScan()
        connect()
    }

    private func connect() {
        print("connect")
        guard let manager = self.manager else { return }
        guard let scale = self.scale else { return }

        manager.connect(scale, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey : NSNumber(value: PERIPHERAL_KEY),
        ])
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("central didConnect")
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
        print("central didDisconnect")
        guard let delegate = self.delegate else { return }
        connected = false
        chars = [:]
        delegate.updated(state: .NotConnected)

        // restart for next measurement
        start()
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("central willRestore")
        if let scales = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            if scales.count > 0 {
                scales[0].delegate = self
                self.scale = scales[0]
            }
        }
    }

    // MARK: CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral didDiscoverServices")

        guard let scale = self.scale else { return }
        guard let services = scale.services else { return }

        for service in services {
            scale.discoverCharacteristics([], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral didDiscoverCharacteristicsFor")
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
            print("Start timer")
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

        print("execute step #\(index) #\(lastIndex)")
        lastIndex = index
        switch(index) {
        case 1:
            startTime = now
            scale.setNotifyValue(true, for: chars[BODY_COMPOSITION_CUSTOM1_CHAR_UUID]!)
            break
        case 2:
            scale.writeValue(GATTCustomScaleUnit(unit: ScaleUnit(rawValue: user.unit!)!).compose(),
                             for: chars[BODY_COMPOSITION_CUSTOM2_CHAR_UUID]!, type: .withResponse)
            break
        case 3:
            scale.setNotifyValue(true, for: chars[USER_CONTROL_POINT_CHAR_UUID]!)
            break
        case 4:
            let delete = false

            if delete {
                let data = GATTUserControlPoint.deleteAllUsers().compose()
                print(data.hexEncodedString(options: .upperCase))
                scale.writeValue(data, for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)

            } else {
                if user.userid == 0 {
                    user.passcode = Int16.random(in: 0...9999)
                    let data = GATTUserControlPoint.registerNewUser(passcode: UInt16(user.passcode)).compose()
                    print(data.hexEncodedString(options: .upperCase))
                    scale.writeValue(data, for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)
                    index += 1
                } else {
                    index += 2
                }
            }
        case 5:
            print("Waiting response")
            break
        case 6:
            let consent = GATTUserControlPoint.consent(userID: UInt8(user.userid), passcode: UInt16(user.passcode))
            scale.writeValue(consent.compose(), for: chars[USER_CONTROL_POINT_CHAR_UUID]!, type: .withResponse)

            if user.written == false {
                // Gender
                let gender = Gender(rawValue: user.gender!)
                let gattgender = GATTGender.init(gender: (gender == .Male) ? GATTGender.Gender.Male : GATTGender.Gender.Female)
                scale.writeValue(gattgender.compose(), for: chars[USER_GENDER_CHAR_UUID]!, type: .withResponse)

                // Height
                let heightFactor = (ScaleUnit(rawValue: user.unit!)! == .Kilogram) ? 1 : Float(2.54)
                let gattheight = GATTHeight.init(height: Float(user.height) * heightFactor)
                scale.writeValue(gattheight.compose(), for: chars[USER_HEIGHT_CHAR_UUID]!, type: .withResponse)

                // Date of Birth
                let gattdob = GATTDateOfBirth.init(date: user.date_of_birth!)
                scale.writeValue(gattdob.compose(), for: chars[USER_DATE_OF_BIRTH_CHAR_UUID]!, type: .withResponse)

                // Age
                let gattage = GATTAge.init(date_of_birth: user.date_of_birth!)
                scale.writeValue(gattage.compose(), for: chars[USER_AGE_CHAR_UUID]!, type: .withResponse)

                // Athlete Mode
                let gattathlete = GATTCustomAthleteMode.init(mode: GATTCustomAthleteMode.Mode.Normal)
                scale.writeValue(gattathlete.compose(), for: chars[USER_CUSTOM_ATHLETE_MODE_UUID]!, type: .withResponse)

                user.written = true
                do {
                    try user.managedObjectContext!.save()
                } catch {
                }
            }

            break
        case 7:
            scale.setNotifyValue(true, for: chars[BODY_COMPOSITION_MEASUREMENT_CHAR_UUID]!)
            break
        case 8:
            scale.setNotifyValue(true, for: chars[WEIGHT_MEASUREMENT_CHAR_UUID]!)
            break
        default:
            print("timer stop, \(now - startTime) sec")
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

        print(characteristic.uuid, data.hexEncodedString(options: .upperCase))
        if characteristic.uuid == USER_CONTROL_POINT_CHAR_UUID {
            let controlPoint = GATTUserControlPoint(data: data)
            guard let response = controlPoint.response else {
                fatalError("Error parsing response")
            }
            if response.operation == .RegisterNewUser {
                if response.value == .Success {
                    if let param = response.parameter {
                        print("User is registered \(param)")
                        user.userid = Int16(param)
                        do {
                            try user.managedObjectContext!.save()
                        } catch {
                            print("Error registering user")
                        }
                        delegate.updated(state: .UserRegistered)
                        index += 1
                    }
                } else {
                    print("Registration failed")
                }
            } else if response.operation == .DeleteUsers {
                if response.value == .Success {
                    print("All users deleted")
                } else {
                    print("All users not deleted")
                }
            } else if response.operation == .Consent {
                if response.value == .Success {
                    print("User consent success")
                    index += 1
                } else {
                    print("User consent not success")
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
                if GATTUtil.flag(flag, 13) {
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
            print("composition "+characteristic.value!.hexEncodedString(options: [.upperCase]))
        } else if characteristic.uuid == BODY_COMPOSITION_CUSTOM1_CHAR_UUID {
            index += 1
        } else {
            print(characteristic.value!.hexEncodedString(options: [.upperCase]))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor")
        index+=1
    }

    @objc func measured() {
        guard let notifyDelegate = self.delegate else { return }

        if let last = weightNotified {
            if (Date().timeIntervalSince(last) < 10) {
                print("Too many notification")
                return
            }
        }

        notifyDelegate.updated(state: .WeightMeasured)
        weightNotified = Date()
    }

}
