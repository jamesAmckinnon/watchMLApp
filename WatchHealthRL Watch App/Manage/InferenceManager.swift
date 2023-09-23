//
//  InferenceManager.swift
//  WatchHealthRL Watch App
//
//  Created by James on 2023-09-12.
//

import Foundation
import Algorithms
import SigmaSwiftStatistics


class InferenceManager: NSObject, ObservableObject {
    let dataManager = DataManager()
    let realmManager = SavedMoodManager()
    var correlations: Dictionary<String, Double> = [:]
    
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

    
    func topNCorrelatedVars(n: Int, epochDuration: Double) -> Void{
        
        var aggregatedData: Dictionary<String, Dictionary<DataManager.HashableTuple, Double>> = [:]
        var correlations: Dictionary<String, Double> = [:]
        
        getAllData(epochDuration: epochDuration) { aggregatedDataCopy in
            aggregatedData = aggregatedDataCopy
        
            if aggregatedData.isEmpty {
                aggregatedData = self.testAggregatedData
            }

            let moods = aggregatedData["moods"] ?? [:]
            
//            print(aggregatedData)
            
            for (key, value) in aggregatedData {

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
        }

        self.correlations = correlations
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
}
