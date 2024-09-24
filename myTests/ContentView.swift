//
//  ContentView.swift
//  myTests
//
//  Created by Wanner, Dorit on 04.04.23.
//

import SwiftUI
import SpeechTranscription

struct ContentView: View {
    @StateObject var transcript = SpeechTranscription()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Button( action: {
                transcript.isRecording ? transcript.stop() : transcript.start()
                print("is recording?: " + transcript.isRecording.description )
                
            }) {
                Text(transcript.isRecording ? "Is Recording!" : "Start Recording by pressing!")
            }
            ScrollView {
                VStack(alignment: .leading) {
                    Text(transcript.transcript)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
