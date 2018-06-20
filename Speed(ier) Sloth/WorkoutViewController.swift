//
//  WorkoutViewController.swift
//  Speed(ier) Sloth
//
//  Created by Alex Richards on 5/8/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//

import Foundation

import UIKit
import HealthKit
import WatchConnectivity

class WorkoutViewController: UIViewController {
    // MARK: Properties
    
    var configuration : HKWorkoutConfiguration?
    let healthStore = HKHealthStore()
    var wcSessionActivationCompletion : ((WCSession)->Void)?
    let WCSess = WCSessionManager.shared
    
    @IBOutlet var workoutSessionState : UILabel!
    @IBOutlet weak var finishedButton: UIButton!
    
    // MARK: UIViewController
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    func updateSessionState(_ state: String) {
        DispatchQueue.main.async {
            self.workoutSessionState.text = state
        }
    }
    
    @IBAction func dismissView(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}


