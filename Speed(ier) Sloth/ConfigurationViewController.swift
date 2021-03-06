//
//  ConfigurationViewController.swift
//  Speed(ier) Sloth
//
//  Created by Alex Richards on 5/8/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//

import UIKit
import HealthKit

class ConfigurationViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    // MARK: Properties
    
    var selectedActivityType: HKWorkoutActivityType
    
    var selectedLocationType: HKWorkoutSessionLocationType
    
    let activityTypes: [HKWorkoutActivityType] = [.walking, .running, .hiking]
    let locationTypes: [HKWorkoutSessionLocationType] = [.unknown, .indoor, .outdoor]
    
    let WCSess = WCSessionManager.shared
    
    // MARK: IBOutlets
    
    
    @IBOutlet var activityTypePicker: UIPickerView!
    @IBOutlet var locationTypePicker: UIPickerView!
    
    // MARK: Initialization
    
    required init?(coder: NSCoder) {
        selectedActivityType = activityTypes[0]
        selectedLocationType = locationTypes[0]
        
        super.init(coder: coder)
    }
    
    // MARK: UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == activityTypePicker {
            return activityTypes.count
        } else if pickerView == locationTypePicker {
            return locationTypes.count
        }
        
        return 0
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == activityTypePicker {
            return format(activityType: activityTypes[row])
        } else if pickerView == locationTypePicker {
            return format(locationType: locationTypes[row])
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == activityTypePicker {
            selectedActivityType = activityTypes[row]
        } else if pickerView == locationTypePicker {
            selectedLocationType = locationTypes[row]
        }
    }
    
    @IBAction func didTapStartButton() {
        let config = HKWorkoutConfiguration()
        config.activityType = selectedActivityType
        config.locationType = selectedLocationType
        
        WCSess.configuration = config
   
        
        print("start button tapped")
        if let workoutViewController = storyboard?.instantiateViewController(withIdentifier: "WorkoutViewController") as? WorkoutViewController {
            workoutViewController.configuration = WCSess.configuration
            present(workoutViewController, animated: true, completion:nil)
        }
        WCSess.startWatchApp()
    }
}
