import Foundation
import AVFoundation
import Combine
import WebRTC

class VoiceCallManager: NSObject, ObservableObject {
    @Published var isInCall = false
    @Published var callStatus: CallStatus = .idle
    @Published var currentCallContact: String = ""
    
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private var peerConnection: RTCPeerConnection?
    private var audioSession: AVAudioSession?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteAudioTrack: RTCAudioTrack?
    
    enum CallStatus {
        case idle
        case outgoing
        case incoming
        case connected
        case ended
    }
    
    override init() {
        super.init()
        setupWebRTC()
        setupAudioSession()
    }
    
    private func setupWebRTC() {
        RTCInitializeSSL()
        
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startCall(to contact: String) {
        currentCallContact = contact
        callStatus = .outgoing
        isInCall = true
        
        createPeerConnection()
        createLocalAudioTrack()
        createOffer()
    }
    
    private func createPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
            RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"])
        ]
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        
        peerConnection = peerConnectionFactory?.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
    }
    
    private func createLocalAudioTrack() {
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = peerConnectionFactory?.audioSource(with: audioConstraints)
        localAudioTrack = peerConnectionFactory?.audioTrack(with: audioSource!, trackId: "audio0")
        
        if let localAudioTrack = localAudioTrack {
            peerConnection?.add(localAudioTrack, streamIds: ["stream0"])
        }
    }
    
    private func createOffer() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )
        
        peerConnection?.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp, error == nil else {
                print("Failed to create offer: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                if let error = error {
                    print("Failed to set local description: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func answerCall() {
        callStatus = .connected
        
        createPeerConnection()
        createLocalAudioTrack()
    }
    
    func endCall() {
        callStatus = .ended
        isInCall = false
        currentCallContact = ""
        
        peerConnection?.close()
        peerConnection = nil
        localAudioTrack = nil
        remoteAudioTrack = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.callStatus = .idle
        }
    }
    
    func simulateIncomingCall(from contact: String) {
        currentCallContact = contact
        callStatus = .incoming
        isInCall = true
    }
}

extension VoiceCallManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Remote stream added")
        if let audioTrack = stream.audioTracks.first {
            remoteAudioTrack = audioTrack
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Remote stream removed")
        remoteAudioTrack = nil
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Peer connection should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE connection state changed: \(newState)")
        
        DispatchQueue.main.async {
            switch newState {
            case .connected, .completed:
                if self.callStatus == .outgoing {
                    self.callStatus = .connected
                }
            case .disconnected, .failed, .closed:
                if self.isInCall {
                    self.endCall()
                }
            default:
                break
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE gathering state changed: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Generated ICE candidate: \(candidate)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Removed ICE candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened")
    }
}
