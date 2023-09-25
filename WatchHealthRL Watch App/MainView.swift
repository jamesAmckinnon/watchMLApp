//
//  ContentView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI
import Charts
import RealmSwift
import UserNotifications


let sevenDayMoods: [DailyMood] = [
    .init(day: "SU", moods: 4.6),
    .init(day: "M", moods: 2.5),
    .init(day: "T", moods: 5.0),
    .init(day: "W", moods: 3.2),
    .init(day: "TH", moods: 3.0),
    .init(day: "F", moods: 2.3),
    .init(day: "S", moods: 3.4),
]

let dataCorrelations: [DataTypeCorrelation] = [
    .init(dataType: "Time asleep", correlation: 0.9, correlationStrength: "Strong +", colour: Color(.green)),
    .init(dataType: "Cals burnt", correlation: -0.2, correlationStrength: "Weak -", colour: Color(.blue)),
    .init(dataType: "Steps", correlation: -0.4, correlationStrength: "Weak -", colour: Color(.gray)),
    .init(dataType: "HRV", correlation: 0.3, correlationStrength: "Weak +", colour: Color(.orange)),
]

public var uiStats: [String: [String: Any]] = [
    "sevenDayAnalysis": [
        "averageMood": 3.4285,
        "moodValues": sevenDayMoods
    ],
    "correlations": [
        "correlationValues": dataCorrelations
    ]
]

struct MainView: View {
    @StateObject var delegate = NotificationDelegate()
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var inferenceManager: InferenceManager
    
    
    @State var sevenDayData: [DailyMood] = []
    @State var dataCorrelationsData: [DataTypeCorrelation] = []
    @State var average: Double = 0.0
    
    @State private var isDataAvailable = false
        
    var body: some View {
        //            realmFileLocation()
        if isDataAvailable {
            TabView() {
                SevenDayView(data: sevenDayData, average: average)
                CorrelationsView(data: dataCorrelationsData)
            }
            .tabViewStyle(.verticalPage)
            .onAppear(perform: {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
                }
                UNUserNotificationCenter.current().delegate = delegate
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                createNotification()
                dataManager.requestAuthorization()
            })
            .background(
                LinearGradient(gradient: Gradient(colors: [.lightGreenBlue, .darkGreenBlue]), startPoint: .top, endPoint: .bottom)
            )
        } else {
            Text("Generating Analysis...")
                .onAppear {
                    Task {
                        inferenceManager.updateUIData(epochDuration: 3600*3) { UIData in
                            if !UIData.isEmpty {
                                dataCorrelationsData = inferenceManager.moodCorrelations
                                sevenDayData = inferenceManager.sevenDayMoods
                                average = inferenceManager.average
                                isDataAvailable = true
                            } else {
                                dataCorrelationsData = uiStats["correlations"]?["correlationValues"] as! [DataTypeCorrelation]
                                sevenDayData = uiStats["sevenDayAnalysis"]?["moodValues"] as! [DailyMood]
                                average = uiStats["sevenDayAnalysis"]?["averageMood"] as! Double
                                isDataAvailable = true
                            }
                            
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [.lightGreenBlue, .darkGreenBlue]), startPoint: .top, endPoint: .bottom)
                )
        }
    }
    
    func createNotification(){
        let content = UNMutableNotificationContent()
        content.title = "Health App"
        content.subtitle = "How are you feeling?"
        content.categoryIdentifier = "ACTIONS"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: true)
        let request = UNNotificationRequest(identifier: "IN-APP", content: content, trigger: trigger)
        
        let one = UNNotificationAction(identifier: "1", title: "1", options: [])
        let two = UNNotificationAction(identifier: "2", title: "2", options: [])
        let three = UNNotificationAction(identifier: "3", title: "3", options: [])
        let four = UNNotificationAction(identifier: "4", title: "4", options: [])
        let five = UNNotificationAction(identifier: "5", title: "5", options: [])

        let category = UNNotificationCategory(identifier: "ACTIONS", actions: [one, two, three, four, five], intentIdentifiers: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func realmFileLocation() -> some View {
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path)
        return Text("")
    }
}

class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @StateObject var realmManager = SavedMoodManager()
    @Published var alert = false
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        
        completionHandler([.badge, .banner, .sound])
    }
    
    // listening to actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        
        let dateTime = Date()
        let mood = Int(response.actionIdentifier) ?? 0
        realmManager.createMood(dateTime: dateTime, mood: mood)
        
        completionHandler()
    }
}
