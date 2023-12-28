//
//  AVAudioUnitMIDISynth.swift
//
//
//  Created by Treata on 12/28/23.
//

import AVFoundation

/**
 A subclass of AVAudioUnitMIDIInstrument that represents a MIDI synthesizer audio unit.

 - Note: This class provides functionality for initializing a MIDI synthesizer with a sound bank URL and setting preload options.
 */
public class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument {
    
    // MARK: Initializer(s)

    /**
     Initializes an AVAudioUnitMIDISynth with a sound bank URL.

     - Parameter soundBankURL: The URL of the sound bank file. If set to nil, a default sound bank file will be used.
     - Throws: An error if the initialization fails.
     */
    public init(soundBankURL: URL?) throws {
        let description = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_MIDISynth,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )

        super.init(audioComponentDescription: description)

        var soundfontURL = soundBankURL ?? URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &soundfontURL,
            UInt32(MemoryLayout<URL>.size))

        if status != OSStatus(noErr) {
            throw "\(status)"
        }
    }

    // MARK: Methods

    /**
     Sets the preload option for the synthesizer.

     - Parameter enabled: A Boolean value indicating whether preload is enabled.
     - Throws: An error if setting the preload option fails.
    */
    public func setPreload(enabled: Bool) throws {
        guard let engine = self.engine else { throw "Synth must be connected to an engine." }
        if !engine.isRunning { throw "Engine must be running." }

        var enabledBit = enabled ? UInt32(1) : UInt32(0)

        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabledBit,
            UInt32(MemoryLayout<UInt32>.size))
        if status != noErr {
            throw "\(status)"
        }
    }
}

