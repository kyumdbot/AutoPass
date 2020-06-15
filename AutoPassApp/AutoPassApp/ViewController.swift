//
//  ViewController.swift
//  AutoPassApp
//
//  Created by rlbot on 2020/5/20.
//  Copyright © 2020 WL. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData
import LocalAuthentication


class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var msgLabel : UILabel!
    @IBOutlet var deviceDisconnectButton : UIButton!
    
    var items : [Item]?
    let bleDevice = MyBLEDevice(prefixName: "AutoPass")
    var sendEnterKey = false
    

    // MARK: - viewLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        weak var weakSelf = self
        bleDevice.begin() { isReady in
            print("BLE Ready: \(isReady)")
            if isReady {
                weakSelf?.showBLEDevicesViewController()
            } else {
                weakSelf?.msgBox(title: "訊息：", message: "請到系統設定裡開啟藍牙。")
            }
        }
    }
    
    // MARK: - Setup
    
    func setup() {
        self.title = "AutoPass"
        setupMsgLael()
        setupDeviceDisconnectButton()
        setupLeftBarButtonItem()
        setupRightBarButtonItem()
        setupTableView()
    }
    
    func setupMsgLael() {
        msgLabel.adjustsFontSizeToFitWidth = true
        msgLabel.text = "Connect to:"
    }
    
    func setupDeviceDisconnectButton() {
        deviceDisconnectButton.layer.borderColor = UIColor.systemBlue.cgColor
        deviceDisconnectButton.layer.borderWidth = 1
        deviceDisconnectButton.layer.cornerRadius = 7
    }
    
    func setupLeftBarButtonItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "scan", style: .plain, target: self, action: #selector(pressedScanBarButton))
    }
    
    func setupRightBarButtonItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(pressedNewItemBarButton))
    }
    
    func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    
    // MARK: - BLE
    
    func showBLEDevicesViewController() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "BLEDevicesVC") as! BLEDevicesViewController
        vc.bleDevice = bleDevice
        
        weak var weakSelf = self
        vc.onCloseCallback = { deviceName in
            print("Close BLEDevicesViewController...")
            weakSelf?.msgLabelShowDeviceName(deviceName)
            weakSelf?.setBLEDeviceValueChangedCallback()
            weakSelf?.setBLEDeviceOnDisconnectCallback()
            weakSelf?.reloadTable()
        }
        present(vc, animated: true, completion: nil)
    }
    
    func msgLabelShowDeviceName(_ deviceName: String) {
        let text = "Connect to : \(deviceName)" as NSString
        let attrString = NSMutableAttributedString(string: text as String)
        
        attrString.addAttribute(.font,
                                value: UIFont.systemFont(ofSize: 17),
                                range: NSRange(location: 0, length: text.length))
        
        attrString.addAttribute(.font,
                                value: UIFont.boldSystemFont(ofSize: 17),
                                range: text.range(of: deviceName))
        
        attrString.addAttribute(.foregroundColor,
                                value: UIColor(red: 1.0/255, green: 152.0/255, blue: 88.0/255, alpha: 1),
                                range: text.range(of: deviceName))
        
        msgLabel.attributedText = attrString
    }
    
    func setBLEDeviceValueChangedCallback() {
        weak var weakSelf = self
        bleDevice.characteristicValueChanged(action: { uuid, data in
            print("BLEDevice's characteristic value changed:")
            weakSelf?.bleValueChanged(uuid: uuid, data: data)
        })
    }
    
    func bleValueChanged(uuid: String, data: NSData?) {
        if uuid == self.bleDevice.textCharacteristicUUID {
            //let str = "TEXT> " + String(data: data! as Data, encoding: .utf8)!
            //print(str)
            print("TEXT>")
            if sendEnterKey {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.bleDevice.sendEnter()
                })
            }
        }
        if uuid == self.bleDevice.enterCharacteristicUUID {
            print("<ENTER>")
        }
    }
    
    func setBLEDeviceOnDisconnectCallback() {
        weak var weakSelf = self
        bleDevice.onDisconnect(action: {
            print("BLEDevice disconnected.")
            weakSelf?.showBLEDevicesViewController()
            weakSelf?.msgLabelShowDeviceName("")
            weakSelf?.clearItems()
        })
    }
    
    func clearItems() {
        items = nil
        tableView.reloadData()
    }
    
    // MARK: - Scan BarButton
    
    @objc func pressedScanBarButton() {
        self.showBLEDevicesViewController()
    }

    
    // MARK: - Add Item
    
    @objc func pressedNewItemBarButton() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AddItemVC") as! AddItemViewController
        weak var weakSelf = self
        vc.onAddedCallback = { title, password, appendEnter in
            weakSelf?.addItem(title: title, password: password, appendEnter: appendEnter)
        }
        present(vc, animated: true, completion: nil)
    }
    
    func addItem(title: String, password: String, appendEnter: Bool) {
        StoreHelper.shared.insertItem(title: title, password: password, appendEnter: appendEnter)
        StoreHelper.shared.save()
        reloadTable()
    }
    
    
    // MARK: - Reload Table
    
    func reloadTable() {
        items = StoreHelper.shared.queryAll()
        tableView.reloadData()
    }
    
    
    // MARK: - UITableView DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)
        cell.selectionStyle = .default
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .lightGray
        
        if let item = items?[indexPath.row] {
            cell.textLabel?.text = "👉  \(item.title ?? "")"
            if item.appendEnter {
                cell.detailTextLabel?.text = "append <ENTER>"
            } else {
                cell.detailTextLabel?.text = ""
            }
        } else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            StoreHelper.shared.deleteItem(item)
            StoreHelper.shared.save()
            items?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "刪除"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            if let passwd = item.password {
                authBiometricsAndSendPasswordToBLEDevice(password: passwd, appendEnter: item.appendEnter)
            }
        }
    }
    
    
    // MARK: - Touch ID or Face ID
    
    func authBiometricsAndSendPasswordToBLEDevice(password: String, appendEnter: Bool) {
        let localAuthContext = LAContext()
        var authError: NSError?
        sendEnterKey = false
        
        if localAuthContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            let reason = "需要使用裝置的生物識別解鎖(TouchID 或 FaceID)。"
            localAuthContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.sendEnterKey = appendEnter
                        self.bleDevice.sendText(password)
                        self.msgBox(title: "訊息：", message: "解鎖成功。")
                    } else {
                        self.msgBox(title: "Error 訊息：", message: error?.localizedDescription ?? "解鎖失敗！")
                    }
                }
            }
        } else {
            msgBox(title: "Error 訊息：", message: authError?.localizedDescription ?? "無法使用此裝置的生物識別(TouchID 或 FaceID)！")
        }
    }
    
    
    // MARK: - Action
    
    @IBAction func pressedDisconnectButton() {
        bleDevice.disconnect()
    }
    
    
    // MARK: - Tools
    
    func msgBox(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
}
