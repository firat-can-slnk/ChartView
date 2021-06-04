//
//  IndicatorPoint.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 03..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

struct IndicatorPoint: View {
    let knobColor: Color
    let shadowColor: Color
    
    init(knobColor: Color = Colors.IndicatorKnob, shadowColor: Color = Colors.LegendColor) {
        self.knobColor = knobColor
        self.shadowColor = shadowColor
    }
    
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
