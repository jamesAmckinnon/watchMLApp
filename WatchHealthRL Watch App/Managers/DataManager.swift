//
//  DataManager.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-20.
//

import Foundation
import HealthKit
import RealmSwift

public var trainingDataTest = [
    ["timestamp": NSDate(dateString:"2023-09-08"), "stepCount": 0, "heartRate": 109.0, "activeEnergyBurned": 0, "basalEnergyBurned": 0, "heartRateVariabilitySDNN": 0] as [String : Any],
    ["heartRateVariabilitySDNN": 0, "stepCount": 167.0, "timestamp": NSDate(dateString:"2023-09-09"), "activeEnergyBurned": 0, "basalEnergyBurned": 0, "heartRate": 0] as [String : Any],
    ["stepCount": 0, "heartRateVariabilitySDNN": 0, "heartRate": 51.0, "timestamp": NSDate(dateString:"2023-09-10"), "activeEnergyBurned": 0, "basalEnergyBurned": 0] as [String : Any],
    ["stepCount": 0, "heartRateVariabilitySDNN": 0, "heartRate": 95.0, "activeEnergyBurned": 0, "basalEnergyBurned": 0, "timestamp": NSDate(dateString:"2023-09-11")] as [String : Any]
]

class DataManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    
    
    // function to request authorization for our app to read and share any health data our app intends to use
    func requestAuthorization() {
        
        let typesToRead: Set = [
            HKObjectType.categoryType(forIdentifier:   .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        ]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead)
        { (success, error) in
            
        }
    }
    
    
    // look into how functions work in swift
    public func fetchLatestData(sampleInfo: [(String, HKQuantityType?, String)],
                                completion: @escaping (_ samples: Dictionary<String, Dictionary<Date, Double>>) -> Void) {
        
        let numberOfDataTypes = sampleInfo.count
        var resultsDict: [String: [Date: Double]] = [:]
    
        let dispatchGroup = DispatchGroup()
        
        // Create a DispatchWorkItem to call our completion handler once all our tasks have finished.
        let workItem = DispatchWorkItem() {
            completion(resultsDict)
        }
        
        for i in 0..<numberOfDataTypes {
            let dataTypeName = sampleInfo[i].0
            let sampleType = sampleInfo[i].1!
            let unitString = sampleInfo[i].2
            
            var dataTypeDictionary = [Date:Double]()
            // Predicate for specifiying start and end dates for the query
            let predicate = HKQuery
                .predicateForSamples(
                    withStart: Date.distantPast,
                    end: Date.now,
                    options: .strictEndDate)
            
            // Set sorting by date.
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false)
            
            
            dispatchGroup.enter() // Tell the dispatch group we have added another async task
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

                    print("~~- \(String(describing: results?.count)) \(dataTypeName) samples returned")
                    for sample in results ?? [] {
                        let data = sample as! HKQuantitySample
                        let unit = HKUnit(from: unitString)
                        let sampleVal = data.quantity.doubleValue(for: unit)
                        let dateStart = data.startDate
                        
                        // Set seconds to 0
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateStart)
                        components.second = 0
                        let noSecondsTime = calendar.date(from: components)!
                        
                        dataTypeDictionary[noSecondsTime] = sampleVal
                    }
                    resultsDict[dataTypeName] = dataTypeDictionary
                    dispatchGroup.leave() // tell the dispatch group this task has been completed
                    
                }
            
            healthStore.execute(query)
            
        }
        dispatchGroup.notify(queue: DispatchQueue.main, work: workItem)  // MARK: New code
    }
    
    
    func getData() {
        
        let sampleInfo = [
            ("heartRate", HKObjectType.quantityType(forIdentifier: .heartRate), "count/min"),
            ("heartRateVariabilitySDNN", HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN), "s"),
            ("stepCount", HKObjectType.quantityType(forIdentifier: .stepCount), "count"),
            ("activeEnergyBurned", HKObjectType.quantityType(forIdentifier: .activeEnergyBurned), "cal"),
            ("basalEnergyBurned", HKObjectType.quantityType(forIdentifier: .basalEnergyBurned), "cal"),
        ]
            
        self.fetchLatestData(
            sampleInfo: sampleInfo
        ) { samplesDict in
            let sampleCount = samplesDict.count
            print("Sample count: \(sampleCount)")
            if (sampleCount > 0) {
                return samplesDict
            } else {
                return [:]
            }
        }
        
//        self.getSleepData()
        
    }
    
    
    func getLabels(trainingData: Array<Dictionary<String, Any>>) {
        let realmManager = SavedMoodManager()
        let moodsSorted = realmManager.moods.sorted(by: {$0.dateTime > $1.dateTime})
        
        for moodItem in moodsSorted {
            let moodDate = moodItem.dateTime
            let mood = moodItem.mood
            var row: [String: Any] = ["mood": mood]
            
            for datapoint in trainingData{
                if let datapointDate = datapoint["timestamp"] as? Date {
                    print("Mood date: \(moodDate), Datapoint date: \(datapointDate)")
                    if moodDate == datapointDate {
                        row.merge(datapoint) { (_, new) in new }
                    }
                }
            }
        }
    }
    
    
    func formatTrainingData(samplesDict: Dictionary<String, Dictionary<Date, Double>>) -> Array<Dictionary<String, Any>>{
        var trainingData: [[String: Any]] = []
        var allTimestamps: Set<Date> = []
        
        print("getting timestamps...")
        for innerDictionary in samplesDict.values {
            allTimestamps.formUnion(innerDictionary.keys)
        }
        
        print("matching timestamp with results to create rows of data...")
        for timestamp in allTimestamps {
            var row: [String: Any] = ["timestamp": timestamp]

            // Iterate through data types.
            for (dataType, innerDictionary) in samplesDict {
                if innerDictionary.contains(where: { $0.key == timestamp }) {
                    row[dataType] = innerDictionary[timestamp]
                } else {
                    row[dataType] = 0
                }
            }

            // Append the row to the training data list.
            trainingData.append(row)
        }
        
        print("\(trainingData.count) data points.")
    }
    
    
    func getSleepData() async throws -> Double{
        let startDate = Date().addingTimeInterval( -(86400) )
        let endDate = Date()
        
        // Define the type.
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis
            .predicateForSamples(equalTo:HKCategoryValueSleepAnalysis.allAsleepValues)
        

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

extension NSDate
{
    
    convenience
      init(dateString:String) {
          let dateStringFormatter = DateFormatter()
          dateStringFormatter.dateFormat = "yyyy-MM-dd"
          dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
          let d = dateStringFormatter.date(from: dateString)!
          self.init(timeInterval:0, since:d)
    }
 }
