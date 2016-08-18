//
//  ViewController.swift
//  swift_test
//
//  Created by Trong_iOS on 6/17/16.
//  Copyright © 2016 MroomSoftware. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnScanTouched(sender: AnyObject) {
        let str : String = "{\"ssid\" : \"Robotbase\", \"wpa\" : \"Do@nket201234\", \"product_id\": \"1233QuanXipHong\", \"user_id\" : \"46\", \"user_hash\" : \"annnn\", \"action\" : \"send_wifi_info\" }"
        ZMQController.sharedInstance().sendLocalData(str) { (obj) in
            
        }
    }
    
    @IBAction func btnSendActionTouched(sender: AnyObject) {
        //TODO: need support go outside internet <-- AutonomousZMQ
    }

}

