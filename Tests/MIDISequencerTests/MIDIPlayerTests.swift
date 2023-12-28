//
//  MIDIPlayerTests.swift
//  
//
//  Created by Treata on 12/28/23.
//

import XCTest
@testable import MIDISequencer

final class MIDIPlayerTests: XCTestCase {
    func testExample() throws {
//        let testBundle = Bundle(for: type(of: self))
//        guard let midiUrl = testBundle.url(forResource: "JoyToTheWorld", withExtension: "mid") else {
//            XCTFail("Failed to locate MIDI file")
//            return
//        }
        let midiUrl = URL(fileURLWithPath:
            "/Downloads/Interstellar.mid")
        let soundBank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        
        let midiPlayer = try MIDIPlayer(with: midiUrl)
        
        print(midiPlayer)
    }
}
