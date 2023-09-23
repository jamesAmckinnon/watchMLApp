//
//  PosNegBarChart.swift
//  WatchHealthRL Watch App
//
//  Created by James McKinnon on 2023-09-22.
//

import SwiftUI
import Charts

struct PosNegBarChart: View {
    var data: [DataTypeCorrelation]
    
    var body: some View {
        let deviceWidth:CGFloat = WKInterfaceDevice.current().screenBounds.size.width
        
        VStack {
            Chart(data) { item in
                let clipShape: UnevenRoundedRectangle = {
                    if item.correlation >= 0 {
                        return UnevenRoundedRectangle(
                            topLeadingRadius: 3,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 3
                        )
                    } else {
                        return UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 3,
                            bottomTrailingRadius: 3,
                            topTrailingRadius: 0
                        )
                    }
                }()
                
                RuleMark(y: .value("Correlation", 0))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .zIndex(1)
                
                BarMark(
                    x: .value("Data Type", item.dataType),
                    y: .value("Correlation", item.correlation),
                    width: 20
                ).clipShape(clipShape)
                .foregroundStyle(item.colour)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 1)) { _ in
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                }
            }
            .frame(width: deviceWidth * 0.85, height: 70)
        }
    }
}
