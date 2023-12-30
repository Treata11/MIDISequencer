/*
 MIDIPlaybackManager.swift
 MIDISequencer
 
 Created by Treata Norouzi on 12/29/23.
 
 Abstract:
 A minimalist ViewModel & manager to interpret `MIDIPlayer` model for views.
*/

import Foundation
import Combine
import MIDISequencer

@available(iOS 17.0, macOS 14.0, *)
@Observable public class MIDIPlaybackManager: Identifiable {
    public var midiPlayer: MIDIPlayer

    public var currentPosition: TimeInterval = 0
    
    private var currentPositionTimer: Timer?
    
    public init(midiPlayer: MIDIPlayer) {
        self.midiPlayer = midiPlayer
        
        startUpdatingCurrentPosition()
        prepareToPlay()
    }
    
    private func startUpdatingCurrentPosition() {
          currentPositionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
              self?.currentPosition = self?.midiPlayer.currentPosition ?? 0
          }
      }
      
    deinit {
        print("MIDIPlaybackManager deinitialized!")
        currentPositionTimer?.invalidate()
    }
    
    // MARK: Computed Properties
    
    public var duration: TimeInterval {
        midiPlayer.realDuration
    }
    
    public var realPosition: TimeInterval {
        midiPlayer.realPosition
    }
    
    /*
     MARK: Previous implementation of currentPos which couldn't be observed
    var currentPosition: TimeInterval {
        midiPlayer.currentPosition
    }
     */
    
    public var isPaused: Bool {
        midiPlayer.isPaused
    }
    
    public var isPlaying: Bool {
        midiPlayer.isPlaying
    }
    
    public var isAtEndOfTrack: Bool {
        midiPlayer.isAtEndOfTrack
    }
    
    // MARK: Intent(s)
    
    func prepareToPlay() {
        midiPlayer.prepareToPlay()
    }
    
    func play() {
        midiPlayer.play {
             
        }
    }
    
    func pause() {
        midiPlayer.pause()
    }
    
    public func togglePlayback() {
        midiPlayer.togglePlayPause()
    }
    
    public func seek(to time: TimeInterval) {
        midiPlayer.seek(to: time)
    }
    
    public func rewind(_ seconds: TimeInterval) {
        midiPlayer.rewind(secs: seconds)
    }
    
    public func fastForward(_ seconds: TimeInterval) {
        midiPlayer.fastForward(secs: seconds)
    }
}

// MARK: - MIDIPlaybackManager Extension(s)

@available(iOS 17.0, macOS 14.0, *)
extension MIDIPlaybackManager: Equatable {
    public static func == (lhs: MIDIPlaybackManager, rhs: MIDIPlaybackManager) -> Bool {
        return lhs.midiPlayer == rhs.midiPlayer
    }
}

@available(iOS 17.0, macOS 14.0, *)
public extension MIDIPlaybackManager {
    static var previews: MIDIPlaybackManager? {
        // FIXME: - Bundle url isn't available in packages
        let midiUrl = Bundle.main.url(forResource: "Interstellar", withExtension: "mid")!
        let soundBank = Bundle.main.url(forResource: "YDP-GrandPiano-20160804", withExtension: "sf2")
        
        do {
            return try MIDIPlaybackManager(midiPlayer: MIDIPlayer(with: midiUrl, andSoundfont: soundBank))
        } catch {
            print("Provide a SMF & a sound-font in the project bundle. \n\(error)")
        }
        
        return nil
    }
}

