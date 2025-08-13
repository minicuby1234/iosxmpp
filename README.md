# iOS XMPP Client

A clean, simple iOS XMPP messaging client built with SwiftUI and Material 3 design principles, featuring real XMPP connectivity, OMEMO encryption, and WebRTC voice calling.

## Features

- **Real XMPP Connectivity**: Connect to any XMPP server using XMPPFramework
- **Material 3 Design**: Clean, modern UI following Google's Material Design 3 guidelines
- **OMEMO Encryption**: Real end-to-end encryption using libsignal-client
- **WebRTC Voice Calling**: Peer-to-peer voice calling functionality
- **Contact Management**: Add, remove, and manage your XMPP contacts with roster support
- **Real-time Messaging**: Send and receive messages with live XMPP streams
- **Cross-platform Support**: Compatible with iOS 16.0+

## Project Structure

```
XMPPClient/
├── XMPPClientApp.swift          # Main app entry point
├── ContentView.swift            # Root view controller
├── Views/
│   ├── LoginView.swift          # XMPP server login
│   ├── ChatListView.swift       # Conversation list
│   ├── ChatView.swift           # Individual chat interface
│   ├── ContactsView.swift       # Contact management
│   └── SettingsView.swift       # App settings and OMEMO config
├── Managers/
│   ├── XMPPManager.swift        # Core XMPP functionality
│   ├── OMEMOManager.swift       # Encryption management
│   └── VoiceCallManager.swift   # Voice calling features
├── Theme/
│   └── MaterialTheme.swift      # Material 3 design system
└── Assets.xcassets/             # App icons and assets
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0+ deployment target
- Swift 5.0+

### Building and Running

1. Clone this repository
2. Open `XMPPClient.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project (⌘+R)

### XMPP Server Setup

The app supports connecting to any XMPP server. You'll need:
- Your XMPP username (JID) - e.g., `user@example.com`
- Your password
- Server domain (auto-detected from JID or manually specified)

Popular XMPP servers include:
- Prosody
- ejabberd
- Openfire
- Tigase

## Usage

### Login
1. Enter your XMPP credentials (username@domain.com)
2. Enter your password
3. Optionally specify a custom server in Advanced Settings
4. Tap "Connect"

### Messaging
- View conversations in the Messages tab
- Tap a contact to open the chat
- Use the lock icon to toggle OMEMO encryption
- Tap the phone icon to start a voice call

### Contacts
- Add new contacts using their JID (Jabber ID)
- View online/offline status
- Remove contacts by swiping left

### Settings
- Toggle OMEMO encryption globally
- View and manage encryption keys
- Sign out from your account

## Security

This app implements OMEMO (OMEMO Multi-End Message and Object Encryption) for end-to-end encryption:
- Messages are encrypted before leaving your device
- Only intended recipients can decrypt messages
- Forward secrecy and deniability
- Device fingerprint verification

## Architecture

The app follows MVVM architecture with SwiftUI:
- **Views**: SwiftUI views for UI presentation
- **Managers**: Business logic and data management
- **Models**: Data structures for messages, contacts, etc.
- **Theme**: Material 3 design system implementation

## Dependencies

This app uses real XMPP functionality with the following dependencies:
- **XMPPFramework**: Robust Objective-C XMPP library with Swift support
- **libsignal-client**: Signal Protocol implementation for OMEMO encryption
- **WebRTC**: Real-time communication framework for voice calling
- **CocoaLumberjack**: Logging framework (XMPPFramework dependency)
- **CocoaAsyncSocket**: TCP/IP networking (XMPPFramework dependency)
- **KissXML**: XML parsing (XMPPFramework dependency)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Support

For issues and questions:
- Open an issue on GitHub
- Check XMPP server documentation
- Verify network connectivity and credentials
