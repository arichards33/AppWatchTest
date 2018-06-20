//
//  WCSessionManager.swift
//  Speed(ier) Sloth
//
//  Created by Alex Richards on 5/14/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import CoreData

public class WCSessionManager: NSObject, WCSessionDelegate {
 
    static let shared = WCSessionManager()

    var wcSessionActivationCompletion : ((WCSession)->Void)?
    var configuration : HKWorkoutConfiguration?

    let healthStore = HKHealthStore()
    var workouts: [NSManagedObject] = []

    override init() {
        super.init()
        print("Starting the WCSession singleton")
        guard WCSession.isSupported() else { return }
        

        let wcSession = WCSession.default
        wcSession.delegate = self
        

    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            if let activationCompletion = wcSessionActivationCompletion {
                activationCompletion(session)
                wcSessionActivationCompletion = nil
            }
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("message received: \(message)")
        
        if message["distance"] != nil && message["calories"] != nil {
            let saveable = message["State"] as! String
            let distance = message["distance"] as! String
            let calories = message["calories"] as! String
            let endDate = message["endDate"] as! Date
            let startDate = message["startDate"] as! Date
            let heartRates = message["heartBeats"] as! [Double]
            
            saveWorkout(distance: distance, calories: calories, endDate: endDate, startDate: startDate, heartBeats: heartRates)
            
        }
        
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }


    func startWatchApp() {
        print("here")
        guard let workoutConfiguration = configuration else { return }
       

        getActiveWCSession { (wcSession) in
            print(wcSession.isWatchAppInstalled)
            if wcSession.activationState == .activated && wcSession.isWatchAppInstalled {
                self.healthStore.startWatchApp(with: workoutConfiguration, completion: { (success, error) in
                    // Handle errors
                })
            }
        }
    }
    
    func getActiveWCSession(completion: @escaping (WCSession)->Void) {
        guard WCSession.isSupported() else { return }
        
        let wcSession = WCSession.default
        wcSession.delegate = self
        
        if wcSession.activationState == .activated {
            completion(wcSession)
        } else {
            wcSession.activate()
            wcSessionActivationCompletion = completion
        }
    }
    
    func saveWorkout(distance: String, calories: String, endDate: Date, startDate: Date, heartBeats: [Double]) {
        DispatchQueue.main.async{
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            print("THIS IS NOT NIL \(managedContext)")
            let entity =
                NSEntityDescription.entity(forEntityName: "WorkOutData",
                                           in: managedContext)!
            
            let workout = NSManagedObject(entity: entity,
                                          insertInto: managedContext)
            
            workout.setValue(distance, forKeyPath: "distance")
            workout.setValue(calories, forKeyPath: "calories")
            workout.setValue(endDate, forKey: "endDate")
            workout.setValue(startDate, forKey: "startDate")
            workout.setValue(heartBeats, forKey: "heartBeatArray")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }

    
    

}


