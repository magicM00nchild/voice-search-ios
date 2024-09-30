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
            Image(systemName: "graduationcap")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
                .font(.title)
                //.padding(.top, 20)

            Spacer()

            ScrollView {
                VStack(alignment: .leading) {
                    Text(transcript.transcript)
                        .padding()
                }
            }
            .frame(maxHeight: .infinity)

            Button(action: {
                transcript.isRecording ? transcript.stop() : transcript.start()
            }) {
                Text(transcript.isRecording ? "Stop Recording" : "Start Recording")
                    .frame(width: 200, height: 50)
                    .background(transcript.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
