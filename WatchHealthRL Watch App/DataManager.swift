//
//  DataManager.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-20.
//

import Foundation
import HealthKit

class DataManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    
    // function to request authorization for our app to read and share any health data our app intends to use
    func requestAuthorization() {
//        ** Heart rate
//        Heart rate variability
//        Resting heart rate
//        active energy burned
//        basal energy burned
//        stepCount
//        Body temperature

        
        let typesToRead: Set = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead)
        { (success, error) in
            
        }
    }
    
    @Published var sleep: Double = 0
    
    
    func sleepTime() async throws -> Double{
        let startDate = Date().addingTimeInterval( -(86400) )
        let endDate = Date()
        
        // Define the type.
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis
            .predicateForSamples(equalTo:HKCategoryValueSleepAnalysis.allAsleepValues)
        
        // Combines two predicates with AND. Here it combines dateRangePredicate and allAsleepValuesPredicate:
        // (
        //   endDate >= CAST(712849305.401525, "NSDate") AND endDate < CAST(712892505.401525, "NSDate")
        //   AND
        //   startDate < CAST(712892505.401525, "NSDate") AND offsetFromStartDate >= CAST(712849305.401525, "NSDate")
        // )
        //   AND
        // (
        //   value == 5 OR value == 4 OR value == 1 OR value == 3
        // )
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])
        
        // Returns a snapshot of all matching samples in the HealthKit store.
        let descriptor = HKSampleQueryDescriptor(
            // A predicate is a logical condition that evaluates to a Boolean value.
            // It can be used to filter a collection of objects.
            predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
            sortDescriptors: []
        )
        
        do {
            let results = try await descriptor.result(for: healthStore)
            var secondsAsleep = 0.0
            for result in results {
                // timeIntervalSince returns the interval between this date and another given date.
                // This looks at each time window of an asleep category and gets the difference between the start
                // and end time of that window in seconds and then adds that to the secondsAsleep variable.
                secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
            }
        
            self.sleep = secondsAsleep
            return secondsAsleep
            
        } catch{
            return 0.0
        }
        
    }
    
}
