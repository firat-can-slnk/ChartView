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
    
    @State var showSelectionLabel: Bool = false
    
    public var formSize:CGSize
    public var dropShadow: Bool
    public var valueSpecifier:String
    
    @State private var touchLocation:CGPoint = .zero
    @State private var showIndicatorDot: Bool = false
    @State private var currentValue: (String?, Double) = (nil, 2) {
        didSet{
            if (oldValue != self.currentValue && showIndicatorDot) {
                HapticFeedback.playSelection()
            }
            
        }
    }
    var frame = CGSize(width: 180, height: 120)
    private var rateValue: Double?
    let showInfinities: Bool
    
    public init(data: ChartData,
                title: String,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                form: ChartForm = ChartForm.medium,
                rateValue: Double? = nil,
                dropShadow: Bool = true,
                valueSpecifier: String = "%.0f",
                showInfinities: Bool = false) {
        
        self.data = data
        self.title = title
        self.legend = legend
        self.style = style
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.formSize = form.getSize()
        frame = CGSize(width: self.formSize.width, height: self.formSize.height/2)
        self.dropShadow = dropShadow
        self.valueSpecifier = valueSpecifier
        self.rateValue = rateValue
        self.showInfinities = showInfinities
    }
    
    public var body: some View {
        ZStack(alignment: .center){
            ZStack(alignment: .top){
                VStack
                {
                    if(!self.showIndicatorDot){
                        topRowView
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.1))
                        .padding([.leading, .top])
                    }else{
                        HStack{
                            Spacer()
                            Text("\(self.currentValue.1, specifier: self.valueSpecifier)")
                                .font(.system(size: 41, weight: .bold, design: .default))
                                .offset(x: 0, y: 10)
                            Spacer()
                        }
                        .transition(.scale)
                        
                        selectionLabelView
                            .padding(.top, 2)
                    }
                    Spacer()
                }.frame(maxWidth: self.formSize.width, maxHeight: self.formSize.height)
                VStack
                {
                    let additionalFrameHeight: CGFloat =
                        (formSize == ChartForm.medium.getSize() || formSize == ChartForm.extraLarge.getSize()) ? 30.0 : 0.0
                    
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
                    .offset(y: showIndicatorDot ? -2 : 0)
                    .frame(minWidth: 0, idealWidth: frame.width, maxWidth: frame.width, minHeight: 0, idealHeight: frame.height, maxHeight: frame.height + (legend == nil && rateValue == nil ? 10 : 0) + additionalFrameHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }.frame(height: self.formSize.height)
        }
        .background(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor.cornerRadius(20) : self.style.backgroundColor.cornerRadius(20))
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
    var selectionLabelView: some View
    {
        Group
        {
            if let text = currentValue.0
            {
                let foregroundColor = self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor
                 Text(text)
                    .font(.callout)
                    .foregroundColor(foregroundColor)
            }
        }
    }
    var topRowView: some View
    {
        VStack(alignment: .leading, spacing: 8)
        {
            let title = Text(self.title)
                            .font(.title)
                            .bold()
                            .lineLimit(1)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                            .minimumScaleFactor(0.5)
                            .padding(.trailing)
            
            if formSize != ChartForm.large.getSize() && formSize != ChartForm.extraLarge.getSize() {
                HStack
                {
                    title
                    Spacer()
                }
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
    
    var rateValueView: some View {
        return Group
        {
            if let rateValue = rateValue
            {
                if rateValue != 0 && !rateValue.isNaN
                {
                    HStack {
                        if rateValue.isFinite
                        {
                            if rateValue > 0
                            {
                                Image(systemName: "arrow.up")
                            }
                            else if rateValue < 0
                            {
                                Image(systemName: "arrow.down")
                            }
                            Text("\(Int((rateValue * 100).rounded())) %")
                        }
                        else if showInfinities
                        {
                            if rateValue == -.infinity
                            {
                                Image(systemName: "arrow.up")
                            }
                            else if rateValue == .infinity
                            {
                                Image(systemName: "arrow.down")
                            }
                            Text("> 999 %")
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
            self.currentValue = data.points[index]
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

struct WidgetView_Previews: PreviewProvider {
    static let data = ChartData(values: [
        ("Q1 2020", 10),
        ("Q2 2020", 25),
        ("Q3 2020", 28),
        ("Q4 2020", 18),
    ])
    static let title = "Line chart"
    static let legend = "Basic"
    
    static var previews: some View {
        ScrollView {
            // MARK: - Legend and rate
            Section(header: Text("Legend and rate"))
            {
                HStack
                {
                    LineChartView(data: data, title: title, legend: legend, form: ChartForm.small, rateValue: 0)
                    LineChartView(data: data, title: title, legend: legend, form: ChartForm.small, rateValue: 1.0)
                }.padding().padding()
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.detail, rateValue: 1.0)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.medium, rateValue: -1.0)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.large, rateValue: 1.0)
                LineChartView(data: data, title: title, legend: legend, form: ChartForm.extraLarge, rateValue: -1.0)
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
                LineChartView(data: data, title: title, form: ChartForm.small, rateValue: 1.0)
                LineChartView(data: data, title: title, form: ChartForm.detail, rateValue: 1.0)
                LineChartView(data: data, title: title, form: ChartForm.medium, rateValue: -1.0)
                LineChartView(data: data, title: title, form: ChartForm.large, rateValue: 1.0)
                LineChartView(data: data, title: title, form: ChartForm.extraLarge, rateValue: -1.0)
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
        .background(Color.green)
    }
}
