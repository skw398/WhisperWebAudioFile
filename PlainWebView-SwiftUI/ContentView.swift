//
//  ContentView.swift
//  PlainWebView-SwiftUI
//
//  Created by Shigenari Oshio on 2023/10/24.
//

import SwiftUI
import Combine
import AudioKit

struct ContentView: View {
    
    @StateObject private var audioManager: AudioManager = .init()
    
    @State private var searchBarText: String = ""
    @State private var action: WebView.Action = .none
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var currentURL: URL? = nil
    @State private var estimatedProgress: Double = 0.0
    
    @State private var showAlertForConfirmation: Bool = false
    @State private var isTranscribing: Bool = false
    @State private var audioUrl: URL? = nil
    
    var body: some View {
        
        var cancellables = Set<AnyCancellable>()
        
        let webView = WebView(
            action: $action,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            currentURL: $currentURL,
            didTapAudioFileLink: { url in
                audioUrl = url
                showAlertForConfirmation = true
            },
            setWebViewHandler: { webView in
                webView.publisher(for: \.estimatedProgress)
                    .receive(on: DispatchQueue.main)
                    .sink { value in
                        estimatedProgress = value
                    }
                    .store(in: &cancellables)
            }
        )
        
        TabView {
            // Browse tab
            VStack(spacing: 0) {
                
                webView
                    .onChange(of: currentURL) { newValue in
                        if let urlString = currentURL?.absoluteString {
                            searchBarText = urlString
                        }
                    }
                    .alert(
                        isTranscribing
                        ? "Audio file found. But another file is in progress."
                        : "Audio file found. Transcribe?",
                        isPresented: $showAlertForConfirmation
                    ) {
                        Button("Cancel", role: .cancel) {}
                        if !isTranscribing {
                            Button("Transcribe"){
                                Task {
                                    isTranscribing = true
                                    await audioManager.transcribeFromWeb(audioUrl) {
                                        isTranscribing = false
                                    }
                                }
                            }
                        }
                    } message: {
                        Text(audioUrl?.lastPathComponent ?? "")
                    }
                
                Divider()
                
                HStack {
                    
                    TextField("Search Google or type a URL", text: $searchBarText)
                        .keyboardType(.webSearch)
                        .onSubmit {
                            action = .load(searchBarText)
                        }
                    
                    Button {
                        searchBarText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("clearButton")
                    
                }
                .padding()
                
                GeometryReader { geometry in
                    Rectangle()
                        .foregroundColor(estimatedProgress == 1.0 ? .clear : .secondary)
                        .frame(width: geometry.size.width * CGFloat(estimatedProgress))
                }
                .frame(height: 4)
                
                Divider()
                
                HStack {
                    
                    Button(action: {
                        action = .goBack
                    }, label: {
                        Image(systemName: "chevron.backward")
                            .imageScale(.large)
                            .frame(width: 44, height: 44, alignment: .center)
                        
                    })
                    .disabled(!canGoBack)
                    
                    Button(action: {
                        action = .goForward
                    }, label: {
                        Image(systemName: "chevron.forward")
                            .imageScale(.large)
                            .frame(width: 44, height: 44, alignment: .center)
                    })
                    .disabled(!canGoForward)
                    
                    Spacer()
                    
                    Button(action: {
                        action = .reload
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                            .imageScale(.large)
                            .frame(width: 44, height: 44, alignment: .center)
                    })
                    
                }
                .padding(8)
            }
            .tabItem {
                Label("Browse", systemImage: "globe")
            }
            
            // Transcription tab
            ScrollView {
                Text(audioManager.messageLog)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                if isTranscribing {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .tabItem {
                Label("Transcription", systemImage: "doc.text")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
