import SwiftUI

struct ContentView: View {
    @EnvironmentObject var xmppManager: XMPPManager
    
    var body: some View {
        Group {
            if xmppManager.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ChatListView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chats")
                }
            
            ContactsView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Contacts")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(MaterialTheme.primary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(XMPPManager())
    }
}
