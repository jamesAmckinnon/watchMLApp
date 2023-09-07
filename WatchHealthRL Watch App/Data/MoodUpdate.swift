//
//  MoodUpdate.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import Foundation
import RealmSwift

// The way we indicate that we want to save instances of this class into a realm file
// is we have to make the class a subclass of object. Object is a realm class.
class MoodUpdate: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var dateTime: Date
    @Persisted var mood: Int
    
    override class func primaryKey() -> String? {
        "id"
    }
    
}
