//
//  MyBLEDevice.swift
//  AutoPassApp
//
//  Created by rlbot on 2020/5/22.
//  Copyright © 2020 WL. All rights reserved.
//

import Foundation
import CoreBluetooth


class MyBLEDevice: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    
    let prefixName : String
    let maxTextLength = 20
    var isConnected = false
    
    let bleServiceUUID          = "0000BE00-0000-1000-8000-00805F9B34FB"
    let textCharacteristicUUID  = "0000BE01-0000-1000-8000-00805F9B34FB"
    let enterCharacteristicUUID = "0000BE02-0000-1000-8000-00805F9B34FB"
    
    private var centralManager : CBCentralManager!
    private var connectPeripheral : CBPeripheral?
    private var charDictionary = [String: CBCharacteristic]()
    
    private var beginAction : ((_ isReady: Bool) -> Void)?
    private var scanAction  : ((_ device: CBPeripheral) -> Void)?
    private var connectSuccessAction  : ((_ device: CBPeripheral) -> Void)?
    private var connectFailureAction  : ((_ errorString: String) -> Void)?
    private var disconnectDoneAction : (() -> Void)?
    private var charValueUpdatedAction : ((_ uuid: String, _ data: NSData?) -> Void)?
    
    
    init(prefixName: String) {
        self.prefixName = prefixName
    }
    
    
    // MARK: - Methods
    
    func begin(action: ((_ isReady: Bool) -> Void)? ) {
        beginAction = action
        
        let queue = DispatchQueue.global()
        
        //- 將觸發 CBCentralManagerDelegate 的：
        //   func centralManagerDidUpdateState(CBCentralManager)
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    func scan(action: ((_ device: CBPeripheral) -> Void)?) {
        scanAction = action
        
        //- 將觸發 CBCentralManagerDelegate 的：
        //   func centralManager(CBCentralManager, didDiscover: CBPeripheral,
        //                       advertisementData: [String : Any], rssi: NSNumber)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connent(to device: CBPeripheral,
                 success: ((_ device: CBPeripheral) -> Void)?,
                 failure: ((_ errorString: String) -> Void)?)
    {
        connectPeripheral = device
        connectPeripheral!.delegate = self
        connectSuccessAction = success
        connectFailureAction = failure
        
        //- 將觸發 CBCentralManagerDelegate 的：
        //   func centralManager(CBCentralManager, didConnect: CBPeripheral)
        centralManager.connect(connectPeripheral!, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectPeripheral, isConnected == true {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func onDisconnect(action: (() -> Void)?) {
        disconnectDoneAction = action
    }
    
    func characteristicValueChanged(action: ((_ uuid: String, _ data: NSData?) -> Void)?) {
        charValueUpdatedAction = action
    }
    
    //- Send text to peripheral's textCharacteristic
    func sendText(_ text: String) {
        if text == "" {
            return
        }
        
        do {
            let data = text.data(using: .utf8)
            try sendData(data!, uuidString: textCharacteristicUUID, writeType: .withResponse)
        } catch {
            print(error)
        }
    }
    
    //- Send 1 to peripheral's textCharacteristic
    func sendEnter() {
        do {
            let value = 1
            let data = withUnsafeBytes(of: value) { Data($0) }
            try sendData(data, uuidString: enterCharacteristicUUID, writeType: .withResponse)
        } catch {
            print(error)
        }
    }
    
    //- Write value to peripheral
    private func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType) throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        
        connectPeripheral?.writeValue(
            data,
            for: characteristic,
            type: writeType
        )
    }
    
    //- 設定接收 Characteristics 通知
    private func subscribeCharacteristics() {
        print("Subscribe characteristics...")
        if let textCharacteristic = charDictionary[textCharacteristicUUID] {
            connectPeripheral?.setNotifyValue(true, for: textCharacteristic)
        }
        if let enterCharacteristic = charDictionary[enterCharacteristicUUID] {
            connectPeripheral?.setNotifyValue(true, for: enterCharacteristic)
        }
    }
    
    
    // MARK: - CBCentralManager Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var isReady = false
        if central.state == .poweredOn {
            isReady = true
        }
        
        if let action = beginAction {
            DispatchQueue.main.async {
                action(isReady)
                self.beginAction = nil
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let deviceName = peripheral.name, deviceName.hasPrefix(prefixName) == true {
            if let action = scanAction {
                DispatchQueue.main.async {
                    action(peripheral)
                    self.scanAction = nil
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        
        // clear characteristic dictionary
        charDictionary = [:]
        
        //- 將觸發 CBPeripheralDelegate 的：
        //   func peripheral(CBPeripheral, didDiscoverServices: Error?)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        
        var errorString = "ERROR: \(#function)"
        if let err = error {
            errorString += err.localizedDescription
            print(errorString)
        }
        
        if let action = connectFailureAction {
            DispatchQueue.main.async {
                action(errorString)
                self.connectFailureAction = nil
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectPeripheral = nil
        
        if let err = error {
            print("ERROR: \(#function)\n\(err.localizedDescription)")
        }
        
        if let action = disconnectDoneAction {
            DispatchQueue.main.async {
                action()
                self.disconnectDoneAction = nil
            }
        }
    }
    
    
    // MARK: - Connect Action
    
    private func callConnectFailureAction(errorString: String) {
        if let action = connectFailureAction {
            DispatchQueue.main.async {
                action(errorString)
                self.connectFailureAction = nil
                self.connectSuccessAction = nil
            }
        }
    }
    
    private func callConnectSuccessAction(peripheral: CBPeripheral) {
        if let action = connectSuccessAction {
            DispatchQueue.main.async {
                action(peripheral)
                self.connectSuccessAction = nil
                self.connectFailureAction = nil
            }
        }
    }
    
    
    // MARK: - CBPeripheral Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            let errorString = "ERROR: \(#function)\n\(error!.localizedDescription)"
            print(errorString)
            callConnectFailureAction(errorString: errorString)
            return
        }
        
        for service in peripheral.services! {
            print("> BLE Service: \(service.uuid.uuidString)")
            
            //- 將觸發 CBPeripheralDelegate 的：
            //   func peripheral(CBPeripheral, didDiscoverCharacteristicsFor: CBService, error: Error?)
            connectPeripheral!.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            let errorString = "ERROR: \(#function)\n\(error!.localizedDescription)"
            print(errorString)
            callConnectFailureAction(errorString: errorString)
            return
        }

        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("> BLE Service's characteristic: \(uuidString)")
        }
        
        subscribeCharacteristics()
        callConnectSuccessAction(peripheral: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("BLE ERROR> Write value failed: \(error!)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#function)")
            print(">> Characteristic UUID: \(characteristic.uuid.uuidString)")
            print(error!)
            return
        }
    }
    
    //- Peripheral's characteristic value changed
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#function)")
            print(error!)
            return
        }
        
        if let action = charValueUpdatedAction {
            DispatchQueue.main.async {
                if characteristic.uuid.uuidString == self.textCharacteristicUUID {
                    let data = characteristic.value! as NSData
                    action(self.textCharacteristicUUID, data)
                }
                if characteristic.uuid.uuidString == self.enterCharacteristicUUID {
                    action(self.enterCharacteristicUUID, nil)
                }
            }
        }
    }
    
}
