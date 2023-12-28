//
//  PlaybackPanel.swift
//
//
//  Created by Treata Norouzi on 12/28/23.
//

import SwiftUI

public struct PlaybackPanel.swift: View {
    let midiUrl: URL
    let soundBank: URL?
    
    var midiPlayer = MIDIPlayer(contentsOf: midiUrl, soundBankURL: soundBank)
    
    
    public var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview("PlaybackPanel.swift") {
    PlaybackPanel.swift()
}
