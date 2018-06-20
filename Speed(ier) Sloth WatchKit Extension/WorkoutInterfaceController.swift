//
//  WorkoutInterfaceController.swift
//  Speed(ier) Sloth WatchKit Extension
//
//  Created by Alex Richards on 5/9/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//


import WatchKit
import Foundation
import HealthKit

class WorkoutInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, CLLocationManagerDelegate {
    // MARK: Properties
    
    let healthStore = HKHealthStore()
    
    var workoutSession : HKWorkoutSession?
    
    var activeDataQueries = [HKQuery]()
    
    let parentConnector = ParentConnector()
    
    var workoutStartDate : Date?
    
    var workoutEndDate : Date?
    
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    
    var heartBeats = [Double]()
    
    var workoutEvents = [HKWorkoutEvent]()
    
    var metadata = [String: AnyObject]()
    
    var timer : Timer?
    
    var isPaused = false
    
    private var workoutRouteBuilder: HKWorkoutRouteBuilder!
    
    private var locationManager: CLLocationManager!
    
    var workout: HKWorkout!
    
    // MARK: IBOutlets
    
    @IBOutlet var durationLabel: WKInterfaceLabel!
    
    @IBOutlet var caloriesLabel: WKInterfaceLabel!
    
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    
    @IBOutlet var pauseResumeButton : WKInterfaceButton!
    
    @IBOutlet var markerLabel: WKInterfaceLabel!
    
    @IBOutlet var heartBeatLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Start a workout session with the configuration
        if let workoutConfiguration = context as? HKWorkoutConfiguration {
            do {
                workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
                workoutSession?.delegate = self
                
                workoutStartDate = Date()
                
                healthStore.start(workoutSession!)
            } catch let error as NSError{
                
                print("This is the error \(error)")
            }
        }
    }
    
    // MARK: Totals
    
    private func totalCalories() -> Double {
        return totalEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
    }
    
    private func totalMeters() -> Double {
        return totalDistance.doubleValue(for: HKUnit.meter())
    }
    
    private func setTotalCalories(calories: Double) {
        totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
    }
    
    private func setTotalMeters(meters: Double) {
        totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: meters)
    }
    
    // MARK: IB Actions
    
    @IBAction func didTapPauseResumeButton() {
        if let session = workoutSession {
            switch session.state {
            case .running:
                healthStore.pause(_: session)
            case .paused:
                healthStore.resumeWorkoutSession(_: session)
            default:
                break
            }
        }
    }
    
    @IBAction func didTapStopButton() {
        workoutEndDate = Date()
        
        // End the Workout Session
        healthStore.end(workoutSession!)
    }
    
    @IBAction func didTapMarkerButton() {
        let markerEvent = HKWorkoutEvent(type: .marker, date: Date())
        workoutEvents.append(markerEvent)
        notifyEvent(markerEvent)
    }
    
    // MARK: Convenience
    
    func updateLabels() {
        caloriesLabel.setText(format(energy: totalEnergyBurned))
        distanceLabel.setText(format(distance: totalDistance))
        
        let duration = computeDurationOfWorkout(withEvents: workoutEvents, startDate: workoutStartDate, endDate: workoutEndDate)
        durationLabel.setText(format(duration: duration))
    }
    
    func updateState() {
        if let session = workoutSession {
            switch session.state {
            case .running:
                setTitle("Active Workout")
                parentConnector.send(state: "running", heartBeats: heartBeats)
                pauseResumeButton.setTitle("Pause")
                
            case .paused:
                setTitle("Paused Workout")
                parentConnector.send(state: "running", heartBeats: heartBeats, endDate: workoutEndDate!, startDate: workoutStartDate!, distance: format(distance: totalDistance), calories: format(energy: totalEnergyBurned))
                pauseResumeButton.setTitle("Resume")
                
            case .notStarted, .ended:
                setTitle("Workout")
                parentConnector.send(state: "running", heartBeats: heartBeats, endDate: workoutEndDate!, startDate: workoutStartDate!, distance: format(distance: totalDistance), calories: format(energy: totalEnergyBurned))
            }
        }
    }
    
    func notifyEvent(_: HKWorkoutEvent) {
        weak var weakSelf = self
        
        DispatchQueue.main.async {
            weakSelf?.markerLabel.setAlpha(1)
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter (deadline: .now()+1) {
                weakSelf?.markerLabel.setAlpha(0)
            }
        }
    }
    
    // MARK: Data Queries
    
    func startAccumulatingData(startDate: Date) {
        startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
        startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier.heartRate)
        
        startAccumulationLocationData()
        
        startTimer()
    }
    
    // MARK: HKRoute
    
    func startAccumulationLocationData() {
        guard CLLocationManager.locationServicesEnabled() else {
            return
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        workoutRouteBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
            location.horizontalAccuracy <= kCLLocationAccuracyNearestTenMeters
        }
        
        guard !filteredLocations.isEmpty else {return}
        
        workoutRouteBuilder.insertRouteData(filteredLocations) { (success, error) in
            if !success {
                print("error occured with routing data")
            }
        }
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { query, samples, deletedObjects, queryAnchor, error in
            self.process(samples: samples, quantityTypeIdentifier: quantityTypeIdentifier)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                          predicate: queryPredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
        
        activeDataQueries.append(query)
    }
    
    func process(samples: [HKSample]?, quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, !strongSelf.isPaused else { return }
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                for sample in quantitySamples {
                    if quantityTypeIdentifier == HKQuantityTypeIdentifier.distanceWalkingRunning {
                        let newMeters = sample.quantity.doubleValue(for: HKUnit.meter())
                        strongSelf.setTotalMeters(meters: strongSelf.totalMeters() + newMeters)
                    } else if quantityTypeIdentifier == HKQuantityTypeIdentifier.activeEnergyBurned {
                        let newKCal = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                        strongSelf.setTotalCalories(calories: strongSelf.totalCalories() + newKCal)
                    } else {
                        let heartBeat = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        strongSelf.heartBeatLabel.setText(heartBeat.description + " BPM")
                        strongSelf.heartBeats.append(heartBeat)
                        }
                        
                    
                }
                
                strongSelf.updateLabels()
            }
            print("heart beat array \(self?.heartBeats)")
          
        }
    }
    
    func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        
        activeDataQueries.removeAll()
        locationManager?.stopUpdatingLocation()
        stopTimer()
        
    }
    
    func pauseAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = true
        }
    }
    
    func resumeAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = false
        }
    }
    
    // MARK: Timer code
    
    func startTimer() {
        print("start timer")
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerDidFire),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc func timerDidFire(timer: Timer) {
        print("timer")
        updateLabels()
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    // MARK: HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout session did fail with error: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        workoutEvents.append(event)
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        switch toState {
        case .running:
            if fromState == .notStarted {
                startAccumulatingData(startDate: workoutStartDate!)
            } else {
                resumeAccumulatingData()
            }
            
        case .paused:
            pauseAccumulatingData()
            
        case .ended:
            stopAccumulatingData()
            saveWorkout()
            
        default:
            break
        }
        
        updateLabels()
        updateState()
    }
    
    private func saveWorkout() {
        // Create and save a workout sample
        let configuration = workoutSession!.workoutConfiguration
        let isIndoor = (configuration.locationType == .indoor) as NSNumber
        print("locationType: \(configuration)")
        
        let workout = HKWorkout(activityType: configuration.activityType,
                                start: workoutStartDate!,
                                end: workoutEndDate!,
                                workoutEvents: workoutEvents,
                                totalEnergyBurned: totalEnergyBurned,
                                totalDistance: totalDistance,
                                metadata: [HKMetadataKeyIndoorWorkout:isIndoor]);
        
        healthStore.save(workout) { success, _ in
            if success {
                self.addSamples(toWorkout: workout)
                //ADDING HKROUTE DATA
//                self.workoutRouteBuilder?.finishRoute(with: workout, metadata: nil) { (workoutRoute, error) in
//                    if workoutRoute == nil {
//                        print("Finishing route failed with an error")
//                    }
//                }
            }
        }
        
        // Pass the workout to Summary Interface Controller
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SummaryInterfaceController", context: workout)])
    }
    
    private func addSamples(toWorkout workout: HKWorkout) {
        // Create energy and distance samples
        let totalEnergyBurnedSample = HKQuantitySample(type: HKQuantityType.activeEnergyBurned(),
                                                       quantity: totalEnergyBurned,
                                                       start: workoutStartDate!,
                                                       end: workoutEndDate!)
        
        let totalDistanceSample = HKQuantitySample(type: HKQuantityType.distanceWalkingRunning(),
                                                   quantity: totalDistance,
                                                   start: workoutStartDate!,
                                                   end: workoutEndDate!)
        
       
        // Add samples to workout
        healthStore.add([totalEnergyBurnedSample, totalDistanceSample], to: workout) { (success: Bool, error: Error?) in
            if success {
                // Samples have been added
            }
        }
    }
    
}

