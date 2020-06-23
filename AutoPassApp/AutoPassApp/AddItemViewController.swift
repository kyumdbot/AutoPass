//
//  AddItemViewController.swift
//  AutoPassApp
//
//  Created by rlbot on 2020/6/4.
//  Copyright © 2020 WL. All rights reserved.
//

import UIKit

class AddItemViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var titleField : UITextField!
    @IBOutlet var passwordField : UITextField!
    @IBOutlet var enterSwitch : UISwitch!
    @IBOutlet var addButton : UIButton!
    
    var onAddedCallback : ((_ title: String, _ password: String, _ appendEnter: Bool) -> Void)?
    

    // MARK: - viewLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    // MARK: - Setup
    
    func setup() {
        setupEnterSwitch()
        setupAddButton()
    }
    
    func setupEnterSwitch() {
        enterSwitch.setOn(true, animated: false)
    }
    
    func setupAddButton() {
        addButton.layer.borderColor = UIColor.systemBlue.cgColor
        addButton.layer.borderWidth = 1
        addButton.layer.cornerRadius = 8
    }
    
    
    // MARK: - Action
    
    @IBAction func pressedCloseButton() {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pressedAddButton() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let appendEnter = enterSwitch.isOn
        
        if title == "" {
            msgBox(title: "訊息：", message: "Title 欄位是不能是空白！")
            return
        }
        if password == "" {
            msgBox(title: "訊息：", message: "Password 欄位是不能是空白！")
            return
        }
        
        if let callback = onAddedCallback {
            callback(title, password, appendEnter)
            onAddedCallback = nil
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UITextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            pressedAddButton()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    
    // MARK: - Tools
    
    func msgBox(title: String, message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
}
