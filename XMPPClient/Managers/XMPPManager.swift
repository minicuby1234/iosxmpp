import Foundation
import Combine

class XMPPManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var messages: [Message] = []
    @Published var contacts: [Contact] = []
    @Published var currentUser: String = ""
    
    private var username: String = ""
    private var password: String = ""
    private var server: String = ""
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    func connect(username: String, password: String, server: String) {
        self.username = username
        self.password = password
        self.server = server
        
        connectionStatus = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isAuthenticated = true
            self.connectionStatus = .connected
            self.currentUser = username
            self.loadInitialData()
        }
    }
    
    func disconnect() {
        isAuthenticated = false
        connectionStatus = .disconnected
        messages.removeAll()
        contacts.removeAll()
        currentUser = ""
    }
    
    func sendMessage(_ text: String, to recipient: String, encrypted: Bool = false) {
        let message = Message(
            id: UUID().uuidString,
            from: currentUser,
            to: recipient,
            body: text,
            timestamp: Date(),
            isEncrypted: encrypted,
            isOutgoing: true
        )
        messages.append(message)
    }
    
    func addContact(_ jid: String, nickname: String = "") {
        let contact = Contact(
            jid: jid,
            nickname: nickname.isEmpty ? jid : nickname,
            isOnline: Bool.random()
        )
        contacts.append(contact)
    }
    
    func removeContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
    }
    
    private func loadInitialData() {
        contacts = [
            Contact(jid: "alice@example.com", nickname: "Alice", isOnline: true),
            Contact(jid: "bob@jabber.org", nickname: "Bob", isOnline: false),
            Contact(jid: "charlie@xmpp.net", nickname: "Charlie", isOnline: true)
        ]
        
        messages = [
            Message(id: "1", from: "alice@example.com", to: currentUser, body: "Hello! How are you?", timestamp: Date().addingTimeInterval(-3600), isEncrypted: false, isOutgoing: false),
            Message(id: "2", from: currentUser, to: "alice@example.com", body: "I'm doing great, thanks!", timestamp: Date().addingTimeInterval(-3500), isEncrypted: false, isOutgoing: true),
            Message(id: "3", from: "charlie@xmpp.net", to: currentUser, body: "🔒 This is an encrypted message", timestamp: Date().addingTimeInterval(-1800), isEncrypted: true, isOutgoing: false)
        ]
    }
}

struct Message: Identifiable, Hashable {
    let id: String
    let from: String
    let to: String
    let body: String
    let timestamp: Date
    let isEncrypted: Bool
    let isOutgoing: Bool
}

struct Contact: Identifiable, Hashable {
    let id = UUID()
    let jid: String
    let nickname: String
    let isOnline: Bool
}
