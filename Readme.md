# ACConnectClient

**ACConnectClient** is an iOS client library for working with the **AC Connect** protocol developed by **Streamsoft Inc**. It allows you to discover, connect to, and communicate with nearby devices broadcasting over local network using uDNS (mDNS). This library provides a modern, lightweight API designed for apps that need to interface with Artist Connection devices.

🧾 **Official protocol documentation:** [https://docs.artistconnection.net/acconnect](https://docs.artistconnection.net/acconnect)
📦 **Library GitHub repository:** [https://github.com/streamsoft-inc/acconnectclient.git](https://github.com/streamsoft-inc/acconnectclient.git)

---

## 🚀 Features

- 🔍 Discover devices broadcasting `_artist_connection._tcp.` and `_acconnect_streaming._tcp.`
- 📡 Receive device found/removed events
- 🔌 Connect and disconnect from devices
- 📥 Query playback status and capabilities
- 🔁 Send playlist and control commands
- 📱 Includes fully functional sample iOS app

---

## 🛠 Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15+
- Local Network permission (`NSLocalNetworkUsageDescription` in Info.plist)

---

## 📦 Installation (via Swift Package Manager)

1. In Xcode, open your project
2. Go to **File > Add Packages**
3. Enter the URL:

   ```
   https://github.com/streamsoft-inc/acconnectclient.git
   ```
4. Choose the `ACConnectClient` package

---

## 🚀 Getting Started

### 📡 Start Scanning for Devices

```swift
ACConnectClient.shared.delegate = self
ACConnectClient.shared.startScanning()
```

Implement the delegate:

```swift
extension YourViewController: ACConnectClientDelegate {
    func deviceFound(_ device: ACDevice) {
        print("Found: \(device.modelName) at \(device.ip)")
    }

    func deviceRemoved(_ device: ACDevice) {
        print("Removed: \(device.modelName)")
    }
}
```

---

## 🔌 Connect to Device

```swift
ACConnectClient.shared.connect(to: device)
```

---

## 📡 Polling Playback Status

Use `NetworkServices` to poll status every second:

```swift
NetworkServices.network.status(device: device) { result in
    switch result {
    case .success(let status):
        print("Status: \(status)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

You can also use a `Timer` to repeat this every second (see sample app).

---

## 🎷 Example Usage: Playlist API

Create a sample playlist array and send it:

```swift
let samplePlaylists: [ConnectPlaylist] = [
    ConnectPlaylist(
        id: UUID().uuidString,
        url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
        type: .AUDIO,
        duration: 240.0,
        metadata: ConnectMetadata(
            title: "Test Song",
            albumName: "Test Album",
            artistName: "Test Artist",
            format: .OTHER,
            artworkUrl: nil
        )
    )
    // Add more items as needed
]
```

---

## 📱 Example App

An iOS example app is included in the repo under the `ExampleApp/` folder.

Features:
- Device discovery
- Connection control
- Playback status polling
- Logging output to `UITextView`
- Volume control

---

## 🥚 Testing

You can use test media links like:
- [SoundHelix Audio](https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3)
- [Big Buck Bunny Video](https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)

---

## ⚠️ Permissions

Make sure you include the following in your app's `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses local network access to discover nearby devices.</string>
<key>NSBonjourServices</key>
<array>
    <string>_artist_connection._tcp</string>
    <string>_acconnect_streaming._tcp</string>
</array>
```

---

## 📄 License

MIT License

---

## 👨‍💼 Author

**Andrija Milovanović**
GitHub: [streamsoft-inc](https://github.com/streamsoft-inc)

---
