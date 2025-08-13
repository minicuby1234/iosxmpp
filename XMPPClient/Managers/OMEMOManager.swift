import Foundation
import Combine

class OMEMOManager: ObservableObject {
    @Published var isEnabled = false
    @Published var deviceFingerprint: String = ""
    
    init() {
        generateDeviceFingerprint()
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
        let characters = "ABCDEF0123456789"
        deviceFingerprint = String((0..<32).map { _ in characters.randomElement()! })
    }
    
    func getContactFingerprints(for jid: String) -> [String] {
        return [
            "A1B2C3D4E5F6789012345678901234567890ABCD",
            "B2C3D4E5F6789012345678901234567890ABCDEF1"
        ]
    }
    
    func verifyFingerprint(_ fingerprint: String, for jid: String) -> Bool {
        return true
    }
}
