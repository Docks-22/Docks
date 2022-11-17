//
//  Device.swift
//  Docks
//
//  Created by david on 11/16/22.
//

import Foundation
import CoreBluetooth
import os

class Device : NSObject, ObservableObject {
    private let centralManager: CBCentralManager
    private let peripheralManager: CBPeripheralManager
    private let queue: DispatchQueue
    private let id = Host.current().name ?? UUID().uuidString
    private let log = Logger()
    
    override init() {
        queue = DispatchQueue(label: "bluetooth-discovery",
                                              qos: .background, attributes: .concurrent,
                                              autoreleaseFrequency: .workItem, target: nil)
        centralManager = CBCentralManager(delegate: nil, queue: queue)
        peripheralManager = CBPeripheralManager(delegate: nil, queue: queue)
        super.init()
        
        centralManager.delegate = self
        peripheralManager.delegate = self
    }
   
}

extension Device : CBCentralManagerDelegate {
    // Called when the Bluetooth central state changes
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            log.error("Unable to start scanning, not powered on")
            return
        }
        
        log.info("Beginning to scan for peripherals")

        // Start scanning for peripherals
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF")],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    // Called when a peripheral is detected
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Get the string value of the UUID of this device as the default value
        var name = peripheral.identifier.description

        // Attempt to get the user-set device name of this peripheral
        if let deviceName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            name = deviceName
        }
        
        log.info("Detected peripheral with name \(name)")
    }
}

extension Device : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // if powered on, start advertising
        guard peripheral.state == .poweredOn else {
            log.error("Unable to start advertising, not powered on")
            return
        }
        log.info("Starting to advertise as peripheral")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF")],
                                            CBAdvertisementDataLocalNameKey: id])
    }
}
