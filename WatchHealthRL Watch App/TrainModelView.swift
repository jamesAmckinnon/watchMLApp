//
//  TrainModelView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI
import RealmSwift

struct TrainModelView: View {
    @StateObject var realmManager = SavedMoodManager()
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var inferenceManager: InferenceManager
    @State var topNCor: Dictionary<String, Double> = [:]
    
    
    var body: some View {
        VStack {
            if(realmManager.moods.count < 1) {
                Image(systemName: "square.and.pencil")
                Text("Update your mood \(1 - realmManager.moods.count) more times to train agent")
            }
             else {
                List(realmManager.moods.sorted(by: {$0.dateTime > $1.dateTime})) {mood in
                    VStack {
                        Text(mood.dateTime, style: .date) +
                        Text(" ") +
                        Text(String(mood.mood))
                    }
                }
            }
            Button (
                "Get labels",
                action: {
//                    Task {
//                        inferenceManager.topNCorrelatedVars(n: 3, epochDuration: 3600*3)
//                    }
//                    Task {
//                        dataManager.getSleepData()
//
//                    }
                }
            )
            List {
                ForEach(Array(topNCor.keys), id: \.self) { key in
                    VStack {
                        Text(key)
                        Text(String(topNCor[key] ?? 0.0))
                    }
                } 
            }
        }
    }
}

struct TrainModelView_Previews: PreviewProvider {
    static var previews: some View {
        TrainModelView()
    }
}
