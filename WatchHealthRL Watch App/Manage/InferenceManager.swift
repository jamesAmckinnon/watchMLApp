//
//  InferenceManager.swift
//  WatchHealthRL Watch App
//
//  Created by James on 2023-09-12.
//

import SwiftUI
import Foundation
import Algorithms
import SigmaSwiftStatistics


class InferenceManager: NSObject, ObservableObject {
    let dataManager = DataManager()
    let realmManager = SavedMoodManager()
    var correlations: Dictionary<String, Double> = [:]
    var aggregatedData: Dictionary<String, Dictionary<DataManager.HashableTuple, Double>> = [:]
    var sevenDayMoods: [DailyMood] = []
    var moodCorrelations: [DataTypeCorrelation] = []
    var average: Double = 0.0
    
    public var testAggregatedData = [
        "moods": [DataManager.HashableTuple(Date.now, 0): 4.0,
                  DataManager.HashableTuple(Date.now, 1): 3.2,
                  DataManager.HashableTuple(Date.now, 2): 3.0],
        "heartRate": [DataManager.HashableTuple(Date.now, 1): 78.5,
                      DataManager.HashableTuple(Date.now, 3): 89.0,
                      DataManager.HashableTuple(Date.now, 5): 75.0],
        "heartRateVariabilitySDNN": [DataManager.HashableTuple(Date.now, 1): 23.0,
                                     DataManager.HashableTuple(Date.now, 2): 43.2,
                                     DataManager.HashableTuple(Date.now, 6): 45.0],
        "stepCount": [DataManager.HashableTuple(Date.now, 6): 3256,
                      DataManager.HashableTuple(Date.now, 3): 567,
                      DataManager.HashableTuple(Date.now, 2): 2300],
        "activeEnergyBurned": [DataManager.HashableTuple(Date.now, 0): 2500,
                               DataManager.HashableTuple(Date.now, 4): 4300,
                            DataManager.HashableTuple(Date.now, 5): 3290],
        "basalEnergyBurned": [DataManager.HashableTuple(Date.now, 0): 1200,
                  DataManager.HashableTuple(Date.now, 5): 3249,
                  DataManager.HashableTuple(Date.now, 7): 2123],
        "sleep": [DataManager.HashableTuple(Date.now, 8): 7.5,
                  DataManager.HashableTuple(Date.now, 3): 6.1,
                  DataManager.HashableTuple(Date.now, 1): 6.6]
    ]
    
    func getAllData(epochDuration: Double,
                    completion: @escaping (Dictionary<String, Dictionary<DataManager.HashableTuple, Double>>) -> Void)  {
        var aggregatedDataCopy: Dictionary<String, Dictionary<DataManager.HashableTuple, Double>> = [:]
        
        dataManager.getData { samplesDict in
            self.dataManager.getAggregattedEpochData(samplesDict: samplesDict, epochDuration: epochDuration) { aggregatedData in
                aggregatedDataCopy = aggregatedData
                
                if let datesDict = aggregatedDataCopy["moods"] {
                    let datesArray = datesDict.keys.map { $0.date }

                    self.dataManager.getSleepData(dates: datesArray) { sleepData in
                        aggregatedDataCopy["sleep"] = sleepData
                    }
                }
            }
            completion(aggregatedDataCopy)
        }
    }

    
    func updateUIData(epochDuration: Double,
                            completion: @escaping (Dictionary<String, Double>) -> Void) -> Void{
        var correlations: Dictionary<String, Double> = [:]
        
        getAllData(epochDuration: epochDuration) { aggregatedDataCopy in
            self.aggregatedData = aggregatedDataCopy
        
            if self.aggregatedData.isEmpty {
                self.aggregatedData = self.testAggregatedData
            }

            let moods = self.aggregatedData["moods"] ?? [:]
            
            for (key, value) in self.aggregatedData {

                if key == "moods" {
                    continue
                }
                
                let featureData = value
                
                let alignedArrays = self.getTimeAlignedArrays(moodData: moods, featureData: featureData )
                let moodArray = alignedArrays[0]
                let featureArray = alignedArrays[1]
                
                if alignedArrays.allSatisfy({ !$0.isEmpty }) {
                    let pearsonCorrelation = Sigma.pearson(x: moodArray, y: featureArray)
                    correlations[key] = pearsonCorrelation
                }
            }
            
            self.dataManager.getAggMoodDayData(moods: moods) { aggedMoods in
                let sortedKeys = aggedMoods.keys.sorted()
                var moodsForTotalAverage: [Double] = []
                
                for moodDay in sortedKeys {
                    let dayOfWeek = self.dayOfWeekName(date: moodDay)
                    let avgMoodDay = aggedMoods[moodDay] ?? 0.0
                    moodsForTotalAverage.append(avgMoodDay)
                    self.sevenDayMoods.append( DailyMood.init(day: dayOfWeek, moods: avgMoodDay) )
                }
                
                var sevenDayMoodAverage = moodsForTotalAverage.reduce(0, +) / Double(moodsForTotalAverage.count)
                
                if sevenDayMoodAverage >= 0.0 {
                    self.average = sevenDayMoodAverage
                } else {
                    self.average = 0.0
                }
            }
            
            for (dataType, cor) in correlations {
                let corStrength = cor > 0.5 ? "Strong" : "Weak"
                let corPosNeg = cor >= 0.0 ? "+" : "-"
                let corString = "\(corStrength) \(corPosNeg)"
                let shortDataType = dataTypeShortNameLookup[dataType]!.0
                let dataTypeColour = dataTypeShortNameLookup[dataType]!.1
                
                self.moodCorrelations.append( 
                    DataTypeCorrelation.init(
                        dataType: shortDataType,
                        correlation: cor,
                        correlationStrength: corString,
                        colour: dataTypeColour
                    )
                )
            }
            completion(correlations)
        }
    }
    
    func getTimeAlignedArrays(moodData: Dictionary<DataManager.HashableTuple, Double>,
                              featureData: Dictionary<DataManager.HashableTuple, Double>) -> Array<Array<Double>>{
        let commonKeys = Set(moodData.keys).intersection(Set(featureData.keys))
        var moodArray: [Double] = []
        var featureArray: [Double] = []
        
        for key in commonKeys {
            moodArray.append(moodData[key]!)
            featureArray.append(featureData[key]!)
        }
        
        return [moodArray, featureArray]
    }
    
    func getLastSevenDaysOfMoods(moods: [Date: Double]) -> [Date: Double] {
        var datesAndAverages: [Date: Double] = [:]
        let calendar = Calendar.current

        for dayOffset in 1...7 {
            if let currentDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                let matchingMoods = moods.filter { moodDate, _ in
                    let moodDateComponents = calendar.dateComponents([.year, .month, .day], from: moodDate)
                    return calendar.isDate(currentDate, inSameDayAs: moodDate) &&
                           currentDateComponents == moodDateComponents
                }
                
                let moodValues = matchingMoods.map { $0.value }
                let averageMood = moodValues.reduce(0, +) / Double(moodValues.count)
                
                datesAndAverages[currentDate] = averageMood
            }
        }

        return datesAndAverages
    }
    
    func dayOfWeekName(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayString = dateFormatter.string(from: date)
        let shortDay = dayLookup[dayString]!

        return shortDay
    }
}

struct DailyMood: Identifiable {
    let day: String
    let moods: Double

    var id: String { day }
}


struct DataTypeCorrelation: Identifiable {
    let dataType: String
    let correlation: Double
    let correlationStrength: String
    let colour: Color

    var id: String { dataType }
}

public let dataTypeShortNameLookup = [
    "heartRate": ("Heart rate", Color(UIColor(red: 240/255, green: 222/255, blue: 54/255, alpha: 1))),
    "heartRateVariabilitySDNN": ("HRV", Color(.orange)),
    "stepCount": ("Steps", Color(UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1))),
    "activeEnergyBurned": ("Cals burnt", Color(.blue)),
    "sleep": ("Time asleep", Color(.green))
]

public let dayLookup = [
    "Monday": "M",
    "Tuesday": "T",
    "Wednesday": "W",
    "Thursday": "TH",
    "Friday": "F",
    "Saturday": "S",
    "Sunday": "SU"
]

