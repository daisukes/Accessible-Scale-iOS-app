//
//  RenphoScale.swift
//  AScale
//
//  Created by Daisuke Sato on 2021/02/12.
//

import Foundation
import CoreBluetooth
import AVFoundation
import UserNotifications

class RenphoScale: Scale, CBCentralManagerDelegate, CBPeripheralDelegate {

    let BODY_COMPOSITION_SERVICE_UUID = CBUUID(string: "0000181B-0000-1000-8000-00805f9b34fb")
    let USER_DATA_SERVICE_UUID =        CBUUID(string: "0000181C-0000-1000-8000-00805f9b34fb")
    let WEIGHT_SCALE_SERVICE_UUID =     CBUUID(string: "0000181D-0000-1000-8000-00805f9b34fb")

    let BODY_COMPOSITION_MEASUREMENT_CHAR_UUID = CBUUID(string: "00002A9C-0000-1000-8000-00805f9b34fb")
    let WEIGHT_MEASUREMENT_CHAR_UUID =           CBUUID(string: "00002A9D-0000-1000-8000-00805f9b34fb")
    let USER_CONTROL_POINT_CHAR_UUID =           CBUUID(string: "00002A9F-0000-1000-8000-00805f9b34fb")

    let START_COMMAND = "0201 061A"
    let PERIPHERAL_KEY = 5939990259

    var bodyCompositionMeasurementChar: CBCharacteristic?
    var weightMeasurementChar: CBCharacteristic?
    var userControlPointChar: CBCharacteristic?

    var timer: Timer?
    var weight: Float = 0
    var unit: Unit = .KiloGram

    override init() {
        print("init")
        super.init()
        if self.manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil, options:[
                CBCentralManagerOptionRestoreIdentifierKey: RESTORE_KEY
            ])
        }
        if manager.state == .poweredOn {
            manager.scanForPeripherals(withServices: [WEIGHT_SCALE_SERVICE_UUID], options: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")

        guard let delegate = self.delegate else { return }

        switch(central.state) {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            delegate.updated(state: .NotConnected)
            break
        case .poweredOn:
            central.scanForPeripherals(withServices: [WEIGHT_SCALE_SERVICE_UUID], options: nil)
            break
        @unknown default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("central didDiscover")
        peripheral.delegate = self
        scale = peripheral

        guard let manager = self.manager else {
            return
        }
        manager.stopScan()
        manager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey : NSNumber(value: PERIPHERAL_KEY),
        ])
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("central didConnect")
        guard let delegate = self.delegate else { return }

        delegate.updated(state: .Connected)

        index = 0
        guard let scale = self.scale else {
            return
        }

        scale.discoverServices([BODY_COMPOSITION_SERVICE_UUID, USER_DATA_SERVICE_UUID, WEIGHT_SCALE_SERVICE_UUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("central didDisconnectPeripheral")

        bodyCompositionMeasurementChar = nil
        weightMeasurementChar = nil
        userControlPointChar = nil
        if let timer = timer {
            timer.invalidate()
        }
        timer = nil
        weight = 0
        central.scanForPeripherals(withServices: [WEIGHT_SCALE_SERVICE_UUID], options: nil)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("central willRestore")
        if let scale = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            self.scale = scale[0]
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral didDiscoverServices")
        guard let scale = self.scale else { return }
        guard let services = peripheral.services else { return }

        for service in services {
            scale.discoverCharacteristics([], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("peripheral didDiscoverCharacteristicsFor")
        guard let chars = service.characteristics else { return }

        for char in chars {
            if char.uuid == BODY_COMPOSITION_MEASUREMENT_CHAR_UUID {
                bodyCompositionMeasurementChar = char
            }
            if char.uuid == WEIGHT_MEASUREMENT_CHAR_UUID {
                weightMeasurementChar = char
            }
            if char.uuid == USER_CONTROL_POINT_CHAR_UUID {
                userControlPointChar = char
            }
        }

        if bodyCompositionMeasurementChar != nil &&
            weightMeasurementChar != nil &&
            userControlPointChar != nil {
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        }
    }

    @objc func fireTimer() {
        nextStep()

        if weight == 0 {
            return
        }
        let utterance = AVSpeechUtterance(string: "\(weight)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        weight = 0
    }

    func nextStep() {
        guard let scale = self.scale else { return }

        while(true) {
            switch(index) {
            case 0:
                // start notification
                //scale.setNotifyValue(true, for: bodyCompositionMeasurementChar!)
                scale.setNotifyValue(true, for: weightMeasurementChar!)
                scale.setNotifyValue(true, for: userControlPointChar!)
                break
            case 1:
                scale.writeValue(dataWithHexString(hex: START_COMMAND), for: userControlPointChar!, type: .withResponse)
                break
            /*
             case 2:
             scale.writeValue(dataWithHexString(hex: "13 09 15 01 10 00 00 00 00", checksum: true),
             for: custom3Char!, type: .withoutResponse)
             break
             case 3:
             let timeInterval: Int32 = Int32(Date().timeIntervalSince1970 - SCALE_UNIX_TIMESTAMP_OFFSET)
             // todo send time
             let data = dataWithHexString(hex: "02 "+Data(withUnsafeBytes(of: timeInterval.bigEndian, Array.init)).hexEncodedString(options: .upperCase), checksum: false)
             scale.writeValue(data, for: custom4Char!, type: .withoutResponse)
             break*/
            default:
                timer?.invalidate()
                return
            }
            index += 1
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("peripheral didUpdateValueFor")
        guard let data = characteristic.value else { return }
        guard let delegate = self.delegate else { return }

        if characteristic.uuid == WEIGHT_MEASUREMENT_CHAR_UUID {
            let unitFlag = (data[0] & 0x01)
            let unit:Unit = (unitFlag == 0) ? .KiloGram : .Pound
            let factor:Float = (unitFlag == 0) ? 0.05 : 0.01
            let weight = (Float(data[2]) * 256.0 + Float(data[1])) * factor

            self.weight = weight
            self.unit = unit

            print(data.hexEncodedString(options: .upperCase))

            delegate.updated(weight: weight, unit: unit)

            if timer != nil {
                timer?.invalidate()
            }

            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self,
                                         selector: #selector(measured), userInfo: nil, repeats: false)
        } else {
            print(characteristic.value!.hexEncodedString(options: [.upperCase]))
        }
    }

    @objc func measured() {
        guard let notifyDelegate = self.delegate else { return }

        notifyDelegate.updated(state: .WeightMeasured)
    }
}
