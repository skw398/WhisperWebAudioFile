//
//  AudioManager.swift
//  PlainWebView-SwiftUI
//
//  Created by Shigenari Oshio on 2023/10/25.
//

import Foundation
import AVFoundation
import SwiftUI
import AudioKit

@MainActor
class AudioManager: ObservableObject {
        
    private let whisper: Whisper = .init()
    private var audioPlayer: AVAudioPlayer?
        
    nonisolated static let audioFormats = ["wav", "bwf", "aif", "aiff", "caf", "m4a", "mp3", "mp4", "m4v", "mpg", "flac", "ogg"]
    
    @Published var messageLog = ""
    
    func transcribeFromWeb(_ url: URL?, completion: @escaping () -> Void) async {
        guard let url else { return }

        do {
            messageLog += "Processing \(url.lastPathComponent)...\n"
            
            guard let url = await downloadFile(from: url) else { return }
            
            let convertedUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("converted.wav")
            if FileManager.default.fileExists(atPath: convertedUrl.path) {
                try FileManager.default.removeItem(at: convertedUrl)
            }
            
            convertToWav(from: url, to: convertedUrl) { [weak self] error in
                guard let self else { return }
                
                if let error {
                    print(error.localizedDescription)
                    messageLog += "Audio file converting failed.\n"
                    return
                }
                
                Task {
                    self.messageLog += "Transcribing...\n"
                    
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                    self.audioPlayer?.play()
                    
                    await self.whisper.transcribe(convertedUrl) { transcription in
                        self.messageLog += "--------------------\n\(transcription)\n"
                        completion()
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
            messageLog += "Audio file processing failed.\n"
        }
    }
    
    private func downloadFile(from url: URL) async -> URL? {
        do {
            let (url, response) = try await URLSession.shared.download(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200 ... 299).contains(httpResponse.statusCode) {
                messageLog += "\(httpResponse.statusCode) error occurred.\n"
                return nil
            }
            
            return url
        } catch {
            print(error.localizedDescription)
            messageLog += "Audio file downloading failed.\n"
            return nil
        }
    }
    
    private func convertToWav(from input: URL, to output: URL, completion: @escaping (_ error: Error?) -> Void) {
        FormatConverter(
            inputURL: input,
            outputURL: output,
            options: FormatConverter.Options(
                pcmFormat: .wav,
                sampleRate: 16000,
                bitDepth: 16,
                channels: 1
            )
        ).start(completionHandler: completion)
    }
}
