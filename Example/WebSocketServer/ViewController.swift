//
//  ViewController.swift
//  WebSocketServer
//
//  Created by Khazan@foxmail.com on 04/17/2023.
//  Copyright (c) 2023 Khazan@foxmail.com. All rights reserved.
//

import UIKit
import WebSocketServer

class ViewController: UIViewController {
    
    let server = WebSocketServer()
    
    @IBAction func startServer(_ sender: UIButton) {
        self.view.endEditing(true)
        
        var port = portTextField.text
        
        if let port = port,
           port.count > 0 {
            print("on customize port: \(port)")
        } else {
            port = portTextField.placeholder
        }
        
        guard let port = port,
              let port = Int(port)
        else { return }
        
        sender.setTitle("Start", for: .normal)
        sender.setTitle("Close", for: .selected)

        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            server.start(with: self, port: port)
        } else {
            server.stop()
        }
        
    }
    
    
    @IBAction func sendText(_ sender: UIButton) {
        self.view.endEditing(true)
        
        guard let text = self.inputTextField.text else { return }
        
        server.send(text: text)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    @IBOutlet weak var IPAdressLabel: UILabel!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var receivedTextView: UITextView!
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: WebSocketServerDelegate {
    
    func started(on IPAddress: String) {
        self.IPAdressLabel.text = "  IPAddress: " + IPAddress
    }
    
    func didReceive(text: String) {
        self.receivedTextView.text = self.receivedTextView.text + text + "\n"
    }
    
}
