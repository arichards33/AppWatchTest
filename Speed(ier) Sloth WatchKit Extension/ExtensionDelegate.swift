//
//  ExtensionDelegate.swift
//  Speed(ier) Sloth WatchKit Extension
//
//  Created by Alex Richards on 5/8/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//


import WatchKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    // MARK: WKExtensionDelegate
    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "WorkoutInterfaceController", context: workoutConfiguration)])
    }
}

