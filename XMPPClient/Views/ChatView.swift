import SwiftUI

struct ChatView: View {
    let contact: String
    @EnvironmentObject var xmppManager: XMPPManager
    @StateObject private var omemoManager = OMEMOManager()
    @StateObject private var voiceCallManager = VoiceCallManager()
    @State private var messageText = ""
    @State private var showingCallSheet = false
    
    var messages: [Message] {
        xmppManager.messages
            .filter { ($0.from == contact && $0.to == xmppManager.currentUser) || ($0.from == xmppManager.currentUser && $0.to == contact) }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            MessageInputView(
                messageText: $messageText,
                isEncryptionEnabled: omemoManager.isEnabled,
                onSend: sendMessage,
                onToggleEncryption: omemoManager.toggleEncryption,
                onStartCall: { showingCallSheet = true }
            )
        }
        .background(MaterialTheme.background)
        .navigationTitle(contact.components(separatedBy: "@").first ?? contact)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: omemoManager.toggleEncryption) {
                        Image(systemName: omemoManager.isEnabled ? "lock.fill" : "lock.open")
                            .foregroundColor(omemoManager.isEnabled ? MaterialTheme.primary : MaterialTheme.onSurfaceVariant)
                    }
                    
                    Button(action: { showingCallSheet = true }) {
                        Image(systemName: "phone")
                            .foregroundColor(MaterialTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCallSheet) {
            VoiceCallView(contact: contact, callManager: voiceCallManager)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let finalMessage = omemoManager.isEnabled ? omemoManager.encryptMessage(messageText, for: contact) : messageText
        xmppManager.sendMessage(finalMessage, to: contact, encrypted: omemoManager.isEnabled)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer()
            }
            
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if message.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(message.isOutgoing ? MaterialTheme.onPrimary : MaterialTheme.primary)
                    }
                    
                    Text(message.body)
                        .font(.body)
                        .foregroundColor(message.isOutgoing ? MaterialTheme.onPrimary : MaterialTheme.onSurface)
                }
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(message.isOutgoing ? MaterialTheme.onPrimary.opacity(0.7) : MaterialTheme.onSurfaceVariant)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.isOutgoing ? MaterialTheme.primary : MaterialTheme.surfaceVariant)
            .cornerRadius(MaterialTheme.cornerRadius)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isOutgoing ? .trailing : .leading)
            
            if !message.isOutgoing {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    let isEncryptionEnabled: Bool
    let onSend: () -> Void
    let onToggleEncryption: () -> Void
    let onStartCall: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MaterialTheme.outline.opacity(0.3))
            
            HStack(spacing: 12) {
                Button(action: onToggleEncryption) {
                    Image(systemName: isEncryptionEnabled ? "lock.fill" : "lock.open")
                        .foregroundColor(isEncryptionEnabled ? MaterialTheme.primary : MaterialTheme.onSurfaceVariant)
                }
                
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(MaterialTheme.surfaceVariant)
                    .cornerRadius(MaterialTheme.cornerRadius)
                    .lineLimit(1...4)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? MaterialTheme.onSurfaceVariant : MaterialTheme.primary)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(MaterialTheme.surface)
    }
}

struct VoiceCallView: View {
    let contact: String
    @ObservedObject var callManager: VoiceCallManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                Circle()
                    .fill(MaterialTheme.primary)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text(String(contact.prefix(1).uppercased()))
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(MaterialTheme.onPrimary)
                    )
                
                Text(contact.components(separatedBy: "@").first ?? contact)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(MaterialTheme.onSurface)
                
                Text(callStatusText)
                    .font(.body)
                    .foregroundColor(MaterialTheme.onSurfaceVariant)
            }
            
            Spacer()
            
            HStack(spacing: 60) {
                Button(action: {
                    callManager.endCall()
                    dismiss()
                }) {
                    Image(systemName: "phone.down.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(MaterialTheme.error)
                        .clipShape(Circle())
                }
                
                if callManager.callStatus == .incoming {
                    Button(action: callManager.answerCall) {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaterialTheme.surface)
        .onAppear {
            if callManager.callStatus == .idle {
                callManager.startCall(to: contact)
            }
        }
        .onChange(of: callManager.callStatus) { status in
            if status == .ended {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
    
    private var callStatusText: String {
        switch callManager.callStatus {
        case .idle:
            return "Ready"
        case .outgoing:
            return "Calling..."
        case .incoming:
            return "Incoming call"
        case .connected:
            return "Connected"
        case .ended:
            return "Call ended"
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(contact: "alice@example.com")
                .environmentObject(XMPPManager())
        }
    }
}
