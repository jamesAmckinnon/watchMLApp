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
    @Binding var isLinkActive: Bool
    
    var body: some View {
        NavigationView{
            VStack{
                
                if mood == -1{
                    Text("How are you feeling?").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                } else if mood == 1 {
                    Text("Very Unpleasant").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                } else if mood == 2 {
                    Text("Unpleasant").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                } else if mood == 3 {
                    Text("Neutral").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                } else if mood == 4 {
                    Text("Pleasant").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                } else if mood == 5 {
                    Text("Very Pleasant").frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 23)
                        .padding(.leading, 15)
                }
                
                
                
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
                    Button("Submit") {
                        dateTime = Date()
                        realmManager.createMood(dateTime: dateTime, mood: mood)
                        mood = -1
                        isLinkActive.toggle()
                    }
                    .frame(height: 15)
                    .padding(.horizontal, 47)
                    .padding(.vertical, 10)
                    .background(.gray)
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(4)
                    
                    Spacer()
//                    Button(action:{
//                        dateTime = Date()
//                        realmManager.createMood(dateTime: dateTime, mood: mood)
//                        mood = -1
//                        isLinkActive.toggle()
//                    }) {
//                        Text("Submit")
//                            .frame(height: 5)
//                    }
//                    .buttonBorderShape(.roundedRectangle(radius: 4))
//                    .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .navigationTitle(){Text("Mood Update").foregroundColor(.white)}
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MoodButtonStyle: ButtonStyle {
    var selected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(selected ? .darkGreenBlue : .white)
            .padding()
            .background(selected ? .white : .clear)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white, lineWidth: 1)
            )
    }
}
