//
//  sevenDayView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-09-22.
//

import SwiftUI
import Charts

struct SevenDayView: View {
    var data: [DailyMood]
    var average: Double
    @State var isLinkActive = false
    
    var body: some View {
        let deviceWidth: CGFloat = WKInterfaceDevice.current().screenBounds.size.width
        
        NavigationView{
            VStack {
                Spacer()
                Chart(data) {
                    RuleMark(y: .value("Mood", average))
                        // light green blue
                        .foregroundStyle(Color(UIColor(red: 196/255, green: 249/255, blue: 245/255, alpha: 1)))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .zIndex(1)
                    BarMark(
                        x: .value("Day", $0.day),
                        y: .value("Moods", $0.moods),
                        width: 9
                    ).clipShape(UnevenRoundedRectangle(topLeadingRadius: 3,
                                                       bottomLeadingRadius: 0,
                                                       bottomTrailingRadius: 0,
                                                       topTrailingRadius: 3
                                                      )
                    )
                    // Light grey
                    .foregroundStyle(Color(UIColor(red: 209/255, green: 209/255, blue: 209/255, alpha: 1)))
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(width: deviceWidth * 0.85, height: 70)
                Spacer()
                Text("Mood")
                    .font(.system(size: 19))
                    .frame(maxWidth: deviceWidth * 0.85, alignment: .leading)
                    .fontWeight(.semibold)
                    // Light green blue
                    .foregroundStyle(Color(UIColor(red: 196/255, green: 249/255, blue: 245/255, alpha: 1)))
                Text(String(format: "%.1f On Average", average))
                    .font(.system(size: 24))
                    .frame(maxWidth: deviceWidth * 0.85, alignment: .leading)
                Text("In last 7 days")
                    .font(.system(size: 15))
                    .frame(maxWidth: deviceWidth * 0.85, alignment: .leading)
                    .foregroundColor(.lightgray)
            }
            .navigationTitle("Last 7 Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        self.isLinkActive.toggle()
                    }) {
                        Image("AddIcon")
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                    }.buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $isLinkActive) {
                        TabView {
                            MoodUpdateView(isLinkActive: $isLinkActive)
                        }
                    }
                }
            }
        }
        
    }
}
