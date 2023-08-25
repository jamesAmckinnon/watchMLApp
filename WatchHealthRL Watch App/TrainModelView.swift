//
//  TrainModelView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI
import RealmSwift

struct TrainModelView: View {
//    @ObservedResults(MoodUpdate.self) var moods
    @StateObject var realmManager = SavedMoodManager()
    
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
        }
    }
}

struct TrainModelView_Previews: PreviewProvider {
    static var previews: some View {
        TrainModelView()
    }
}
