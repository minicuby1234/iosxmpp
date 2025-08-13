import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    @State private var searchText = ""
    
    var filteredChats: [String] {
        let uniqueContacts = Set(xmppManager.messages.map { $0.isOutgoing ? $0.to : $0.from })
        let contacts = Array(uniqueContacts)
        
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                if filteredChats.isEmpty {
                    EmptyStateView()
                } else {
                    List(filteredChats, id: \.self) { contact in
                        NavigationLink(destination: ChatView(contact: contact)) {
                            ChatListRow(contact: contact)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(MaterialTheme.background)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ChatListRow: View {
    let contact: String
    @EnvironmentObject var xmppManager: XMPPManager
    
    var lastMessage: Message? {
        xmppManager.messages
            .filter { ($0.from == contact && $0.to == xmppManager.currentUser) || ($0.from == xmppManager.currentUser && $0.to == contact) }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(MaterialTheme.primary)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(contact.prefix(1).uppercased()))
                        .foregroundColor(MaterialTheme.onPrimary)
                        .fontWeight(.medium)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.components(separatedBy: "@").first ?? contact)
                        .font(.headline)
                        .foregroundColor(MaterialTheme.onSurface)
                    
                    Spacer()
                    
                    if let lastMessage = lastMessage {
                        Text(formatTime(lastMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(MaterialTheme.onSurfaceVariant)
                    }
                }
                
                HStack {
                    if let lastMessage = lastMessage {
                        HStack(spacing: 4) {
                            if lastMessage.isEncrypted {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(MaterialTheme.primary)
                            }
                            
                            Text(lastMessage.body)
                                .font(.body)
                                .foregroundColor(MaterialTheme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No messages")
                            .font(.body)
                            .foregroundColor(MaterialTheme.onSurfaceVariant)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .materialCard()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
        }
        return formatter.string(from: date)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MaterialTheme.onSurfaceVariant)
            
            TextField("Search conversations", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MaterialTheme.surfaceVariant)
        .cornerRadius(MaterialTheme.cornerRadius)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 64))
                .foregroundColor(MaterialTheme.onSurfaceVariant)
            
            Text("No conversations yet")
                .font(.headline)
                .foregroundColor(MaterialTheme.onSurface)
            
            Text("Start a conversation by adding contacts")
                .font(.body)
                .foregroundColor(MaterialTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaterialTheme.background)
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
            .environmentObject(XMPPManager())
    }
}
