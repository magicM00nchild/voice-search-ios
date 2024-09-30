import XCTest
@testable import SpeechTranscription

@available(iOS 13.0, *)
final class SpeechTranscriptionTests: XCTestCase {
    func testForInit() throws {
        XCTAssertNotNil(SpeechTranscription.self)
    }
    func testFunctions() throws {
        let transcript = SpeechTranscription()
        transcript.start()
        XCTAssertTrue(transcript.isRecording)
        transcript.stop()
        XCTAssertFalse(transcript.isRecording)
        
    }
}
