//
//  AbstractScale.swift
//  AScale
//
//  Created by Daisuke Sato on 2021/02/12.
//

import Foundation
import CoreBluetooth
import UserNotifications

protocol ScaleDelegate {
    func updated(state: Scale.State)
    func updated(weight: Float32, unit: Unit)
    func updated(fat: Float32)
}

class Scale: NSObject {
    enum State {
        case NotConnected
        case Connected
        case WeightMeasured
        case CompositeMeasured
        case Idle
    }

    var manager: CBCentralManager!
    let RESTORE_KEY = "accessibility-scale-ble-restore-key-1"
    var delegate: ScaleDelegate?
    var scale: CBPeripheral?
    var index: Int = 0
    var weightUnit: Unit = .KiloGram
    var measureComposite: Bool = false

    func measureComposite(flag: Bool) {
        self.measureComposite = flag
    }    
}
