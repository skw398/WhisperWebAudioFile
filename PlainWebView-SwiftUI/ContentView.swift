//
//  ContentView.swift
//  PlainWebView-SwiftUI
//
//  Created by Shigenari Oshio on 2023/10/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State var searchBarText: String = ""
    
    @State private var action: WebView.Action = .none
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var currentURL: URL? = nil
    @State private var estimatedProgress: Double = 0.0

    var body: some View {

        var cancellables = Set<AnyCancellable>()
        
        let webView = WebView(
            action: $action,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            currentURL: $currentURL,
            setWebViewHandler: { webView in
                webView.publisher(for: \.estimatedProgress)
                    .receive(on: DispatchQueue.main)
                    .sink { value in
                        estimatedProgress = value
                    }
                    .store(in: &cancellables)
            }
        )

        NavigationView {
            VStack(spacing: 0) {

                webView
                    .onChange(of: currentURL) { newValue in
                        if let urlString = currentURL?.absoluteString {
                            searchBarText = urlString
                        }
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
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
