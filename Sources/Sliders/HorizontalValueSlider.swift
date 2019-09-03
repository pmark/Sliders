import SwiftUI

public typealias HSlider = HorizontalValueSlider

public struct HorizontalValueSlider<V, TrackView: InsettableShape, ValueView: View, ThumbView : InsettableShape>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
    @Environment(\.sliderStyle)
    var style
    
    @usableFromInline
    var preferences = SliderPreferences()
    
    let value: Binding<V>
    let bounds: ClosedRange<V>
    let step: V.Stride

    let trackView: TrackView
    let valueView: ValueView
    let thumbView: ThumbView
    
    let onEditingChanged: (Bool) -> Void
    
    @State
    private var dragOffsetX: CGFloat? = nil
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .init(horizontal: .leading, vertical: .center)) {
                self.generatedValueTrackView(geometry: geometry, valueView: self.valueView, trackView: self.trackView)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let relativeValue: CGFloat = (value.location.x - self.thumbSize.width / 2) / (geometry.size.width - self.thumbSize.width)
                            let bounds = CGFloat(self.bounds.lowerBound)...CGFloat(self.bounds.upperBound)
                            let computedValue = valueFrom(relativeValue: relativeValue, bounds: bounds, step: CGFloat(self.step))
                            self.value.wrappedValue = V(computedValue)
                            print(computedValue)
                            self.onEditingChanged(true)
                        }
                        .onEnded { _ in
                            self.onEditingChanged(false)
                        }
                )

                self.generatedThumbView(view: self.thumbView)
                    .offset(x: self.xForValue(width: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if self.dragOffsetX == nil {
                                    self.dragOffsetX = value.startLocation.x - self.xForValue(width: geometry.size.width)
                                }
                                let relativeValue: CGFloat = (value.location.x - (self.dragOffsetX ?? 0)) / (geometry.size.width - self.thumbSize.width)
                                let bounds = CGFloat(self.bounds.lowerBound)...CGFloat(self.bounds.upperBound)
                                let computedValue = valueFrom(relativeValue: relativeValue, bounds: bounds, step: CGFloat(self.step))
                                self.value.wrappedValue = V(computedValue)
                                self.onEditingChanged(true)
                            }
                            .onEnded { _ in
                                self.dragOffsetX = nil
                                self.onEditingChanged(false)
                            }
                    )
            }
            .frame(height: self.height)
        }
        .frame(height: self.height)
        
        /// Enabling this draws incorrect gradient on value change, fix it before enabling metal randering
        //.drawingGroup()
    }
    
    func valueOffset(overallWidth: CGFloat) -> CGFloat {
        return (xForValue(width: overallWidth) - overallWidth) / 2
    }
    
    func valueWidth(overallWidth: CGFloat) -> CGFloat {
        self.xForValue(width: overallWidth)
    }
    
    func xForValue(width: CGFloat) -> CGFloat {
        (width - self.thumbSize.width) * (CGFloat(self.value.wrappedValue - bounds.lowerBound) / CGFloat(bounds.upperBound - bounds.lowerBound))
    }
}

// MARK: Views

extension HorizontalValueSlider {
    func generatedValueTrackView<ValueView: View, TrackView: InsettableShape>(geometry: GeometryProxy, valueView: ValueView, trackView: TrackView) -> some View {
        valueView
            .foregroundColor(self.valueColor)
            .frame(width: geometry.size.width, height: self.thickness)
            .mask(
                Rectangle()
                    .frame(
                        width: self.clippedValue ? (self.valueWidth(overallWidth: geometry.size.width) + self.thumbSize.width) : geometry.size.width,
                        height: self.thickness
                    )
                    .fixedSize()
                    .offset(x: self.clippedValue ? self.valueOffset(overallWidth: geometry.size.width) : 0)
            )
            .overlay(
                trackView
                    .strokeBorder(self.trackBorderColor, lineWidth: self.trackBorderWidth)
            )
            .background(self.trackColor)
                .mask(
                    trackView.frame(width: geometry.size.width, height: self.thickness)
            )
    }
    
    func generatedThumbView<ThumbView: InsettableShape>(view: ThumbView) -> some View {
        view
            .overlay(
                view.strokeBorder(self.thumbBorderColor, lineWidth: self.thumbBorderWidth)
            )
            .frame(width: self.thumbSize.width, height:self.thumbSize.height)
            .foregroundColor(self.thumbColor)
            .shadow(color:self.thumbShadowColor, radius: self.thumbShadowRadius, x: self.thumbShadowX, y: self.thumbShadowY)
    }
}

// MARK: Inits

extension HorizontalValueSlider {
    /// Creates an instance that selects a value from within a range.
    ///
    /// - Parameters:
    ///     - value: The selected value within `bounds`.
    ///     - bounds: The range of the valid values. Defaults to `0...1`.
    ///     - onEditingChanged: A callback for when editing begins and ends.
    ///
    /// `onEditingChanged` will be called when editing begins and ends. For
    /// example, on iOS, a `RangeSlider` is considered to be actively editing while
    /// the user is touching the thumb and sliding it around the track.
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, trackView: TrackView, valueView: ValueView, thumbView: ThumbView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.value = value
        self.bounds = bounds
        self.step = step
        
        self.trackView = trackView
        self.valueView = valueView
        self.thumbView = thumbView
        
        self.onEditingChanged = onEditingChanged
    }
}

extension HorizontalValueSlider where TrackView == Capsule {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, valueView: ValueView, thumbView: ThumbView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: Capsule(), valueView: valueView, thumbView: thumbView, onEditingChanged: onEditingChanged)
    }
}

extension HorizontalValueSlider where ValueView == Rectangle {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, trackView: TrackView, thumbView: ThumbView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: trackView, valueView: Rectangle(), thumbView: thumbView, onEditingChanged: onEditingChanged)
    }
}

extension HorizontalValueSlider where ThumbView == Capsule {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, trackView: TrackView, valueView: ValueView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: trackView, valueView: valueView, thumbView: Capsule(), onEditingChanged: onEditingChanged)
    }
}

extension HorizontalValueSlider where ThumbView == Capsule, ValueView == Rectangle {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, trackView: TrackView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: trackView, valueView: Rectangle(), thumbView: Capsule(), onEditingChanged: onEditingChanged)
    }
}


extension HorizontalValueSlider where TrackView == Capsule, ValueView == Rectangle {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, thumbView: ThumbView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: Capsule(), valueView: Rectangle(), thumbView: thumbView, onEditingChanged: onEditingChanged)
    }
}

extension HorizontalValueSlider where TrackView == Capsule, ThumbView == Capsule {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, valueView: ValueView, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: Capsule(), valueView: valueView, thumbView: Capsule(), onEditingChanged: onEditingChanged)
    }
}

extension HorizontalValueSlider where TrackView == Capsule, ValueView == Rectangle, ThumbView == Capsule {
    public init(value: Binding<V>, in bounds: ClosedRange<V> = 0.0...1.0, step: V.Stride = 0.001, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self.init(value: value, in: bounds, step: step, trackView: Capsule(), valueView: Rectangle(), thumbView: Capsule(), onEditingChanged: onEditingChanged)
    }
}

// MARK: Values

extension HorizontalValueSlider {
    var height: CGFloat {
        preferences.height ?? style.height
    }
    
    var thickness: CGFloat {
        preferences.thickness ?? style.thickness
    }
    
    var thumbSize: CGSize {
        preferences.thumbSize ?? style.thumbSize
    }
    
    var thumbColor: Color {
        preferences.thumbColor ?? style.thumbColor
    }
    
    var thumbBorderColor: Color {
        preferences.thumbBorderColor ?? style.thumbBorderColor
    }
    
    var thumbBorderWidth: CGFloat {
        preferences.thumbBorderWidth ?? style.thumbBorderWidth
    }
    
    var thumbShadowColor: Color {
        preferences.thumbShadowColor ?? style.thumbShadowColor
    }
    
    var thumbShadowRadius: CGFloat {
        preferences.thumbShadowRadius ?? style.thumbShadowRadius
    }
    
    var thumbShadowX: CGFloat {
        preferences.thumbShadowX ?? style.thumbShadowX
    }
    
    var thumbShadowY: CGFloat {
        preferences.thumbShadowY ?? style.thumbShadowY
    }
    
    var valueColor: Color {
        preferences.valueColor ?? style.valueColor
    }
    
    var trackColor: Color {
        preferences.trackColor ?? style.trackColor
    }
    
    var trackBorderColor: Color {
        preferences.trackBorderColor ?? style.trackBorderColor
    }
    
    var trackBorderWidth: CGFloat {
        preferences.trackBorderWidth ?? style.trackBorderWidth
    }
    
    var clippedValue: Bool {
        preferences.clippedValue ?? style.clippedValue
    }
}

// MARK: Modifiers

public extension HorizontalValueSlider {
    @inlinable func height(_ length: CGFloat?) -> Self {
        var copy = self
        copy.preferences.height = length
        return copy
    }
    
    @inlinable func thickness(_ length: CGFloat?) -> Self {
        var copy = self
        copy.preferences.thickness = length
        return copy
    }
    
    @inlinable func thumbSize(_ size: CGSize?) -> Self {
        var copy = self
        copy.preferences.thumbSize = size
        return copy
    }
    
    @inlinable func thumbColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.thumbColor = color
        return copy
    }
    
    @inlinable func thumbBorderColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.thumbBorderColor = color
        return copy
    }
    
    @inlinable func thumbBorderWidth(_ width: CGFloat?) -> Self {
        var copy = self
        copy.preferences.thumbBorderWidth = width
        return copy
    }
    
    @inlinable func thumbShadowColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.thumbShadowColor = color
        return copy
    }

    @inlinable func thumbShadowRadius(_ radius: CGFloat?) -> Self {
        var copy = self
        copy.preferences.thumbShadowRadius = radius
        return copy
    }

    @inlinable func thumbShadowX(_ offset: CGFloat?) -> Self {
        var copy = self
        copy.preferences.thumbShadowX = offset
        return copy
    }

    @inlinable func thumbShadowY(_ offset: CGFloat?) -> Self {
        var copy = self
        copy.preferences.thumbShadowY = offset
        return copy
    }
    
    @inlinable func valueColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.valueColor = color
        return copy
    }
    
    @inlinable func trackColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.trackColor = color
        return copy
    }

    @inlinable func trackBorderColor(_ color: Color?) -> Self {
        var copy = self
        copy.preferences.trackBorderColor = color
        return copy
    }

    @inlinable func trackBorderWidth(_ length: CGFloat?) -> Self {
        var copy = self
        copy.preferences.trackBorderWidth = length
        return copy
    }
    
    @inlinable func clippedValue(_ isClipped: Bool?) -> Self {
        var copy = self
        copy.preferences.clippedValue = isClipped
        return copy
    }
}


#if DEBUG
struct  HorizontalValueSlider_Previews: PreviewProvider {
    
    static var previews: some View {
        HorizontalValueSlider(value: .constant(0.5), thumbView: Rectangle())
            .height(100)
            .thumbColor(.blue)
            .thumbBorderWidth(4)
            .thumbBorderColor(.red)
            .previewLayout(.fixed(width: 300, height: 100))
    }
}
#endif
