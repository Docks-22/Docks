//
//  Device.swift
//  Docks
//
//  Created by david on 11/3/22.
//

import Foundation
import CoreBluetooth
import os

class Device : NSObject, ObservableObject {
//    private(set) public let devices = [Device]()
    private let centralManager: CBCentralManager
    private let peripheralManager: CBPeripheralManager
    private let queue: DispatchQueue
    private let id = Host.current().name ?? UUID().uuidString
    private let log = Logger()
    private var connectedPeripherals: [CBPeripheral]
    
    // Central variables
    private var centralCharacteristic: CBCharacteristic?
    
    // Peripheral variables
    private var peripheralCharacteristic: CBMutableCharacteristic?
    
    override init() {
        queue = DispatchQueue(label: "bluetooth-discovery",
                                              qos: .background, attributes: .concurrent,
                                              autoreleaseFrequency: .workItem, target: nil)
        centralManager = CBCentralManager(delegate: nil, queue: queue)
        peripheralManager = CBPeripheralManager(delegate: nil, queue: queue)
        connectedPeripherals = []
        super.init()
        
        centralManager.delegate = self
        peripheralManager.delegate = self
        
    }
    
//    private func sendCentralData(_ data: Data) {
//        for periph in connectedPeripherals {
//
//        }
//
//    }
    
   
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
        
        for periph in connectedPeripherals {
            // already connected to peripheral
            if (periph.identifier == peripheral.identifier) {
                return
            }
        }
        
        // Start connecting
        centralManager.connect(peripheral, options: nil)
        
        // Add the connected peripheral to list of connected devices
        self.connectedPeripherals.append(peripheral)
//        log.info("Detected peripheral with name \(name)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        var name = peripheral.identifier
        log.info("connected to \(name)")
        
    }
}

extension Device : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // if powered on, start advertising
        guard peripheral.state == .poweredOn else {
            log.error("Unable to start advertising, not powered on")
            return
        }
        
        // Create a characteristic that will allow us to send information
//        peripheralCharacteric = CBMutableCharacteristic(type: CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f"))
        
        
        
        log.info("Starting to advertise as peripheral")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF")],
                                            CBAdvertisementDataLocalNameKey: id])
    }
}
