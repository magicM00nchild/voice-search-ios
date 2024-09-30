//
//  SpeechRecognizer.swift
//  VoiceSearch
//
//  Created by Wanner, Dorit on 30.03.23.
//

import AVFoundation
import Foundation
import Speech
import SwiftUI


@available(iOS 13.0, *)
public class SpeechTranscription: ObservableObject {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    @Published public var transcript: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    private var timer: Timer?
    
    public var microphoneAccess: Bool?
    public var speechRecognizeAccess: Bool?
    
    
    /// Public part
    public init() {
        
        recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: Locale.preferredLanguages[0]))
        
        Task(priority: .background) {
            do {
                guard recognizer != nil else {
                    throw RecognizerError.nilRecognizer
                }
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    speechRecognizeAccess = false
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    microphoneAccess = false
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                speakError(error)
            }
        }
    }
    
    deinit {
        reset()
    }

    @Published public var isRecording = false
    
    public func start(){
        self.reset()
        self.transcribe()
        isRecording = true
        countTime()
    }
    public func stop(){
        self.stopTranscribing()
        isRecording = false
    }
    
    
    ///Private part
    
    private func countTime (){
        let delayTime = DispatchTime.now() + 60.0
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
            self.stop()
        })
    }
    private func didNotSpeak (){
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.callStopAfterSpeechEnd), userInfo: nil, repeats: false)
    }
    @objc func callStopAfterSpeechEnd () {
        stop()
    }
    
    private func transcribe() {
        DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async { [weak self] in
            guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else {
                self?.speakError(RecognizerError.recognizerIsUnavailable)
                return
            }
            
            do {
                let (audioEngine, request) = try Self.prepareEngine()
                self.audioEngine = audioEngine
                self.request = request
                self.task = recognizer.recognitionTask(with: request, resultHandler: self.recognitionHandler(result:error:))
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }
    
    private func stopTranscribing() {
        reset()
    }
    
   private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    private func recognitionHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        timer?.invalidate()
        
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
        }
        if let result = result {
            speak(result.bestTranscription.formattedString)
        }
        didNotSpeak()
    }
    
    private func speak(_ message: String) {
        transcript = message
    }
    
    ///Executes speak Error
    private func speakError(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        transcript = "<< \(errorMessage) >>"
    }
}

///Asks permission for SpeechRecognition
extension SFSpeechRecognizer {
    @available(iOS 13.0.0, *)
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
///Asks permission for microphone use
extension AVAudioSession {
    @available(iOS 13.0.0, *)
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}
