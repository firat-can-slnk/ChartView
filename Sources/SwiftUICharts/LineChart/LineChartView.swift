//
//  LineCard.swift
//  LineChart
//
//  Created by András Samu on 2019. 08. 31..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct LineChartView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var data:ChartData
    public var title: String
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    
    public var formSize:CGSize
    public var dropShadow: Bool
    public var valueSpecifier:String
    
    @State private var touchLocation:CGPoint = .zero
    @State private var showIndicatorDot: Bool = false
    @State private var currentValue: Double = 2 {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    var frame = CGSize(width: 180, height: 120)
    private var rateValue: Int?
    
    public init(data: [Double],
                title: String,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                form: ChartForm = ChartForm.medium,
                rateValue: Int? = 14,
                dropShadow: Bool? = true,
                valueSpecifier: String? = "%.1f") {
        
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form.getSize()
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.dropShadow = dropShadow!
        self.valueSpecifier = valueSpecifier!
        self.rateValue = rateValue
    }
    
    public var body: some View {
        ZStack(alignment: .center){
            RoundedRectangle(cornerRadius: 20)
                .fill(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                .frame(width: frame.width, height: self.formSize.height, alignment: .center)
                .shadow(color: self.style.dropShadowColor, radius: self.dropShadow ? 8 : 0)
            ZStack(alignment: .top){
                VStack
                {
                    if(!self.showIndicatorDot){
                        VStack(alignment: .leading, spacing: 8){
                            Text(self.title)
                                .font(.title)
                                .bold()
                                .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                            
                            legendAndRateValueView
                        }
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.1))
                        .padding([.leading, .top])
                        .frame(width: frame.width, height: self.formSize.height, alignment: .topLeading)
                    }else{
                        HStack{
                            Spacer()
                            Text("\(self.currentValue, specifier: self.valueSpecifier)")
                                .font(.system(size: 41, weight: .bold, design: .default))
                                .offset(x: 0, y: 10)
                            Spacer()
                        }
                        .transition(.scale)
                    }
                    Spacer()
                }.frame(width: self.formSize.width, height: self.formSize.height)
                VStack
                {
                    Spacer()
                    GeometryReader{ geometry in
                        Line(data: self.data,
                             frame: .constant(geometry.frame(in: .local)),
                             touchLocation: self.$touchLocation,
                             showIndicator: self.$showIndicatorDot,
                             minDataValue: .constant(nil),
                             maxDataValue: .constant(nil),
                             gradient: self.style.gradientColor
                        )
                    }
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }.frame(width: self.formSize.width, height: self.formSize.height)
        }
        .gesture(DragGesture()
        .onChanged({ value in
            self.touchLocation = value.location
            self.showIndicatorDot = true
            self.getClosestDataPoint(toPoint: value.location, width:self.frame.width, height: self.frame.height)
        })
            .onEnded({ value in
                self.showIndicatorDot = false
            })
        )
    }
    
    var legendAndRateValueView: some View
    {
        Group
        {
            let sideBySide = HStack
            {
                legendView
                Spacer()
                rateValueView
                    .fixedSize()
                    .padding(.trailing)
            }
            switch formSize {
                case ChartForm.small.getSize(): sideBySide
                case ChartForm.detail.getSize(): sideBySide
                case ChartForm.large.getSize(): sideBySide
                default:
                    Group
                    {
                        legendView
                        
                        rateValueView
                    }
            }
        }
    }
    var legendView: some View {
        return Group
        {
            if let legend = legend
            {
                let foregroundColor = self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor
                 Text(legend)
                    .font(.callout)
                    .foregroundColor(foregroundColor)
            }
        }
    }
    
    var rateValueView: some View {
        return Group
        {
            if let rateValue = rateValue
            {
                if rateValue != 0
                {
                    HStack {
                        if rateValue > 0
                        {
                            Image(systemName: "arrow.up")
                        }
                        else if rateValue < 0
                        {
                            Image(systemName: "arrow.down")
                        }
                        Text("\(rateValue) %")
                    }
                }
            }
        }
    }
    
    @discardableResult func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(round((toPoint.x)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentValue = points[index]
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineChartView(data: [8,23,54,32,12,37,7,23,43], title: "Line chart", legend: "Basic")
                .environment(\.colorScheme, .light)
            
            LineChartView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Line chart", legend: "Basic")
            .environment(\.colorScheme, .light)
        }
    }
}
