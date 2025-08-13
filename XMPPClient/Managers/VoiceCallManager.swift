import Foundation
import AVFoundation
import Combine

class VoiceCallManager: ObservableObject {
    @Published var isInCall = false
    @Published var callStatus: CallStatus = .idle
    @Published var currentCallContact: String = ""
    
    private var audioSession: AVAudioSession?
    
    enum CallStatus {
        case idle
        case outgoing
        case incoming
        case connected
        case ended
    }
    
    init() {
        setupAudioSession()
    }
    
    func startCall(to contact: String) {
        currentCallContact = contact
        callStatus = .outgoing
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.callStatus = .connected
            self.isInCall = true
        }
    }
    
    func answerCall() {
        callStatus = .connected
        isInCall = true
    }
    
    func endCall() {
        callStatus = .ended
        isInCall = false
        currentCallContact = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.callStatus = .idle
        }
    }
    
    func simulateIncomingCall(from contact: String) {
        currentCallContact = contact
        callStatus = .incoming
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .voiceChat)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
}
