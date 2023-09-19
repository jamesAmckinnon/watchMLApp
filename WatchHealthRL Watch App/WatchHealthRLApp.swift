//
//  WatchHealthRLApp.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI

@main
struct WatchHealthRL_Watch_AppApp: App {
    @StateObject var dataManager = DataManager()
    @StateObject var inferenceManager = InferenceManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataManager)
                .environmentObject(inferenceManager)
        }
    }
}
