/*
 MusicSlider.swift
 Pianiso

 Created by Treata Norouzi on 11/15/23.
 Abstract:
 A slider to replicate the slider present in music.app
*/

import SwiftUI

#if os(iOS)
@available(iOS 17.0, macOS 14.0, *)
struct MusicSlider<T: BinaryFloatingPoint, S: ShapeStyle>: View {
    @Bindable var viewModel: MIDIPlaybackManager
    
    /// A bound value to the current-position of the _interval_
    @Binding var value: T
    /// The range of the playback interval always starting from 0 and closed at interval's ending.
    let inRange: ClosedRange<T>
    /// The color used on the **slider** only when the slider **isActive**
    let activeFillColor: S
    /// The permanent color used on the **slider**
    let fillColor: S
    /// It's the color of the **background** of the slider and also the color of the **timers** when the
    /// slider is _inActive_.
    ///
    /// It's recommended to set its value to be a little bit transparent
    let emptyColor: S
    /// the value seen in the _music.app_ is somewhere around `34-38`
    let height: CGFloat
    
    // MARK: States
    
    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    
    @GestureState private var isActive: Bool = false
    
    @State private var progressDuration: T = 0
    
    init(
        _ viewModel: MIDIPlaybackManager,
        value: Binding<T>,
        inRange: ClosedRange<T>,
        activeFillColor: S,
        fillColor: S,
        emptyColor: S,
        height: CGFloat = 38
    ) {
        self.viewModel = viewModel
        self._value = value
        self.inRange = inRange
        self.activeFillColor = activeFillColor
        self.fillColor = fillColor
        self.emptyColor = emptyColor
        self.height = height
    }
    
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                VStack {
                    ZStack(alignment: .center) {
                        // Acts as the background of the slider
                        Capsule()
                            .fill(emptyColor)
                        // Act as the slider itself
                        Capsule()
                            .fill(isActive ? activeFillColor : fillColor)
                            .mask({
                                /// Here a Rectangle is masked on the tip of the slider's point
                                /// to represent the played half of the playback and the value of
                                /// it gets updated constantly to match the currentPosition of the playback.
                                HStack {
                                    Rectangle().frame(
                                        width: max(bounds.size.width * CGFloat((localRealProgress + localTempProgress)), 0),
                                        alignment: .leading
                                    )
                                    Spacer(minLength: 0)
                                }
                            })
                    }
                    // MARK: Timers
                    timers
                }
                .frame(width: isActive ? bounds.size.width * 1.03 : bounds.size.width, alignment: .center)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height, alignment: .center)
            // MARK: Drag Gesture
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isActive) { value, state, transaction in
                    state = true
                }
                .onChanged { gesture in
                    localTempProgress = T(gesture.translation.width / bounds.size.width)
                    let prg = max(min((localRealProgress + localTempProgress), 1), 0)
                    progressDuration = inRange.upperBound * prg
                    
//                    print("MusicSlider.gesture.onChanged")
//                    value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                }.onEnded { value in
                    localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                    localTempProgress = 0
                    progressDuration = inRange.upperBound * localRealProgress
                    
                    let currentPosition = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                    viewModel.seek(to: TimeInterval(currentPosition))
//                    localRealProgress = getPrgPercentage(currentPosition)
                    self.value = currentPosition
                })
            .onAppear {
                localRealProgress = getPrgPercentage(value)
                progressDuration = inRange.upperBound * localRealProgress
            }
            .onChange(of: value) { _, newValue in
                if !isActive {
                    localRealProgress = getPrgPercentage(newValue)
                }
            }
        }
        .padding(.horizontal)
        .frame(height: isActive ? height * 1.13 : height, alignment: .center)
    }
    
    var timers: some View {
        HStack {
            Text(value.asTimeString(style: .positional))
            Spacer(minLength: 0)
            Text("-" + (inRange.upperBound - value).asTimeString(style: .positional))
        }
        .font(.system(.headline, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(isActive ? fillColor : emptyColor)
//                    .foregroundColor(isActive ? activeFillColor : emptyColor)
    }
    
    private var animation: Animation {
        if isActive {
            return .easeInOut
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
    
    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }

    private func getPrgValue() -> T {
        return ((localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound)) + inRange.lowerBound
    }
}
#else
@available(iOS 17.0, macOS 14.0, *)
struct MusicSlider<T: BinaryFloatingPoint, S: ShapeStyle>: View {
    @Bindable var viewModel: MIDIPlaybackManager
    
    /// A bound value to the current-position of the _interval_
    @Binding var value: T
    /// The range of the playback interval always starting from 0 and closed at interval's ending.
    let inRange: ClosedRange<T>
    /// The color used on the **slider** only when the slider **isActive**
    let activeFillColor: S
    /// The permanent color used on the **slider**
    let fillColor: S
    /// It's the color of the **background** of the slider and also the color of the **timers** when the
    /// slider is _inActive_.
    ///
    /// It's recommended to set its value to be a little bit transparent
    let emptyColor: S
    /// the value seen in the _music.app_ is somewhere around `34-38`
    let height: CGFloat
    
    // MARK: States
    
    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    
    @GestureState private var isActive: Bool = false
    
    @State private var progressDuration: T = 0
    
    init(
        _ viewModel: MIDIPlaybackManager,
        value: Binding<T>,
        inRange: ClosedRange<T>,
        activeFillColor: S,
        fillColor: S,
        emptyColor: S,
        height: CGFloat = 44
    ) {
        self.viewModel = viewModel
        self._value = value
        self.inRange = inRange
        self.activeFillColor = activeFillColor
        self.fillColor = fillColor
        self.emptyColor = emptyColor
        self.height = height
    }
    
    var body: some View {
        GeometryReader { bounds in
            ZStack {
                VStack {
                    ZStack(alignment: .center) {
                        // Acts as the background of the slider
                        Capsule()
                            .fill(emptyColor)
                        // Act as the slider itself
                        Capsule()
                            .fill(isActive ? activeFillColor : fillColor)
                            .mask({
                                /// Here a Rectangle is masked on the tip of the slider's point
                                /// to represent the played half of the playback and the value of
                                /// it gets updated constantly to match the currentPosition of the playback.
                                HStack {
                                    Rectangle().frame(
                                        width: max(bounds.size.width * CGFloat((localRealProgress + localTempProgress)), 0),
                                        alignment: .leading
                                    )
                                    Spacer(minLength: 0)
                                }
                            })
                    }
                    // MARK: Timers
                    timers
                }
                .frame(width: isActive ? bounds.size.width * 1.03 : bounds.size.width, alignment: .center)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height, alignment: .center)
            // MARK: Drag Gesture
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isActive) { value, state, transaction in
                    state = true
                }
                .onChanged { gesture in
                    localTempProgress = T(gesture.translation.width / bounds.size.width)
                    let prg = max(min((localRealProgress + localTempProgress), 1), 0)
                    progressDuration = inRange.upperBound * prg
                    
//                    print("MusicSlider.gesture.onChanged")
//                    value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                }.onEnded { value in
                    localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                    localTempProgress = 0
                    progressDuration = inRange.upperBound * localRealProgress
                    
                    let currentPosition = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                    viewModel.seek(to: TimeInterval(currentPosition))
//                    localRealProgress = getPrgPercentage(currentPosition)
                    self.value = currentPosition
                })
            .onAppear {
                localRealProgress = getPrgPercentage(value)
                progressDuration = inRange.upperBound * localRealProgress
            }
            .onChange(of: value) { _, newValue in
                if !isActive {
                    localRealProgress = getPrgPercentage(newValue)
                }
            }
        }
        .padding(.horizontal)
        .frame(height: isActive ? height * 1.07 : height, alignment: .center)
    }
    
    var timers: some View {
        HStack {
            Text(value.asTimeString(style: .positional))
            Spacer(minLength: 0)
            Text("-" + (inRange.upperBound - value).asTimeString(style: .positional))
        }
        .font(.system(.headline, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(isActive ? fillColor : emptyColor)
//                    .foregroundColor(isActive ? activeFillColor : emptyColor)
    }
    
    private var animation: Animation {
        if isActive {
            return .easeInOut
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
    
    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedStartValue = value - inRange.lowerBound
        let percentage = correctedStartValue / range
        return percentage
    }

    private func getPrgValue() -> T {
        return ((localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound)) + inRange.lowerBound
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
#Preview("MusicSlider") {
    @Bindable var viewModel = MIDIPlaybackManager.previews!
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    return MusicSlider(
        viewModel,
//        value: $viewModel.currentPosition,
        value: $viewModel.currentPosition,
        inRange: 0...viewModel.duration,
        activeFillColor: colorScheme == .dark ? Color.white : Color.black,
        fillColor: colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7),
        emptyColor: colorScheme == .dark ? Color.white.opacity(1/4) : Color.black.opacity(1/4)
    )
}
