//
//  BLEDevicesViewController.swift
//  AutoPassApp
//
//  Created by rlbot on 2020/5/23.
//  Copyright © 2020 WL. All rights reserved.
//

import UIKit
import CoreBluetooth


class BLEDevicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    
    var bleDevice : MyBLEDevice!
    var onCloseCallback : ((_ deviceName: String) -> Void)?
    
    private var devices = [CBPeripheral]()
    
    
    // MARK: - viewLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        searchBleDevices()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("BLEDevicesVC => viewDidDisappear(_:)")
        print("> bleDevice.isConnected: \(bleDevice.isConnected)")
        
        if bleDevice.isConnected == false {
            bleDevice.stopScan()
        }
    }
    
    
    // MARK: - Setup
    
    func setup() {
        setupTableView()
    }
    
    func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshTable() {
        bleDevice.stopScan()
        devices.removeAll()
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.tableView.refreshControl?.endRefreshing()
            self.searchBleDevices()
        })
    }
    
    
    // MARK: - BLE Devices
    
    func searchBleDevices() {
        print("Search BLE Devices:")
        bleDevice.scan() { [weak self] (device) in
            print("> Device: \(device.name ?? "") (\(device.identifier.uuidString))")
            self?.addToDevices(device)
        }
    }
    
    func addToDevices(_ device: CBPeripheral) {
        if !devicesContains(device) {
            devices.append(device)
            tableView.reloadData()
        }
    }
    
    func devicesContains(_ device: CBPeripheral) -> Bool {
        for item in devices {
            if item.name == device.name && item.identifier.uuidString == device.identifier.uuidString {
                return true
            }
        }
        return false
    }

    func connectToDevice(_ device: CBPeripheral) {
        bleDevice.connent(to: device, success: { [weak self] _ in
            let deviceName = device.name ?? ""
            self?.dismiss(animated: true, completion: { self?.callOnCloseCallbackWith(deviceName: deviceName) })
        }, failure: { [weak self] (errorString) in
            self?.msgBox(title: "ERROR: ", message: errorString)
        })
    }
    
    private func callOnCloseCallbackWith(deviceName: String) {
        if let callback = onCloseCallback {
            callback(deviceName)
            onCloseCallback = nil
        }
    }
    
    
    // MARK: - UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceCell", for: indexPath)
        
        let device = devices[indexPath.row]
        cell.selectionStyle = .default
        cell.textLabel?.text = "\(device.name ?? "")"
        cell.detailTextLabel?.text = "UUID: \(device.identifier.uuidString)"
        
        return cell
    }
    
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        let alertController = UIAlertController(title: "使用這個裝置：", message: "\"\(device.name ?? "")\"", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "確定", style: .default) { _ in
            self.connectToDevice(device)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            self.tableView.reloadData()
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Tools
    
    func msgBox(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
}
