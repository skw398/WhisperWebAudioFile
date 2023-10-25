//
//  Whisper.swift
//  PlainWebView-SwiftUI
//
//  Created by Shigenari Oshio on 2023/10/25.
//

import Foundation

final class Whisper: NSObject {
    
    private var whisperContext: WhisperContext?
    private let modelUrl: URL = Bundle.main.url(forResource: "ggml-tiny.en", withExtension: "bin")!

    override init() {
        super.init()
        do {
            whisperContext = try WhisperContext.createContext(path: modelUrl.path())
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func transcribe(_ url: URL, completion: @MainActor (String) -> Void) async {
        guard let whisperContext else { return }
        
        do {
            let data = try decodeWaveFile(url)
            await whisperContext.fullTranscribe(samples: data)
            let result = await whisperContext.getTranscription()
            
            await completion(result)
        } catch {
            print(error.localizedDescription)
        }
    }
}
