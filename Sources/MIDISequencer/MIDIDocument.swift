//
//  MIDIDocument.swift
//  
//
//  Created by Treata on 12/28/23.
//

import AVFoundation

/*
public class MIDIFilePresenter: NSObject, NSFilePresenter {
    private var midiPath: URL!
    private var soundfontPath: URL?

    public convenience init(path: URL, sfPath: URL?) {
        self.init()

        self.midiPath = path
        self.soundfontPath = sfPath
    }

    public var files: [URL] {
        var temp: [URL] = [self.midiPath]
        if let sfURL = self.presentedItemURL {
            temp.append(sfURL)
        }
        return temp
    }

    public var primaryPresentedItemURL: URL? {
        return self.midiPath
    }

    public var presentedItemURL: URL? {
        return self.soundfontPath
    }

    public var presentedItemOperationQueue: OperationQueue {
        return OperationQueue.main
    }
}
*/

// MARK: - MIDIDocument

/*
public class MIDIDocument: NSDocument {

    public var midiPresenter: MIDIFilePresenter!

    private var midiPath: URL!
    private var soundfontPath: URL?

//    var viewController: DocumentViewController? {
//        return self.windowControllers[0].contentViewController as? DocumentViewController
//    }

    public override var isInViewingMode: Bool {
        return true
    }

    public override var keepBackupFile: Bool {
        return false
    }

//    public override func makeWindowControllers() {
//        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
//        guard let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as? DocumentWindowController else {
//            fatalError("Couldn't instantiate window controller")
//        }
//        self.addWindowController(windowController)
//
//        if let documentURL = self.midiPath {
//            (windowController.contentViewController as? DocumentViewController)?.openFile(midiURL: documentURL)
//        }
//    }

    // MARK: - NSDocument

    public override func read(from url: URL, ofType typeName: String) throws {
        // this will throw if the MIDI isn't valid, aborting the document opening process
        _ = try AVMIDIPlayer(contentsOf: url, soundBankURL: nil)

        self.midiPath = url
        self.soundfontPath = MIDIPlayer.guessSoundfontPath(forMIDI: url)

        self.midiPresenter = MIDIFilePresenter(path: url, sfPath: self.soundfontPath)
        NSFileCoordinator.addFilePresenter(self.midiPresenter)
    }

    public override func close() {
        NSFileCoordinator.removeFilePresenter(self.midiPresenter)
        super.close()
    }
}
*/
