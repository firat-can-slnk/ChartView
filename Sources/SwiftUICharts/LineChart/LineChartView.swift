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
                rateValue: Int? = nil,
                dropShadow: Bool = true,
                valueSpecifier: String = "%.0f") {
        
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form.getSize()
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.dropShadow = dropShadow
        self.valueSpecifier = valueSpecifier
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
                        topRowView
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
                        .padding(.top)
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
                    .frame(width: frame.width, height: frame.height + (legend == nil && rateValue == nil ? 15 : 0))
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
    var topRowView: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            let title = Text(self.title)
                            .font(.title)
                            .bold()
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
            
            if formSize != ChartForm.large.getSize() && formSize != ChartForm.extraLarge.getSize() {
                
                title
                legendAndRateValueView
            }
            else
            {
                HStack
                {
                    title
                    Spacer()
                    rateValueView
                }
                legendView
            }
        }
        
    }
    var legendAndRateValueView: some View
    {
        Group
        {
            let sideBySide = HStack
            {
                if legend != nil
                {
                    legendView
                    Spacer()
                }
                rateValueView
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
                    .fixedSize()
                    .padding(.trailing)
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
    static let data: [Double] = Array(0...500).shuffled().map { Double($0) }.suffix(10)
    static let title = "Line chart"
    static let legend = "Basic"
    
    static var previews: some View {
        ScrollView {
            // MARK: - Legend and rate
            Section(header: Text("Legend and rate"))
            {
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.small, rateValue: 0)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.small, rateValue: 10)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.detail, rateValue: 10)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.medium, rateValue: -10)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.large, rateValue: 10)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.extraLarge, rateValue: -10)
            }
            
            // MARK: - Legend
            Section(header: Text("Legend"))
            {
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.small)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.detail)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.medium)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.large)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.extraLarge)
            }
            
            // MARK: - Rate
            Section(header: Text("Rate"))
            {
                LineChartView(data: data, title: title, form: ChartForm.small, rateValue: 0)
                LineChartView(data: data, title: title, form: ChartForm.small, rateValue: 10)
                LineChartView(data: data, title: title, form: ChartForm.detail, rateValue: 10)
                LineChartView(data: data, title: title, form: ChartForm.medium, rateValue: -10)
                LineChartView(data: data, title: title, form: ChartForm.large, rateValue: 10)
                LineChartView(data: data, title: title, form: ChartForm.extraLarge, rateValue: -10)
            }
            
            // MARK: - Only title
            Section(header: Text("Only title"))
            {
                LineChartView(data: data, title: title, form: ChartForm.small)
                LineChartView(data: data, title: title, form: ChartForm.detail)
                LineChartView(data: data, title: title, form: ChartForm.medium)
                LineChartView(data: data, title: title, form: ChartForm.large)
                LineChartView(data: data, title: title, form: ChartForm.extraLarge)
            }
        }
    }
}
