//
//  ContentView.swift
//  Record WOW HC
//
//  Created by james bouker on 6/6/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Stepper("Keep the last \(viewModel.numberOfVideos) videos (5 minutes each)", value: $viewModel.numberOfVideos, in: 2...12)
            if !viewModel.isRecording {
                Stepper("Frame rate \(viewModel.frameRate) FPS", value: $viewModel.frameRate, in: 20...60)
            }
            if viewModel.hasFiles {
                Button("View screen recordings") {
                    NSWorkspace.shared.open(viewModel.url)
                }
            }
            
            Spacer()
            
            if viewModel.isRecording {
                VStack {
                    Spacer()
                    Button("🔴 Stop Recording") {
                        viewModel.userStop()
                    }
                    Spacer()
                    HStack {
                        Text("Died?")
                        Button("Stop Recording & copy last video for safe keeping") {
                            viewModel.userStopAndCopy()
                        }
                    }
                }
            } else {
                Button("Start Recording") {
                    if viewModel.hasFiles {
                        viewModel.userStart(viewModel.url)
                    } else {
                        openSavePanel()
                    }
                }
            }
            
            Spacer()
            
            if !viewModel.hidePermissions {
                Button("Open Screen Recording Permissions") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording")!)
                }
                Text("Must enable to record ^^")
            }
        }
        .padding()
    }
    
    func openSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save File"
        savePanel.nameFieldStringValue = viewModel.url.lastPathComponent
        if let initialDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            savePanel.directoryURL = initialDirectoryURL
        }
        savePanel.allowedContentTypes = [.directory]
        
        if savePanel.runModal() == .OK {
            guard let url = savePanel.url else { return }
            saveFile(at: url)
        }
    }
    
    func saveFile(at url: URL) {
        viewModel.userStart(url)
    }
}
