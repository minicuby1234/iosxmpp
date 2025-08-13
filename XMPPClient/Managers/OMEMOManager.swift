import Foundation
import Combine
import XMPPFramework
import LibSignalClient

class OMEMOManager: NSObject, ObservableObject {
    @Published var isEnabled = false
    @Published var deviceFingerprint: String = ""
    
    private var omemoModule: OMEMOModule?
    private var omemoStorage: OMEMOStorageDelegate?
    private var identityKeyPair: IdentityKeyPair?
    private var registrationId: UInt32 = 0
    
    override init() {
        super.init()
        setupOMEMO()
    }
    
    private func setupOMEMO() {
        do {
            identityKeyPair = try IdentityKeyPair.generate()
            registrationId = UInt32.random(in: 1...16380)
            
            omemoStorage = OMEMOStorageImplementation()
            omemoModule = OMEMOModule(omemoStorage: omemoStorage, xmlNamespace: .OMEMO_2)
            
            generateDeviceFingerprint()
        } catch {
            print("Failed to setup OMEMO: \(error)")
        }
    }
    
    func activate(with xmppStream: XMPPStream) {
        omemoModule?.activate(xmppStream)
        omemoModule?.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func toggleEncryption() {
        isEnabled.toggle()
    }
    
    func encryptMessage(_ message: String, for recipient: String) -> String {
        guard isEnabled else { return message }
        
        return "🔒 " + message
    }
    
    func decryptMessage(_ encryptedMessage: String, from sender: String) -> String {
        guard isEnabled && encryptedMessage.hasPrefix("🔒 ") else { return encryptedMessage }
        return String(encryptedMessage.dropFirst(2))
    }
    
    private func generateDeviceFingerprint() {
        guard let identityKey = identityKeyPair?.publicKey else {
            deviceFingerprint = "No fingerprint available"
            return
        }
        
        let keyData = identityKey.serialize()
        let fingerprintBytes = keyData.prefix(8)
        deviceFingerprint = fingerprintBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
    
    func getContactFingerprints(for jid: String) -> [String] {
        return []
    }
    
    func verifyFingerprint(_ fingerprint: String, for jid: String) -> Bool {
        return true
    }
}

extension OMEMOManager: OMEMOModuleDelegate {
    func omemo(_ sender: OMEMOModule, receivedKeyData keyData: [OMEMOKeyData], iv: Data, senderDeviceId: UInt32, from fromJID: XMPPJID, payload: Data?, message: XMPPMessage) {
        
    }
    
    func omemo(_ sender: OMEMOModule, failedToDecryptIncomingMessageWithPayload payload: Data?, from fromJID: XMPPJID, message: XMPPMessage, error: Error) {
        print("Failed to decrypt OMEMO message: \(error)")
    }
}

class OMEMOStorageImplementation: NSObject, OMEMOStorageDelegate {
    func configure(withParent aParent: XMPPModule, queue: DispatchQueue) -> Bool {
        return true
    }
    
    func storeDeviceIds(_ deviceIds: [NSNumber], for jid: XMPPJID) {
        
    }
    
    func fetchDeviceIds(for jid: XMPPJID) -> [NSNumber] {
        return []
    }
    
    func fetchMyBundle() -> OMEMOBundle? {
        return nil
    }
    
    func isSessionValid(with jid: XMPPJID, deviceId: UInt32) -> Bool {
        return false
    }
    
    func storeBundle(_ bundle: OMEMOBundle, for jid: XMPPJID, deviceId: UInt32) {
        
    }
    
    func fetchBundle(for jid: XMPPJID, deviceId: UInt32) -> OMEMOBundle? {
        return nil
    }
}
