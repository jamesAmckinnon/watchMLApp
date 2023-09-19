//
//  SavedMoodManager.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import Foundation
import RealmSwift

class SavedMoodManager: ObservableObject {
    private(set) var localRealm: Realm?
    @Published private(set) var moods: [MoodUpdate] = []
    
    init() {
        openRealm()
        getMoods()
    }
    
    func openRealm() {
        do {
            let config = Realm.Configuration(schemaVersion: 1)
            
            Realm.Configuration.defaultConfiguration = config
            
            localRealm = try Realm()
            
        } catch {
            print("There was an error opening Realm: \(error)")
        }
    }
    
    func createMood(dateTime: Date, mood: Int){
        if let localRealm = localRealm {
            do {
                try localRealm.write {
                    let newMood = MoodUpdate(value: ["dateTime": dateTime, "mood": mood])
                    
                    localRealm.add(newMood)
                    getMoods()
                    print("Successfully added new note: \(newMood)")
                }
            } catch {
                print("There was an error creating new mood: \(error)")
            }
        }
    }
    
    func getMoods() {
        if let localRealm = localRealm {
            let allMoods = localRealm.objects(MoodUpdate.self)
            moods = []
            allMoods.forEach{ mood in
                moods.append(mood)
            }
        }
    }
}
