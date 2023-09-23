//
//  CorrelationsView.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-09-22.
//

import SwiftUI
import Charts

struct CorrelationsView: View {
    var data: [DataTypeCorrelation]
    @State var isLinkActive = false
    
    var body: some View {
        let deviceWidth: CGFloat = WKInterfaceDevice.current().screenBounds.size.width
        
        NavigationView{
            VStack{
                PosNegBarChart(data: data)
                    .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                Spacer()
                Text("Correlation With Mood")
                    .font(.system(size: 13))
                    .frame(maxWidth: deviceWidth * 0.85, alignment: .leading)
                ForEach(data) { item in
                    HStack {
                        Circle()
                            .frame(width: 9, height: 9)
                            .foregroundColor(item.colour)
                            .padding(.trailing, 2)
                        Text(item.dataType)
                            .font(.system(size: 12))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Text(item.correlationStrength)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundColor(.gray)
                    }.frame(width: deviceWidth * 0.85)
                }
            }
            .navigationTitle("Correlations")
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
