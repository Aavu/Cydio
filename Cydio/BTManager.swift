//
//  BTManager.swift
//  Cydio
//
//  Created by Raghavasimhan Sankaranarayanan on 11/20/19.
//  Copyright © 2019 Aavu. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BTManagerDelegate {
    func BTManagerDidReceiveData(_ data:UInt8)
    func BTManagerDidReceiveError(_ error:Error)
}

class BTManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var CydioPeripheral: CBPeripheral!
    
    let cydioServiceCBUUID = CBUUID(string: "4e218cc7-d49f-4a94-96d9-9e517842ded7")
    let cydioSeatSensorCBUUID = CBUUID(string: "92546bf6-864d-403d-9d95-941b4d34693a")
    
    var delegate: BTManagerDelegate?
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
          print("central state is powered off")
        case .poweredOn:
          print("central state is poweredOn")
          centralManager.scanForPeripherals(withServices: [cydioServiceCBUUID])
        case .resetting:
          print("central state is resetting")
        case .unauthorized:
          print("central state is unauthorized")
        case .unknown:
          print("central state is unknown")
        case .unsupported:
          print("central state is unsupported")
        default:
          print("Default case")
        }
      }
      
      func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "peripheral")!")
        peripheral.discoverServices(nil)
      }
      
      func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
          peripheral.discoverCharacteristics(nil, for: service)
        }

      }
      
      func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
    //      print(characteristic)
    //      if characteristic.properties.contains(.read) {
    //        print("\(characteristic.uuid): properties contains .read")
    //        peripheral.readValue(for: characteristic)
    //      }
          if characteristic.properties.contains(.notify) {
    //        print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic)
          }
        }
      }
      
      func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case cydioSeatSensorCBUUID:
            print(characteristic.value?.first ?? "no value")
            if let delegate = delegate {
                delegate.BTManagerDidReceiveData(characteristic.value?.first ?? 0)
                
            }
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
      }
      
      func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        CydioPeripheral = peripheral
        CydioPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(CydioPeripheral)
      }
}
