//
//  MoodUpdateView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-08-19.
//

import SwiftUI
import RealmSwift

struct MoodUpdateView: View {
    
    @StateObject var realmManager = SavedMoodManager()
    @State var mood: Int = -1
    @State var dateTime: Date = Date()
    
    var body: some View {
        VStack{
            Text("Mood")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
            
            Spacer()
            
            HStack(spacing: 5) {
                ForEach(1...5, id: \.self) { value in
                    Button("\(value)") {
                        mood = value // Update the mood state
                    }
                    .buttonStyle(MoodButtonStyle(selected: mood == value))
                }
            }
            
            Spacer()
            
            if mood != -1 {
                Button(action:{
                    dateTime = Date()
                    realmManager.createMood(dateTime: dateTime, mood: mood)
                    mood = -1
                }) {
                    Text("Submit")
                }
                .buttonBorderShape(.roundedRectangle(radius: 4))
                .padding(.bottom)
            }
        }
        .padding()
    }
}

struct MoodButtonStyle: ButtonStyle {
    var selected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(selected ? .white : .blue)
            .padding()
            .background(selected ? Color.blue : Color.clear)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 1)
            )
    }
}

struct MoodUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        MoodUpdateView()
    }
}
