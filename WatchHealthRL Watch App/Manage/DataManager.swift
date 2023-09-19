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

public var testSampleData = [
    "heartRate":
        [NSDate(dateString:"2023-09-08") as Date: 78.0, NSDate(dateString:"2023-09-09") as Date: 84.2, NSDate(dateString:"2023-09-10") as Date: 92.0, NSDate(dateString:"2023-09-11") as Date: 75.2],
    "heartRateVariabilitySDNN":
        [NSDate(dateString:"2023-09-08") as Date: 2, NSDate(dateString:"2023-09-09") as Date:4, NSDate(dateString:"2023-09-10") as Date: 5, NSDate(dateString:"2023-09-11") as Date: 3],
    "stepCount":
        [NSDate(dateString:"2023-09-08") as Date: 9940, NSDate(dateString:"2023-09-09") as Date: 2300, NSDate(dateString:"2023-09-10") as Date: 4000, NSDate(dateString:"2023-09-11") as Date: 5400],
    "activeEnergyBurned":
        [NSDate(dateString:"2023-09-08") as Date: 34, NSDate(dateString:"2023-09-09") as Date: 22, NSDate(dateString:"2023-09-10") as Date: 340, NSDate(dateString:"2023-09-11") as Date: 800],
    "basalEnergyBurned":
        [NSDate(dateString:"2023-09-08") as Date: 2030, NSDate(dateString:"2023-09-09") as Date: 1500, NSDate(dateString:"2023-09-10") as Date: 2200, NSDate(dateString:"2023-09-11") as Date: 2980]
]

class DataManager: NSObject, ObservableObject {
    let healthStore = HKHealthStore()
    let realmManager = SavedMoodManager()
    
    
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
                                completion: @escaping (_ samplesDict: Dictionary<String, Dictionary<Date, Double>>) -> Void) {
        let numberOfDataTypes = sampleInfo.count
        var samplesDict: [String: [Date: Double]] = [:]
    
        let dispatchGroup = DispatchGroup()
        
        // Create a DispatchWorkItem to call our completion handler once all our tasks have finished.
        let workItem = DispatchWorkItem() {
            completion(samplesDict)
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
            
            // Tell the dispatch group we have added another async task
            dispatchGroup.enter()
            
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
                        
                        // might have to make a timestamp key with the timestamp and a value key with the sample value
                        dataTypeDictionary[dateStart] = sampleVal
                    }
                    samplesDict[dataTypeName] = dataTypeDictionary
                    
                    // tell the dispatch group this task has been completed
                    dispatchGroup.leave()
                    
                }
            healthStore.execute(query)
            
        }
        dispatchGroup.notify(queue: DispatchQueue.main, work: workItem)
    }
    
    
    func getData(completion: @escaping (Dictionary<String, Dictionary<Date, Double>>) -> Void) {
        let sampleInfo = [
            ("heartRate", HKObjectType.quantityType(forIdentifier: .heartRate), "count/min"),
            ("heartRateVariabilitySDNN", HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN), "s"),
            ("stepCount", HKObjectType.quantityType(forIdentifier: .stepCount), "count"),
            ("activeEnergyBurned", HKObjectType.quantityType(forIdentifier: .activeEnergyBurned), "cal"),
            ("basalEnergyBurned", HKObjectType.quantityType(forIdentifier: .basalEnergyBurned), "cal"),
        ]
        
//        var samplesDict: [String: [Date: Double]] = [:]
            
        self.fetchLatestData(
            sampleInfo: sampleInfo
        ) { samplesDict in
            let allDictionariesEmpty = samplesDict.allSatisfy { (_, value) in value.isEmpty}

            if !allDictionariesEmpty {
                completion(samplesDict)
            } else {
                completion(testSampleData)
            }
        }
    }
    
    
    func getLabels(trainingData: Array<Dictionary<String, Any>>) {
        let moodsSorted = realmManager.moods.sorted(by: {$0.dateTime > $1.dateTime})
        
        for moodItem in moodsSorted {
            let moodDate = moodItem.dateTime
            let mood = moodItem.mood
            var row: [String: Any] = ["mood": mood]
            
            for datapoint in trainingData{
                if let datapointDate = datapoint["timestamp"] as? Date {
                    if moodDate == datapointDate {
                        row.merge(datapoint) { (_, new) in new }
                    }
                }
            }
        }
    }
    
    
    func getAggregattedEpochData(samplesDict: Dictionary<String, Dictionary<Date, Double>>,
                        epochDuration: Double,
                        completion: @escaping (Dictionary<String, Dictionary<HashableTuple, Double>>) -> Void)  {
        let moodsSorted = realmManager.moods.sorted(by: {$0.dateTime > $1.dateTime})
        var unAggregatedData: [String: [HashableTuple: Array<Double>]] = [:]
        var allTimestamps: Set<Date> = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for mood in moodsSorted {
            let timestamp = mood.dateTime
            let moodValue = Double(mood.mood)
            let (date, epochNumber) = getDateAndEpoch(timestamp: timestamp, epochDuration: epochDuration)
            let key = HashableTuple(date, epochNumber)

            if unAggregatedData["moods"] == nil {
                            unAggregatedData["moods"] = [:]
            }
            
            if var existingValues = unAggregatedData["moods"]?[key] {
                existingValues.append(moodValue)
                unAggregatedData["moods"]?[key] = existingValues
            } else {
                unAggregatedData["moods"]?[key] = [moodValue]
            }
            
        }
        
        for innerDictionary in samplesDict.values {
            allTimestamps.formUnion(innerDictionary.keys)
        }
        
        for timestamp in allTimestamps {
            // Iterate through data types.
            for (dataType, innerDictionary) in samplesDict {
                if let value = innerDictionary[timestamp] {
                    let (date, epochNumber) = getDateAndEpoch(timestamp: timestamp, epochDuration: epochDuration)
                    let key = HashableTuple(date, epochNumber)
                    
                    if unAggregatedData[dataType] == nil {
                                    unAggregatedData[dataType] = [:]
                    }
                    
                    if var existingValues = unAggregatedData[dataType]?[key] {
                        existingValues.append(value)
                        unAggregatedData[dataType]?[key] = existingValues
                    } else {
                        unAggregatedData[dataType]?[key] = [value]
                    }
                }
            }
        }
    
        let aggregatedData = aggregateData(unAggregatedData: unAggregatedData)
        
        completion(aggregatedData)
    }
    
    func aggregateData(unAggregatedData: Dictionary<String, Dictionary<HashableTuple, Array<Double>>>)
            -> Dictionary<String, Dictionary<HashableTuple, Double>> {
                
        var aggregatedData: [String: [HashableTuple: Double]] = [:]

        // Iterate through the outer dictionary.
        for (outerKey, innerDictionary) in unAggregatedData {
            var aggregatedInnerDictionary: [HashableTuple: Double] = [:]

            // Iterate through the inner dictionary.
            for (innerKey, valuesArray) in innerDictionary {
                // Calculate the average of the values array.
                let average = valuesArray.reduce(0.0, +) / Double(valuesArray.count)
                aggregatedInnerDictionary[innerKey] = average
            }

            aggregatedData[outerKey] = aggregatedInnerDictionary
        }
                
        return aggregatedData
    }
    
    struct HashableTuple: Hashable {
        let date: Date
        let intValue: Int
        
        init(_ date: Date, _ intValue: Int) {
            self.date = date
            self.intValue = intValue
        }
    }
    
    func getDateAndEpoch(timestamp: Date, epochDuration: Double) -> (Date, Int) {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: timestamp)
        let date = Calendar.current.date(from: dateComponents)
        
        // Calculate the total number of seconds since the start of the day
        let secondsComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: timestamp)
        let secondsSinceStartOfDay = TimeInterval(secondsComponents.hour! * 3600 + secondsComponents.minute! * 60 + secondsComponents.second!)

        // Calculate the epoch number
        let epochNumber = Int(secondsSinceStartOfDay / epochDuration)
        
        return (date!, epochNumber)
    }
    
    
    func getSleepData(dates: Array<Date>,
                      completion: @escaping (Dictionary<HashableTuple, Double>) -> Void) {
        var dataTypeDictionary = [HashableTuple:Double]()
        
        let dispatchGroup = DispatchGroup()
        
        // Create a DispatchWorkItem to call our completion handler once all our tasks have finished.
        let workItem = DispatchWorkItem() {
            completion(dataTypeDictionary)
        }
        
        for date in dates {
            // Predicate for specifiying start and end dates for the query
            let predicate = HKQuery
                .predicateForSamples(
                    withStart: Calendar.current.date(byAdding: .day, value: -1, to: date)!,
                    end: date,
                    options: .strictEndDate)
            
            // Tell the dispatch group we have added another async task
            dispatchGroup.enter()
            
            // Create the query
            let query = HKSampleQuery(
                sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                predicate: predicate,
                limit: Int(HKObjectQueryNoLimit),
                sortDescriptors: nil) { (_, results, error) in
                    
                    guard error == nil else {
                        print("Error: \(error!.localizedDescription)")
                        return
                    }
                    
                    var sleep: Double = 0.0
                    
                    for item in results ?? [] {
                        if let sample = item as? HKCategorySample {
                            let timeInterval = sample.endDate.timeIntervalSince(sample.startDate) / (60 * 60)

                            switch sample.value {
                                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                                    sleep += Double(timeInterval)
                                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                                    sleep += Double(timeInterval)
                                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                                    sleep += Double(timeInterval)
                                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                                    sleep += Double(timeInterval)
                                default: continue
                            }
                        }
                    }
                
                    
                    dataTypeDictionary[HashableTuple(date, 0)] = sleep
                    
                    // Tell the dispatch group this task has been completed.
                    dispatchGroup.leave()
                }
            healthStore.execute(query)
        }
        dispatchGroup.notify(queue: DispatchQueue.main, work: workItem)
    }
    
//    func getSleepData(dates: Array<Date>) async throws -> Dictionary<Date, Double> {
//    func getSleepData(dates: Array<Date>,
//                      completion: @escaping (Dictionary<Date, Double>) -> Void) {
//        let startDate = Date().addingTimeInterval( -(86400) )
//        let endDate = Date()
//
//        // Define the type.
//        let sleepType = HKCategoryType(.sleepAnalysis)
//
//        let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//        let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis
//            .predicateForSamples(equalTo:HKCategoryValueSleepAnalysis.allAsleepValues)
//
//
//        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])
//
//        // Returns a snapshot of all matching samples in the HealthKit store.
//        let descriptor = HKSampleQueryDescriptor(
//            // A predicate is a logical condition that evaluates to a Boolean value.
//            // It can be used to filter a collection of objects.
//            predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
//            sortDescriptors: []
//        )
//
//        do {
//            let results = try await descriptor.result(for: healthStore)
//            var secondsAsleep = 0.0
//            print(results)
//            for result in results {
//                // timeIntervalSince returns the interval between this date and another given date.
//                // This looks at each time window of an asleep category and gets the difference between the start
//                // and end time of that window in seconds and then adds that to the secondsAsleep variable.
//                secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
//            }
//
//            return secondsAsleep
//
//        } catch{
//            return 0.0
//        }
//        var sleepData: [Date: Double] = [:]
//
//        // Define the type.
//        let sleepType = HKCategoryType(.sleepAnalysis)
//
//        var dates = [
//            Calendar.current.date(byAdding: .day, value: -4, to: Date.now)!,
//            Calendar.current.date(byAdding: .day, value: -3, to: Date.now)!,
//            Calendar.current.date(byAdding: .day, value: -2, to: Date.now)!
//        ]
//
//        for date in dates {
//            let startDate = date
//            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
//
//            let dateRangePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//            let allAsleepValuesPredicate = HKCategoryValueSleepAnalysis
//                .predicateForSamples(equalTo: HKCategoryValueSleepAnalysis.allAsleepValues)
//
//            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dateRangePredicate, allAsleepValuesPredicate])
//
//            let descriptor = HKSampleQueryDescriptor(
//                predicates: [.categorySample(type: sleepType, predicate: compoundPredicate)],
//                sortDescriptors: []
//            )
//
//            do {
//                let results = try await descriptor.result(for: healthStore)
//                var secondsAsleep = 0.0
//                print("results: ")
//                print(results)
//
//                for result in results {
//                    secondsAsleep += result.endDate.timeIntervalSince(result.startDate)
//                }
//
//                sleepData[date] = secondsAsleep
//            } catch {
//                print("Error collecting sleep data for \(date)")
//            }
//        }
//
//        return sleepData
//    }
//
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
