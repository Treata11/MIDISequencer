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
// MARK: - Non iOS
@available(macOS 14.0, *)
public struct MIDIPlaybackPanel: View {
    @Bindable var viewModel: MIDIPlaybackManager
    
    let title: String
    let artist: String?
    let image: UIImage
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public init(viewModel: MIDIPlaybackManager, title: String, artist: String? = nil, image: UIImage) {
        self.viewModel = viewModel
        self.title = title
        self.artist = artist
        self.image = image
    }
    
    public var body: some View {
        ZStack {
            HStack {
                playbackManager
                    .offset(x: 50)
                Spacer()
                panel
                Spacer()
            }
            .padding(.horizontal)
        }
        .background {
            Rectangle()
                .foregroundStyle(.background)
                .scaleEffect(CGSize(width: 10, height: 1))
        }
    }
    
    var panel: some View {
        ZStack {
            background
            content
        }
        .frame(maxWidth: 666)
    }
    
    var content: some View {
        HStack {
            artwork
            Spacer()
            ZStack {
                info
                    .offset(y: -10)
                slider
                    .offset(y: 30)
            }
            Spacer()
        }
    }
    
    var slider: some View {
        let color: Color = colorScheme == .dark ? .white : .black
        
        return MusicSlider(
            viewModel,
            value: $viewModel.currentPosition,
            inRange: TimeInterval.zero...viewModel.duration,
            activeFillColor: color,
            fillColor: color.opacity(0.7),
            emptyColor: color.opacity(0.3)
        )
//        .padding(.horizontal, 30)
    }
    
    var artwork: some View {
        Image(uiImage: image)
            .resizable()
            .frame(minWidth: 113, maxWidth: 113, minHeight: 113, maxHeight: 113)
            .aspectRatio(contentMode: .fit)
    }
    
    var info: some View {
        VStack {
            Text(title)
                .fontWeight(.semibold)
            Text(artist ?? "")
                .fontDesign(.rounded)
                .opacity(0.5)
        }
    }
    
    var background: some View {
        Rectangle()
            .foregroundStyle(.ultraThickMaterial)
            .aspectRatio(990/168 , contentMode: .fit)
    }
    
    // MARK: Buttons
    
    var playbackManager: some View {
        ZStack {
            rewind.offset(x: -70)
            playButton
            fastForward.offset(x: 70)
        }
        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black)
        .animation(.easeInOut(duration: 0.03), value: viewModel.isPlaying)
        .padding(.horizontal)
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
#endif

#if os(iOS)
@available(iOS 17.0, macOS 14.0, *)
#Preview("MIDIPlaybackPanel") {
    @Bindable var manager = MIDIPlaybackManager.previews!
    
    return MIDIPlaybackPanel(viewModel: manager)
}
#endif
