//
//  ConfigurationInterfaceController.swift
//  Speed(ier) Sloth WatchKit Extension
//
//  Created by Alex Richards on 5/17/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//
import WatchKit
import Foundation
import HealthKit

class ConfigurationInterfaceController: WKInterfaceController {
    // MARK: Properties
    
    var selectedActivityType: HKWorkoutActivityType
    
    var selectedLocationType: HKWorkoutSessionLocationType
    
    let activityTypes: [HKWorkoutActivityType] = [.walking, .running, .hiking]
    
    let locationTypes: [HKWorkoutSessionLocationType] = [.unknown, .indoor, .outdoor]
    
    // MARK: IB Outlets
    
    @IBOutlet var activityTypePicker: WKInterfacePicker!
    
    @IBOutlet var locationTypePicker: WKInterfacePicker!
    
    // MARK: Initialization
    
    override init() {
        selectedActivityType = activityTypes[0]
        selectedLocationType = locationTypes[0]
        
        super.init()
    }
    
    // MARK: Interface Controller Overrides
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Populate the activity type picker
        let activityTypePickerItems: [WKPickerItem] = activityTypes.map {type in
            let pickerItem = WKPickerItem()
            pickerItem.title = format(activityType: type)
            return pickerItem
        }
        activityTypePicker.setItems(activityTypePickerItems)
        
        // Populate the location type picker
        let locationTypePickerItems: [WKPickerItem] = locationTypes.map {type in
            let pickerItem = WKPickerItem()
            pickerItem.title = format(locationType: type)
            return pickerItem
        }
        locationTypePicker.setItems(locationTypePickerItems)
        
        setTitle("Speedier Sloth")
    }
    
    // MARK: IB Actions
    
    @IBAction func activityTypePickerSelectedItemChanged(value: Int) {
        selectedActivityType = activityTypes[value]
    }
    
    @IBAction func locationTypePickerSelectedItemChanged(value: Int) {
        selectedLocationType = locationTypes[value]
    }
    
    @IBAction func didTapStartButton() {
        // Create workout configuration
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = selectedActivityType
        workoutConfiguration.locationType = selectedLocationType
        
        // Pass configuration to next interface controller
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "WorkoutInterfaceController", context: workoutConfiguration)])
    }
    
}

