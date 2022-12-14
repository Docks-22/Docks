//
//  DocksDevice.swift
//  Docks
//
//  Created by david on 11/3/22.
//

import Foundation
import CoreBluetooth
import os


let chatServiceID = CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF")
let MAX_PERIPHERALS = 5
let MAX_CENTRALS = 10

class DocksDevice : NSObject, ObservableObject {
    private let centralManager: CBCentralManager
    private let peripheralManager: CBPeripheralManager
    private let queue: DispatchQueue
    private let id = UUID().uuidString
    private let log = Logger()
    private var recv_callback : (String) -> Void
    
    // Central variables
    private var centralCharacteristicMap: Dictionary<UUID, CBCharacteristic>
    // reference to the peripherals we are connected to (if central)
    private var peripherals: [CBPeripheral]
    
    // Peripheral variables
    private var peripheralCharacteristic: CBMutableCharacteristic?
    // reference to centrals we are connected to (if peripheral)
    private var centrals: [CBCentral]
    
    override init() {
        queue = DispatchQueue(label: "bluetooth-discovery",
                                              qos: .background, attributes: .concurrent,
                                              autoreleaseFrequency: .workItem, target: nil)
        centralManager = CBCentralManager(delegate: nil, queue: queue)
        peripheralManager = CBPeripheralManager(delegate: nil, queue: queue)
        peripherals = []
        centralCharacteristicMap = [:]
        centrals = []
        recv_callback = { _ in return} // default callback is a no-op
        super.init()
        
        centralManager.delegate = self
        peripheralManager.delegate = self
        
    }
    
    public func send(msg: String) {
        sendAsPeripheral(msg: msg)
        sendAsCentral(msg: msg)
    }
    
    public func sendAsCentral(msg: String) {
        log.info("Sending message as central \"\(msg)\"")
        let msgData = msg.data(using: .utf8)!

        peripherals.forEach { peripheral in
            let centralCharacteristic = centralCharacteristicMap[peripheral.identifier]!
            peripheral.writeValue(msgData, for: centralCharacteristic, type:.withResponse)
            log.info("sent to peripheral: \(peripheral.identifier)")
        }
        
    }
    
    public func sendAsPeripheral(msg: String) {
        log.info("Sending message as peripheral \"\(msg)\"")
        let msgData = msg.data(using: .utf8)!
        guard let periphCharacteristic = self.peripheralCharacteristic else {
            log.info("No known peripherals, cancelling send")
            return
        }
        
        peripheralManager.updateValue(msgData, for: periphCharacteristic, onSubscribedCentrals: centrals)
        centrals.forEach{ central in
            log.info("sent to centrals: \(central.identifier)")
        }
    }
    
    // return my own UUIDString
    public func get_id() -> String {
        return id
    }
    
    /**
     * Register a function as a callback upon receiving
     */
    public func register_receive_callback(callback_fn: @escaping (String) -> Void) {
        self.recv_callback = callback_fn
        log.info("Registered new callback function on message receipt")
    }
   
}

extension DocksDevice : CBCentralManagerDelegate {
    // Called when the Bluetooth central state changes
    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        guard central.state == .poweredOn else {
            log.error("Unable to start scanning, not powered on")
            return
        }
        log.info("Beginning to scan for peripherals")
        // Start scanning for peripherals
        centralManager.scanForPeripherals(withServices: [chatServiceID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    // Called when a peripheral is detected
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        for periph in peripherals {
            // already connected to peripheral
            if (periph.identifier == peripheral.identifier) {
                return
            }
        }
        
        // Start connecting
        centralManager.connect(peripheral, options: nil)
        
        // Add the connected peripheral to list of connected devices
        self.peripherals.append(peripheral)
        
        // Stop advertising if connected to too many machines
        if (peripherals.count == MAX_PERIPHERALS) {
            log.info("Maximum connections reached as Central, stopping scan")
            centralManager.stopScan();
        }
    }
    
    // called on connection
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.identifier
        log.info("connected to \(name)")
        
        // Configure a delegate for the peripheral
        peripheral.delegate = self
        
        // Scan for peripheral's characteristics
        peripheral.discoverServices([chatServiceID])
        
    }
    
    // called on disconnection
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.info("Disconnected from peripheral \(peripheral.identifier)")
        self.peripherals.removeAll(where: { p in
            return p.identifier == peripheral.identifier
        })
        
        if (peripherals.count == MAX_PERIPHERALS - 1) {
            log.info("Restarting scan")
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF")],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }

    }
}

extension DocksDevice : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // if powered on, start advertising
        guard peripheral.state == .poweredOn else {
            log.error("Unable to start advertising, not powered on")
            return
        }
        
        // Create a characteristic that will allow us to send information
        peripheralCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "f0ab5a15-b003-4653-a248-73fd504c128f"),
                                                           properties: [.write, .notify],
                                                           value: nil,
                                                           permissions: .writeable)
        
        // Create the service to broadcast
        let service = CBMutableService(type: CBUUID(string: "8F383A98-E5B4-44F2-BDC4-E9A41A79D9DF"), primary: true)
        service.characteristics = [self.peripheralCharacteristic!]
        
        // Register the service to this peripheral
        peripheralManager.add(service)
        
        log.info("Starting to advertise as peripheral")
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[chatServiceID],
                                            CBAdvertisementDataLocalNameKey: id])
    }
    
    // on subscription
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.centrals.append(central)
        // if too many centrals, stop searching
        if (self.centrals.count == MAX_CENTRALS) {
            log.info("Maximum connections reached as peripheral, stopping advertising")
            peripheralManager.stopAdvertising();
        }

    }
    
    // on unsubscription
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
        self.centrals.removeAll(where: { c in
            c.identifier == central.identifier
        })
        
        if (self.centrals.count == MAX_CENTRALS - 1) {
            log.info("Restarting advertising")
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[chatServiceID],
                                                CBAdvertisementDataLocalNameKey: id])
        }

    }
    
}

extension DocksDevice : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log.error("Unable to discover service: \(error.localizedDescription)")
            return
        }
        
        peripheral.services?.forEach { service in
            log.info("Found service \(service.uuid)")
            // TODO: may need to check for duplicate services/characteristics
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            log.error("Unable to discover characteristics: \(error.localizedDescription)")
        }
        
        service.characteristics?.forEach { characteristic in
            // subscribe to each characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            
            // Keep a reference to the characteristic for sending data
            self.centralCharacteristicMap[peripheral.identifier] = characteristic
        }
    }
    
    // New data arrived in a characteristic we are subscribed to
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            log.error("Unable to fetch updated characteristic: \(error.localizedDescription)")
        }
        
        guard let data = characteristic.value else { return }
        let msg = String(decoding: data, as: UTF8.self)
        log.info("Received message \"\(msg)\", calling callback function")
        // call callback on msg
        DispatchQueue.main.async {
            self.recv_callback(msg)
        }
    }
    
}
