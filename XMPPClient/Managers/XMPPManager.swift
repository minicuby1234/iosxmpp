import Foundation
import Combine
import XMPPFramework
import XMPPFrameworkSwift

class XMPPManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var messages: [Message] = []
    @Published var contacts: [Contact] = []
    @Published var currentUser: String = ""
    
    var xmppStream: XMPPStream?
    private var xmppRoster: XMPPRoster?
    private var xmppRosterStorage: XMPPRosterCoreDataStorage?
    private var username: String = ""
    private var password: String = ""
    private var server: String = ""
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    override init() {
        super.init()
        setupXMPP()
    }
    
    private func setupXMPP() {
        xmppStream = XMPPStream()
        xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        xmppRosterStorage = XMPPRosterCoreDataStorage.sharedInstance()
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        xmppRoster?.activate(xmppStream)
        xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        xmppStream?.enableBackgroundingOnSocket = true
    }
    
    func connect(username: String, password: String, server: String) {
        self.username = username
        self.password = password
        self.server = server
        self.currentUser = username
        
        connectionStatus = .connecting
        
        guard let jid = XMPPJID(string: username) else {
            connectionStatus = .error("Invalid JID format")
            return
        }
        
        xmppStream?.myJID = jid
        xmppStream?.hostName = server.isEmpty ? jid.domain : server
        
        do {
            try xmppStream?.connect(withTimeout: 30.0)
        } catch {
            connectionStatus = .error("Connection failed: \(error.localizedDescription)")
        }
    }
    
    func disconnect() {
        xmppStream?.disconnect()
        connectionStatus = .disconnected
        isAuthenticated = false
        currentUser = ""
        messages.removeAll()
        contacts.removeAll()
    }
    
    func sendMessage(_ text: String, to recipient: String, encrypted: Bool = false) {
        guard let recipientJID = XMPPJID(string: recipient) else { return }
        
        let message = XMPPMessage(type: "chat", to: recipientJID)
        message?.addBody(text)
        
        let messageId = UUID().uuidString
        message?.addAttribute(withName: "id", stringValue: messageId)
        
        if encrypted {
            message?.addChild(DDXMLElement.element(withName: "encryption", xmlns: "urn:xmpp:eme:0", stringValue: "urn:xmpp:omemo:2") as! DDXMLElement)
        }
        
        xmppStream?.send(message)
        
        let localMessage = Message(
            id: messageId,
            from: currentUser,
            to: recipient,
            body: text,
            timestamp: Date(),
            isEncrypted: encrypted,
            isOutgoing: true
        )
        messages.append(localMessage)
    }
    
    func addContact(_ jid: String, nickname: String = "") {
        guard let contactJID = XMPPJID(string: jid) else { return }
        xmppRoster?.addUser(contactJID, withNickname: nickname.isEmpty ? nil : nickname)
    }
    
    func removeContact(_ contact: Contact) {
        guard let contactJID = XMPPJID(string: contact.jid) else { return }
        xmppRoster?.removeUser(contactJID)
        contacts.removeAll { $0.id == contact.id }
    }
}

extension XMPPManager: XMPPStreamDelegate {
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        do {
            try xmppStream?.authenticate(withPassword: password)
        } catch {
            connectionStatus = .error("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        connectionStatus = .connected
        isAuthenticated = true
        
        let presence = XMPPPresence()
        presence?.addChild(DDXMLElement.element(withName: "priority", stringValue: "24") as! DDXMLElement)
        xmppStream?.send(presence)
        
        xmppRoster?.fetch()
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        connectionStatus = .error("Authentication failed")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        if let error = error {
            connectionStatus = .error("Disconnected with error: \(error.localizedDescription)")
        } else {
            connectionStatus = .disconnected
        }
        isAuthenticated = false
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        guard let body = message.body,
              let from = message.from?.bare else { return }
        
        let receivedMessage = Message(
            id: UUID().uuidString,
            from: from,
            to: currentUser,
            body: body,
            timestamp: Date(),
            isEncrypted: false,
            isOutgoing: false
        )
        
        DispatchQueue.main.async {
            self.messages.append(receivedMessage)
        }
    }
}

extension XMPPManager: XMPPRosterDelegate {
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterItem item: DDXMLElement) {
        guard let jid = item.attributeStringValue(forName: "jid") else { return }
        let name = item.attributeStringValue(forName: "name") ?? jid
        let subscription = item.attributeStringValue(forName: "subscription") ?? "none"
        
        if subscription != "remove" {
            let contact = Contact(jid: jid, nickname: name, isOnline: false)
            
            DispatchQueue.main.async {
                if !self.contacts.contains(where: { $0.jid == jid }) {
                    self.contacts.append(contact)
                }
            }
        }
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        xmppRoster?.acceptPresenceSubscriptionRequest(from: presence.from, andAddToRoster: true)
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        guard let from = presence.from?.bare else { return }
        
        let isAvailable = presence.type != "unavailable"
        
        DispatchQueue.main.async {
            if let index = self.contacts.firstIndex(where: { $0.jid == from }) {
                let updatedContact = Contact(
                    jid: self.contacts[index].jid,
                    nickname: self.contacts[index].nickname,
                    isOnline: isAvailable
                )
                self.contacts[index] = updatedContact
            }
        }
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
