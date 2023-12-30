/*
 MIDIPlaybackManager.swift
 MIDISequencer
 
 Created by Treata Norouzi on 12/29/23.
 
 Abstract:
 A minimalist ViewModel & manager to interpret `MIDIPlayer` model for views.
*/

import Foundation
import MIDISequencer
import Combine

@Observable class MIDIPlaybackManager: Identifiable {
    var midiPlayer: MIDIPlayer

    var currentPosition: TimeInterval = 0
    
    private var currentPositionTimer: Timer?
    
    init(midiPlayer: MIDIPlayer) {
        self.midiPlayer = midiPlayer
        startUpdatingCurrentPosition()
    }
    
    private func startUpdatingCurrentPosition() {
          currentPositionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
              self?.currentPosition = self?.midiPlayer.currentPosition ?? 0
          }
      }
      
      deinit {
          currentPositionTimer?.invalidate()
      }
    
    // MARK: Computed Properties
    
    public var duration: TimeInterval {
        midiPlayer.realDuration
    }
    
    var realPosition: TimeInterval {
        midiPlayer.realPosition
    }
    
    /*
     MARK: Previous implementation of currentPos which couldn't be observed
    var currentPosition: TimeInterval {
        midiPlayer.currentPosition
    }
     */
    
    var isPaused: Bool {
        midiPlayer.isPaused
    }
    
    var isPlaying: Bool {
        midiPlayer.isPlaying
    }
    
    public var isAtEndOfTrack: Bool {
        midiPlayer.isAtEndOfTrack
    }
    
//    private func updateCurrentPosition() {
//        guard currentPosition <= duration else {
//            pause()
//            return
//        }
//        // Increment the current position based on the `refresh rate`
//        currentPosition += 0.1
//    }
    
    // MARK: Intent(s)
    
//    func prepareToPlay() {
//        midiPlayer.prepareToPlay()
//    }
    
    func play() {
        midiPlayer.prepareToPlay()
        midiPlayer.play {
             
        }
    }
    
    func pause() {
        midiPlayer.pause()
    }
    
    func togglePlayback() {
        midiPlayer.togglePlayPause()
    }
    
    func seek(to time: TimeInterval) {
        midiPlayer.seek(to: time)
    }
}

extension MIDIPlaybackManager: Equatable {
    static func == (lhs: MIDIPlaybackManager, rhs: MIDIPlaybackManager) -> Bool {
        return lhs.midiPlayer == rhs.midiPlayer
    }
}

extension MIDIPlaybackManager {
    public static var previews: MIDIPlaybackManager? {
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
