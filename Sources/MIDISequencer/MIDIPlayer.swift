//
//  MIDIPlayer.swift
//
//
//  Created by Treata on 12/28/23.
//

import AVFoundation
import MediaPlayer

protocol MIDIPlayerDelegate: AnyObject {
    func filesLoaded(midi: URL, soundFont: URL?)

    func playbackWillStart(firstTime: Bool)
    func playbackStarted(firstTime: Bool)

    func playbackPositionChanged(position: TimeInterval, duration: TimeInterval)

    func playbackStopped(paused: Bool)
    func playbackEnded()

    func playbackSpeedChanged(speed: Float)
}

/**
 A subclass of AVMIDIPlayer that adds additional functionality for MIDI playback.

 > This class provides support for MIDI playback and additional features such as handling soundfonts, playback control, and delegation.
 */
@available(iOS 13.0, *)
public class MIDIPlayer: AVMIDIPlayer, Identifiable {
    
    // MARK: Properties
    
    /// The URL of the current MIDI file.
    public var currentMIDI: URL?
    /// The URL of the current soundfont file.
    public var currentSoundfont: URL?

    /// The delegate for `MIDIPlayer` events.
    weak var delegate: MIDIPlayerDelegate?

    private var progressTimer: Timer?
    private let endOfTrackTolerance = 0.1

    /// A Boolean value that indicates whether the MIDIPlayer accepts media keys for control.
    public var acceptsMediaKeys = true
    
    // MARK: Computed Properties

    /// The playback rate of the MIDIPlayer.
    public override var rate: Float {
        didSet {
            NowPlayingCentral.shared.updateNowPlayingInfo(for: self, with: [MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: self.rate)])
            self.delegate?.playbackSpeedChanged(speed: self.rate)
        }
    }

    /// The actual duration of the MIDI sequence considering the playback rate.
    public var realDuration: TimeInterval {
        return self.duration / Double(self.rate)
    }
    /// The actual position of the playback considering the playback rate.
    public var realPosition: TimeInterval {
        return self.currentPosition / Double(self.rate)
    }

    /// The current position of the playback.
    public override var currentPosition: TimeInterval {
        didSet {
            self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
        }
    }

    /// A Boolean value that indicates whether the sequence is paused.
    public var isPaused: Bool {
        return !self.isPlaying && !self.isAtEndOfTrack
    }

    /// A Boolean value that indicates whether the sequence is stopped.
    public var isAtEndOfTrack: Bool {
        return !self.isPlaying && self.currentPosition >= self.duration - self.endOfTrackTolerance
    }
    
    // MARK: Methods

    /**
         Guesses the path of the soundfont file associated with the given MIDI file.

         - Parameter midiFile: The URL of the MIDI file.
         - Returns: The URL of the associated soundfont file if found, otherwise nil.
    */
    public class func guessSoundfontPath(forMIDI midiFile: URL) -> URL? {
        let midiDirectory = midiFile.deletingLastPathComponent()
        let midiDirParent = midiDirectory.deletingLastPathComponent()

        guard let fileNameWithoutExt = NSString(string: midiFile.lastPathComponent).deletingPathExtension.removingPercentEncoding else {
            return nil
        }

        // Super cheap way of checking for accompanying soundfonts:
        // Just check for soundfonts that have the same name as the MIDI file
        // or the containing directory
        let potentialSoundFonts = [
            // Soundfonts with same name as the MIDI file
            "\(midiDirectory.path)/\(fileNameWithoutExt).sf2",
            "\(midiDirectory.path)/\(fileNameWithoutExt).dls",

            // Soundfonts with same name as containing directory
            "\(midiDirectory.path)/\(midiDirectory.lastPathComponent).sf2",
            "\(midiDirectory.path)/\(midiDirectory.lastPathComponent).dls",

            // Soundfonts with same name as the parent directory
            "\(midiDirParent.path)/\(midiDirParent.lastPathComponent).sf2",
            "\(midiDirParent.path)/\(midiDirParent.lastPathComponent).dls"
        ]

        for psf in potentialSoundFonts {
            if FileManager.default.fileExists(atPath: psf) {
                print("Soundfont found: \(psf)")
                return URL(fileURLWithPath: psf)
            }
        }

        if Settings.shared.looseSFMatching {
            // Busting out the old Levenshtein string distance
            // as a "looser" soundfont detection method
            print("starting loose soundfont search")
            do {
                let directoryContents = try FileManager.default.contentsOfDirectory(at: midiDirectory, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)

                let soundFontURLs = directoryContents.filter {
                    $0.pathExtension.lowercased() == "dls" || $0.pathExtension.lowercased() == "sf2"
                }

                return soundFontURLs.min {
                    let fileA = $0.lastPathComponent
                    let fileB = $1.lastPathComponent

                    return Levenshtein.distanceBetween(aStr: fileA, and: fileNameWithoutExt) <
                    Levenshtein.distanceBetween(aStr: fileB, and: fileNameWithoutExt)
                }
            } catch {
                print(error.localizedDescription)
            }
        }

        print("no soundfont found")
        return nil
    }

    /**
       Initializes the MIDIPlayer with the given MIDI file and an optional soundfont file.

       - Parameter midiFile: The URL of the MIDI file.
       - Parameter soundfontFile: The URL of the soundfont file, if available.
       - Throws: An error if the initialization fails.
       */
    public convenience init(with midiURL: URL, andSoundfont soundfontFile: URL? = nil) throws {
        try self.init(contentsOf: midiURL, soundBankURL: soundfontFile)

        self.currentMIDI = midiURL
        self.currentSoundfont = soundfontFile
    }
    
    // TODO: Init by Data
//    public convenience init(by midiFile: Data, andSoundfont soundfontFile: URL? = nil) throws {
//        try self.init(contentsOf: midiFile, soundBankURL: soundfontFile)
//
//        self.currentMIDI = midiFile
//        self.currentSoundfont = soundfontFile
//    }

    deinit {
        print("MIDIPlayer: deinit")

        self.progressTimer?.invalidate()
        self.progressTimer = nil

        self.currentSoundfont?.stopAccessingSecurityScopedResource()

        self.delegate = nil
    }


    public func timerDidFire(_ timer: Timer) {
        guard timer == self.progressTimer, timer.isValid else {
            return
        }

        // Updating the entire Now Playing dictionary here because macOS's caching(?) really fucks with us here
        // If I rely on the OS to keep track of song names, durations and whatnot, we'll desync in about 0.02 seconds
        NowPlayingCentral.shared.initNowPlayingInfo(for: self)
        NowPlayingCentral.shared.updateNowPlayingInfo(for: self, with: [MPNowPlayingInfoPropertyElapsedPlaybackTime: NSNumber(value: self.currentPosition)])

        self.delegate?.playbackPositionChanged(position: self.currentPosition, duration: self.duration)
    }

    // MARK: - Overrides and convenience methods

    public override func prepareToPlay() {
        super.prepareToPlay()

        self.delegate?.filesLoaded(midi: self.currentMIDI!, soundFont: self.currentSoundfont)
    }


    public override func play(_ completionHandler: AVMIDIPlayerCompletionHandler? = nil) {
        guard self.acceptsMediaKeys else {
            return
        }

        NowPlayingCentral.shared.makeActive(player: self)

        if self.currentPosition >= self.duration - self.endOfTrackTolerance {
            self.currentPosition = 0
        }

        self.delegate?.playbackWillStart(firstTime: self.currentPosition == 0)

        super.play {
            DispatchQueue.main.async {
                if self.currentPosition >= self.duration - self.endOfTrackTolerance {
                    self.progressTimer?.invalidate()

                    NowPlayingCentral.shared.playbackState = .stopped
                    self.delegate?.playbackEnded()
                }
            }

            completionHandler?()
        }

        self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true, block: timerDidFire)
        self.progressTimer!.tolerance = 0.125 / 8

        if !Settings.shared.cacophonyMode {
            NowPlayingCentral.shared.initNowPlayingInfo(for: self)
            NowPlayingCentral.shared.playbackState = .playing
        }

        self.delegate?.playbackStarted(firstTime: self.currentPosition == 0)
    }

    // cheap, but it works. mostly

    public func pause() {
        guard self.acceptsMediaKeys else {
            return
        }

        super.stop()

        self.progressTimer?.invalidate()

        NowPlayingCentral.shared.playbackState = .paused

        self.delegate?.playbackStopped(paused: true)
    }


    public override func stop() {
        guard self.acceptsMediaKeys else {
            return
        }

        super.stop()

        self.progressTimer?.invalidate()

        self.currentPosition = 0

        NowPlayingCentral.shared.playbackState = .stopped

        self.delegate?.playbackStopped(paused: false)
    }
    
    public func seek(to time: TimeInterval) {
        guard self.acceptsMediaKeys else {
            return
        }
        
        let newPos = min(time, self.duration)
        self.currentPosition = newPos
    }

    public func rewind(secs: TimeInterval) {
        guard self.acceptsMediaKeys else {
            return
        }

        let newPos = max(0, self.currentPosition - secs)
        self.currentPosition = newPos
    }

    public func fastForward(secs: TimeInterval) {
        guard self.acceptsMediaKeys else {
            return
        }

        let newPos = min(self.currentPosition + secs, self.duration)
        self.currentPosition = newPos
    }

    public func togglePlayPause() {
        guard self.acceptsMediaKeys else {
            print("Doesn't accept media keys")
            return
        }

        if self.isPaused || self.isAtEndOfTrack {
            self.play()
        } else if self.isPlaying {
            self.pause()
        } else {
            self.stop()
        }
    }

}
