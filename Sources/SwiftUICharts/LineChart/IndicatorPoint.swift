//
//  IndicatorPoint.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 03..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

struct IndicatorPoint: View {
    let knobColor: Color = Colors.IndicatorKnob
    let shadowColor: Color = Colors.LegendColor
    
    var body: some View {
        ZStack{
            Circle()
                .fill(knobColor)
            Circle()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4))
        }
        .frame(width: 14, height: 14)
        .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
    }
}

struct IndicatorPoint_Previews: PreviewProvider {
    static var previews: some View {
        IndicatorPoint()
    }
}
