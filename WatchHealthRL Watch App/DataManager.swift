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
    var dataTypeDictionary = [(String, Any)]()
    
    // function to request authorization for our app to read and share any health data our app intends to use
    func requestAuthorization() {
        
        let typesToRead: Set = [
            HKObjectType.categoryType(forIdentifier:   .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead)
        { (success, error) in
            
        }
    }
    
    // look into how functions work in swift
//    public func fetchLatestData(dataTypeName: String, sampleType: HKSampleType, completion: @escaping (_ samples: [HKQuantitySample]?) -> Void) {
    public func fetchLatestData(dataTypeName: String, sampleType: HKSampleType, completion: @escaping (_ samples: Dictionary<Date, Any>?) -> Void) {
//        /// Create sample type for the heart rate
//        guard let sampleType = HKObjectType
//          .quantityType(forIdentifier: .heartRate) else {
//            completion(nil)
//          return
//        }

        // Predicate for specifiying start and end dates for the query
        let predicate = HKQuery
          .predicateForSamples(
            withStart: Date.distantPast,
            end: Date(),
            options: .strictEndDate)

        // Set sorting by date.
        let sortDescriptor = NSSortDescriptor(
          key: HKSampleSortIdentifierStartDate,
          ascending: false)
        
        var complete = false

        // Create the query
        let query = HKSampleQuery(
          sampleType: sampleType,
          predicate: predicate,
          limit: Int(HKObjectQueryNoLimit),
          sortDescriptors: [sortDescriptor]) { (_, results, error) in

            guard error == nil else {
              print("Error: \(error!.localizedDescription)")
              return
            }
            
            var tempDictionary = [Date:Double]()

            for result in results ?? [] {
              let data = result as! HKQuantitySample
              let unit = HKUnit(from: "count/min")
              let heartRateVal = data.quantity.doubleValue(for: unit)
              let dateStart = data.startDate
              
              tempDictionary[dateStart] = heartRateVal
            }

            self.dataTypeDictionary.append((dataTypeName, tempDictionary))
              
        }
        
        healthStore.execute(query)
        completion(self.dataTypeDictionary)
      }
    
    func getData() {
        
        let dataTypeNames = ["heartRate"]
        let sampleTypes = [ HKObjectType.quantityType(forIdentifier: .heartRate) ]
        let numberOfDataTypes = Int(dataTypeNames.count)
        var results: [String: [String: Any]] = [:]
        
        for i in 0...numberOfDataTypes {
            let dataSamples = self.fetchLatestData(dataTypeName: dataTypeNames[i], sampleType: sampleTypes[i] ?? <#default value#>) { samples in
                if samples == nil {
                    print("There was an error fetching heart rate samples.")
                }
            }
            results[dataTypeNames[i]] = dataSamples
        }
        
//        completion(results as? [HKQuantitySample])
        
    }

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
        
            return secondsAsleep
            
        } catch{
            return 0.0
        }
        
    }
    
}
