import SwiftUI

@main
struct XMPPClientApp: App {
    @StateObject private var xmppManager = XMPPManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(xmppManager)
        }
    }
}
