//
//  MIDIFileBouncer.swift
//  
//
//  Created by Treata on 12/28/23.
//

import Cocoa
import AVFoundation

/// The delegate for MIDIFileBouncer events.
public protocol MIDIFileBouncerDelegate: AnyObject {
    /// Informs the delegate about the progress of the bounce operation.
    func bounceProgress(progress: Double, currentTime: TimeInterval)
    /// Informs the delegate about any error that occurred during the bounce operation.
    func bounceError(error: MIDIBounceError)
    /// Informs the delegate that the bounce operation has been completed.
    func bounceCompleted()
}

/// An error type that can occur during the MIDI bounce process.
public struct MIDIBounceError: Error {
    public enum ErrorKind {
        case initializationFailure
        case invalidSequenceLength
        case avAudioFileCreationFailure
        case conversionFailure
        case engineStartFailure
        case sequencerStartFailure
        case ioError
    }

    public let kind: ErrorKind
    public let localizedMessage: String
    public let innerError: Error?

    public init(kind: ErrorKind, message: String, innerError: Error? = nil) {
        self.kind = kind

        let localizedMessage = NSLocalizedString(message, comment: "Make sure all error messages are fully localized")
        self.localizedMessage = localizedMessage

        self.innerError = innerError
    }
}

// MARK: - MIDIFileBouncer

/**
 A class for processing MIDI files and bouncing (rendering and exporting) audio output.

 - Note: Use this class to perform audio rendering from a MIDI file using an associated sound font.
*/
public class MIDIFileBouncer {
    private var engine: AVAudioEngine!
    private var sampler: AVAudioUnitMIDISynth!
    private var sequencer: AVAudioSequencer!

    private var cancelProcessing = false

    public var midiFile: URL?
    public var soundfontFile: URL?
    public var outFile: URL?

    public var isCancelled: Bool {
        return self.cancelProcessing
    }

    public var rate: Float {
        get {
            return self.sequencer.rate
        }
        set {
            self.sequencer.rate = newValue
        }
    }

    /**
     A weak reference to a delegate conforming to the MIDIFileBouncerDelegate protocol to receive
     progress updates, errors, and completion notifications.
     */
    public weak var delegate: MIDIFileBouncerDelegate?

    deinit {
        self.engine.disconnectNodeInput(self.sampler, bus: 0)
        self.engine.detach(self.sampler)
        self.sequencer = nil
        self.sampler = nil
        self.engine = nil
    }

    public init(midiFile: URL, soundfontFile: URL?) throws {
        self.engine = AVAudioEngine()

        self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundfontFile)

        self.engine.attach(self.sampler)

        let mixer = self.engine.mainMixerNode
        mixer.outputVolume = 0.0
        self.engine.connect(self.sampler, to: mixer, format: Settings.shared.processingFormat)

        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        try self.sequencer.load(from: midiFile, options: [])
        self.sequencer.prepareToPlay()

        self.midiFile = midiFile
        self.soundfontFile = soundfontFile
    }

    public func cancel() {
        self.cancelProcessing = true
    }

    // MARK: Delegate methods

    /// Dispatches progress updates to the delegate on the main thread.
    private func delegateProgress(progress: Double, currentTime: TimeInterval) {
        DispatchQueue.main.async {
            self.delegate?.bounceProgress(progress: progress, currentTime: currentTime)
        }
    }

    /// Dispatches error notifications to the delegate on the main thread.
    private func delegateError(error: MIDIBounceError) {
        DispatchQueue.main.async {
            self.delegate?.bounceError(error: error)
        }
    }

    /// Dispatches completion notifications to the delegate on the main thread.
    private func delegateCompleted() {
        DispatchQueue.main.async {
            self.delegate?.bounceCompleted()
        }
    }

    // MARK: Bounce logic

    /**
     Initiates the bouncing process, converting the MIDI file to audio format and writing the output to the 
     specified file URL.

     - Sets up audio resources including the sequencer, AVAudioFile, and a tap for capturing audio output.
     - Initiates playback, captures audio samples, and writes the converted audio to the output file.
     - Updates the delegate with progress, errors, and completion status during the bouncing process.
     */
    public func bounce(to fileURL: URL) {
        var writeError: NSError?

        self.outFile = fileURL

        let outputNode = self.sampler!
        let outputFormat = outputNode.outputFormat(forBus: 0)

        guard let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds + self.sequencer.seconds(forBeats: $0.offsetTime) }).max() else {
            self.delegateError(error: MIDIBounceError(kind: .invalidSequenceLength, message: "Can't determine sequence length."))
            return
        }

        let converter = Settings.shared.getConverter(from: outputFormat)

        let outputFile: AVAudioFile
        do {
            outputFile = try AVAudioFile(forWriting: fileURL, settings: converter.outputFormat.settings, commonFormat: converter.outputFormat.commonFormat, interleaved: true)
        } catch {
            self.delegateError(error: MIDIBounceError(kind: .avAudioFileCreationFailure, message: "AVAudioFile creation failed.", innerError: error))
            return
        }

        // Install tap
        outputNode.installTap(onBus: 0, bufferSize: 1024*4, format: nil) { (buffer: AVAudioPCMBuffer, _) in
            do {
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return buffer
                }

                // necessary because otherwise the converter will stretch/squeeze samples to fit the buffer, resulting in corruption
                let sampleRateRatio = outputFormat.sampleRate / converter.outputFormat.sampleRate
                let capacity = UInt32(Double(buffer.frameCapacity) / sampleRateRatio)

                let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity)!
                convertedBuffer.frameLength = convertedBuffer.frameCapacity

                let status = converter.convert(to: convertedBuffer, error: &writeError, withInputFrom: inputBlock)

                if status == .error {
                    self.delegateError(error: MIDIBounceError(kind: .conversionFailure, message: "Error occurred while converting file."))
                    return
                }

                try outputFile.write(from: convertedBuffer)
            } catch {
                writeError = error as NSError
            }
        }

        // Get sequencer ready
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()

        self.engine.prepare()

        do {
            try self.engine.start()
        } catch {
            self.delegateError(error: MIDIBounceError(kind: .engineStartFailure, message: "Engine start failed.", innerError: error))
            return
        }

        // Add silence to beginning
        usleep(useconds_t(0.2 * 1000 * 1000))

        // Start playback.
        do {
            try self.sequencer.start()
        } catch {
            self.delegateError(error: MIDIBounceError(kind: .sequencerStartFailure, message: "Can't start sequencer.", innerError: error))
            return
        }

        // Continuously check whether the track's finished or if an error occurred while looping
        while self.sequencer.isPlaying && !self.cancelProcessing && writeError == nil && self.sequencer.currentPositionInSeconds < sequenceLength {
            let progress = self.sequencer.currentPositionInSeconds / sequenceLength
            self.delegateProgress(progress: progress * 100, currentTime: self.sequencer.currentPositionInSeconds)

            usleep(10000)
        }

        // Ensure playback is stopped
        self.sequencer.stop()

        if writeError == nil {
            // Add x seconds of silence to end to ensure all notes have fully stopped playing
            usleep(useconds_t(1.5 * 1000 * 1000))
            self.delegateProgress(progress: 100, currentTime: self.sequencer.currentPositionInSeconds)
        }

        // Stop recording.
        outputNode.removeTap(onBus: 0)
        self.engine.stop()

        // Return error if there was any issue during recording.
        if let writeError = writeError {
            self.delegateError(error: MIDIBounceError(kind: .ioError, message: "Can't write to file.", innerError: writeError))
        } else {
            self.delegateCompleted()
        }
    }
}

