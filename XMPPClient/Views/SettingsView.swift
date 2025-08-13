import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    @StateObject private var omemoManager = OMEMOManager()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(MaterialTheme.primary)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(xmppManager.currentUser.prefix(1).uppercased()))
                                    .foregroundColor(MaterialTheme.onPrimary)
                                    .fontWeight(.medium)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(xmppManager.currentUser.components(separatedBy: "@").first ?? "User")
                                .font(.headline)
                                .foregroundColor(MaterialTheme.onSurface)
                            
                            Text(xmppManager.currentUser)
                                .font(.body)
                                .foregroundColor(MaterialTheme.onSurfaceVariant)
                            
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                
                                Text("Online")
                                    .font(.caption)
                                    .foregroundColor(Color.green)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Security") {
                    SettingsRow(
                        icon: "lock.fill",
                        title: "OMEMO Encryption",
                        subtitle: omemoManager.isEnabled ? "Enabled" : "Disabled",
                        action: {
                            omemoManager.toggleEncryption()
                        }
                    )
                    
                    NavigationLink(destination: OMEMOSettingsView(omemoManager: omemoManager)) {
                        SettingsRowContent(
                            icon: "key.fill",
                            title: "Encryption Keys",
                            subtitle: "Manage device keys"
                        )
                    }
                }
                
                Section("Account") {
                    SettingsRow(
                        icon: "arrow.right.square",
                        title: "Sign Out",
                        subtitle: "Disconnect from server",
                        isDestructive: true,
                        action: {
                            showingLogoutAlert = true
                        }
                    )
                }
                
                Section("About") {
                    SettingsRowContent(
                        icon: "info.circle",
                        title: "Version",
                        subtitle: "1.0.0"
                    )
                    
                    SettingsRowContent(
                        icon: "heart.fill",
                        title: "Made with",
                        subtitle: "Swift & SwiftUI"
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(MaterialTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    xmppManager.disconnect()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                icon: icon,
                title: title,
                subtitle: subtitle,
                isDestructive: isDestructive
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? MaterialTheme.error : MaterialTheme.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? MaterialTheme.error : MaterialTheme.onSurface)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(MaterialTheme.onSurfaceVariant)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct OMEMOSettingsView: View {
    @ObservedObject var omemoManager: OMEMOManager
    
    var body: some View {
        List {
            Section("Your Device") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Fingerprint")
                        .font(.headline)
                        .foregroundColor(MaterialTheme.onSurface)
                    
                    Text(formatFingerprint(omemoManager.deviceFingerprint))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(MaterialTheme.onSurfaceVariant)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 8)
            }
            
            Section("Trusted Devices") {
                ForEach(omemoManager.getContactFingerprints(for: "example@contact.com"), id: \.self) { fingerprint in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Device")
                            .font(.caption)
                            .foregroundColor(MaterialTheme.onSurfaceVariant)
                        
                        Text(formatFingerprint(fingerprint))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(MaterialTheme.onSurface)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(MaterialTheme.background)
        .navigationTitle("OMEMO Keys")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatFingerprint(_ fingerprint: String) -> String {
        let chunks = fingerprint.chunked(into: 8)
        return chunks.joined(separator: " ")
    }
}

extension String {
    func chunked(into size: Int) -> [String] {
        return stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(XMPPManager())
    }
}
