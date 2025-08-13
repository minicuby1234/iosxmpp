import SwiftUI

struct LoginView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    @State private var username = ""
    @State private var password = ""
    @State private var server = ""
    @State private var showingAdvanced = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(MaterialTheme.primary)
                        
                        Text("XMPP Client")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(MaterialTheme.onSurface)
                        
                        Text("Connect to your XMPP server")
                            .font(.body)
                            .foregroundColor(MaterialTheme.onSurfaceVariant)
                    }
                    
                    VStack(spacing: 16) {
                        MaterialTextField(
                            title: "Username",
                            text: $username,
                            placeholder: "user@example.com"
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        
                        MaterialTextField(
                            title: "Password",
                            text: $password,
                            placeholder: "Enter password",
                            isSecure: true
                        )
                        
                        if showingAdvanced {
                            MaterialTextField(
                                title: "Server",
                                text: $server,
                                placeholder: "example.com (optional)"
                            )
                            .textInputAutocapitalization(.never)
                        }
                        
                        Button(action: {
                            withAnimation {
                                showingAdvanced.toggle()
                            }
                        }) {
                            HStack {
                                Text("Advanced Settings")
                                Spacer()
                                Image(systemName: showingAdvanced ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(MaterialTheme.primary)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        Button(action: login) {
                            HStack {
                                if xmppManager.connectionStatus == .connecting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: MaterialTheme.onPrimary))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Connect")
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .materialButton()
                        .disabled(username.isEmpty || password.isEmpty || xmppManager.connectionStatus == .connecting)
                        
                        if case .error(let message) = xmppManager.connectionStatus {
                            Text(message)
                                .foregroundColor(MaterialTheme.error)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .background(MaterialTheme.background)
            .navigationBarHidden(true)
        }
    }
    
    private func login() {
        let serverToUse = server.isEmpty ? extractServer(from: username) : server
        xmppManager.connect(username: username, password: password, server: serverToUse)
    }
    
    private func extractServer(from jid: String) -> String {
        let components = jid.components(separatedBy: "@")
        return components.count > 1 ? components[1] : "localhost"
    }
}

struct MaterialTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(MaterialTheme.onSurfaceVariant)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MaterialTheme.surfaceVariant)
            .cornerRadius(MaterialTheme.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: MaterialTheme.smallCornerRadius)
                    .stroke(MaterialTheme.outline.opacity(0.5), lineWidth: 1)
            )
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(XMPPManager())
    }
}
