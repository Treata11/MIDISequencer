/*
 PlaybackPanel.swift


 Created by Treata Norouzi on 12/28/23.
 
 Abstract:
 An iOS music.app like playback panel to manage the playing midi files.
*/

import SwiftUI

#if os(iOS)
@available(iOS 17.0, macOS 14.0, *)
public struct MIDIPlaybackPanel: View {
    @Bindable var viewModel: MIDIPlaybackManager
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public init(viewModel: MIDIPlaybackManager) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .foregroundStyle(.ultraThinMaterial)
            playbackSlider
            playbackManager.offset(y: +40)
                .padding(.horizontal)
        }
        .frame(minWidth: 350, maxWidth: 450, minHeight: 150, maxHeight: 170)
    }
    
    var playbackSlider: some View {
        let color: Color = colorScheme == .dark ? .white : .black
        
        return MusicSlider(
            viewModel,
            value: $viewModel.currentPosition,
            inRange: TimeInterval.zero...viewModel.duration,
            activeFillColor: color,
            fillColor: color.opacity(0.7),
            emptyColor: color.opacity(0.3)
        )
        .padding(.horizontal, 30)
    }
    
    var playbackManager: some View {
        ZStack {
            rewind.offset(x: -50)
            playButton
            fastForward.offset(x: 50)
        }
        .scaleEffect(1.66)
        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black)
        .animation(.easeInOut(duration: 0.03), value: viewModel.isPlaying)
    }
    
    var fastForward: some View {
        Button(action: {
            // TODO: Implementations
        }, label: {
            Image(systemName: "forward.fill", variableValue: 1)
//                .symbolEffect(.pulse, options: .nonRepeating)
        })
    }
    var rewind: some View {
        Button(action: {
            // TODO: Implementations
        }, label: {
            Image(systemName: "backward.fill", variableValue: 1)
        })
    }
    
    var playButton: some View {
        Button(action: {
            viewModel.togglePlayback()
        }, label: {
            Image(
                systemName: viewModel.isPlaying ?
                "pause.fill" : "play.fill"
            )
        })
        .scaleEffect(1.3)
    }
}
#else
public struct MIDIPlaybackPanel: View {
    @Bindable var viewModel: MIDIPlaybackManager
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public init(viewModel: MIDIPlaybackManager) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EmptyView()
    }
}
#endif

@available(iOS 17.0, macOS 14.0, *)
#Preview("MIDIPlaybackPanel") {
    @Bindable var manager = MIDIPlaybackManager.previews!
    
    return MIDIPlaybackPanel(viewModel: manager)
}
