//
//  ContentView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI
import RealmSwift
import UserNotifications

struct MainView: View {
    @StateObject var delegate = NotificationDelegate()
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        
        NavigationStack {
            realmFileLocation()
            List {
                NavigationLink("Mood Update") { MoodUpdateView() }
                NavigationLink("Train Model") { TrainModelView() }
            }
        }.onAppear(perform: {
            dataManager.requestAuthorization()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
            }
            
            UNUserNotificationCenter.current().delegate = delegate
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            createNotification()
            dataManager.getData()
        })
    }
    
    func createNotification(){
        let content = UNMutableNotificationContent()
        content.title = "ML Health App"
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
