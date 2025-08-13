import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    @State private var showingAddContact = false
    @State private var searchText = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return xmppManager.contacts
        } else {
            return xmppManager.contacts.filter {
                $0.jid.localizedCaseInsensitiveContains(searchText) ||
                $0.nickname.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                if filteredContacts.isEmpty {
                    ContactsEmptyStateView()
                } else {
                    List {
                        ForEach(filteredContacts) { contact in
                            ContactRow(contact: contact)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteContacts)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(MaterialTheme.background)
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(MaterialTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
        }
    }
    
    private func deleteContacts(offsets: IndexSet) {
        for index in offsets {
            let contact = filteredContacts[index]
            xmppManager.removeContact(contact)
        }
    }
}

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MaterialTheme.primary)
                    .frame(width: 48, height: 48)
                
                Text(String(contact.nickname.prefix(1).uppercased()))
                    .foregroundColor(MaterialTheme.onPrimary)
                    .fontWeight(.medium)
                
                if contact.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: 18)
                        .overlay(
                            Circle()
                                .stroke(MaterialTheme.surface, lineWidth: 2)
                                .frame(width: 12, height: 12)
                                .offset(x: 18, y: 18)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.nickname)
                    .font(.headline)
                    .foregroundColor(MaterialTheme.onSurface)
                
                Text(contact.jid)
                    .font(.body)
                    .foregroundColor(MaterialTheme.onSurfaceVariant)
                
                Text(contact.isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(contact.isOnline ? Color.green : MaterialTheme.onSurfaceVariant)
            }
            
            Spacer()
            
            NavigationLink(destination: ChatView(contact: contact.jid)) {
                Image(systemName: "message")
                    .foregroundColor(MaterialTheme.primary)
            }
        }
        .padding(.vertical, 4)
        .materialCard()
    }
}

struct AddContactView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    @Environment(\.dismiss) private var dismiss
    @State private var jid = ""
    @State private var nickname = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    MaterialTextField(
                        title: "JID (Jabber ID)",
                        text: $jid,
                        placeholder: "user@example.com"
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    MaterialTextField(
                        title: "Nickname (Optional)",
                        text: $nickname,
                        placeholder: "Display name"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding(.top, 24)
            .background(MaterialTheme.background)
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MaterialTheme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addContact()
                    }
                    .foregroundColor(MaterialTheme.primary)
                    .disabled(jid.isEmpty)
                }
            }
        }
    }
    
    private func addContact() {
        xmppManager.addContact(jid, nickname: nickname)
        dismiss()
    }
}

struct ContactsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 64))
                .foregroundColor(MaterialTheme.onSurfaceVariant)
            
            Text("No contacts yet")
                .font(.headline)
                .foregroundColor(MaterialTheme.onSurface)
            
            Text("Add contacts to start messaging")
                .font(.body)
                .foregroundColor(MaterialTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaterialTheme.background)
    }
}

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView()
            .environmentObject(XMPPManager())
    }
}
