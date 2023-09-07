//
//  bpmUpdate.swift
//  WatchHealthRL Watch App
//
//  Created by NewMac on 2023-09-06.
//

import Foundation
import RealmSwift

// Make the class a subclass of object. Object is a realm class.
class BpmUpdate: Object, Identifiable {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var dateTime: Date
    @Persisted var bpm: Int
    
    override class func primaryKey() -> String? {
        "id"
    }
}
