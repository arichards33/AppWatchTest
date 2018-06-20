//
//  WorkoutsDisplayViewController.swift
//  Speed(ier) Sloth
//
//  Created by Alex Richards on 5/17/18.
//  Copyright © 2018 Alex Richards. All rights reserved.
//

import UIKit
import CoreData

class WorkoutsDisplayViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let searchController = UISearchController(searchResultsController: nil)
    var workouts: [NSManagedObject] = []
    var filteredWorkouts: [NSManagedObject] = []
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Workouts"
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "Cell")
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Names"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "WorkOutData")
        
        do {
            workouts = try managedContext.fetch(fetchRequest)
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func save(name: String) {
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let entity =
            NSEntityDescription.entity(forEntityName: "WorkOutData",
                                       in: managedContext)!
        
        let workout = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
        workout.setValue(name, forKeyPath: "distance")
        
        do {
            try managedContext.save()
            workouts.append(workout)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

}

// MARK: - UITableViewDataSource// MARK: - UITableViewDataSour
extension WorkoutsDisplayViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return filteredWorkouts.count
        } else {
            return 1 }
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            let cell =
                tableView.dequeueReusableCell(withIdentifier: "Cell",
                                              for: indexPath)
            if searchController.isActive {
                let workout = filteredWorkouts[indexPath.row]
                
                cell.textLabel?.text = "TEST"
//                    workout.value(forKeyPath: "distance") as? String
                return cell
            } else {
                
                let workout = workouts[indexPath.row]
                
                cell.textLabel?.text = "TeST"
//                    workout.value(forKeyPath: "distance") as? String
                return cell }
    }
}

extension WorkoutsDisplayViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Person")
        
        fetchRequest.predicate = NSPredicate(format: "name = %@", searchController.searchBar.text!)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let result = try context.fetch(fetchRequest)
            print(result)
            for data in result {
                print(data.value(forKey: "name") as! String)
                filteredWorkouts.append(data)
            }
            
            tableView.reloadData()
            
        } catch {
            
            print("Failed")
        }
        
    }
}

