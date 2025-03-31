//
//  ViewController.swift
//  ExampleApp
//
//  Created by Andrija Milovanovic on 30.3.25..
//

import UIKit
import ACConnectClient

class ViewController: UIViewController {

    private var discoveredDevices: [ACDevice] = []
    private var statusTimer: Timer?
    private var muteStatus = false
    private var pauseStatus = false
    private var activeDevice: ACDevice? = nil
    private var activePlaylist:ConnectPlaylist? = nil
    
    @IBOutlet weak var txtLogView: UITextView!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var btnPause: UIButton!
    @IBOutlet weak var btnMute: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegate
        ACConnectClient.shared.delegate = self
        
        self.appendLine("Initiate scanning")
        // Start scanning
        ACConnectClient.shared.startScanning()
    }
    
    func stopPollingStatus() {
        statusTimer?.invalidate()
        statusTimer = nil
    }

    lazy var playlist:[ConnectPlaylist] = {
        return [
            ConnectPlaylist(
                id: UUID().uuidString,
                url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                type: .AUDIO,
                duration: 240.0,
                metadata: ConnectMetadata(
                    title: "SoundHelix Track 1",
                    albumName: "Test Album",
                    artistName: "Test Artist",
                    format: .OTHER,
                    artworkUrl: URL(string: "https://via.placeholder.com/150")
                )
            ),
            ConnectPlaylist(
                id: UUID().uuidString,
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                type: .VIDEO,
                duration: 596.0,
                metadata: ConnectMetadata(
                    title: "Big Buck Bunny",
                    albumName: "Unknown",
                    artistName: "Blender Foundation",
                    format: .DOLBY,
                    artworkUrl: URL(string: "https://peach.blender.org/wp-content/uploads/title_anouncement.jpg")
                )
            ),
            ConnectPlaylist(
                id: UUID().uuidString,
                url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")!,
                type: .AUDIO,
                duration: 210.0,
                metadata: ConnectMetadata(
                    title: "SoundHelix Track 2",
                    albumName: "Another Album",
                    artistName: "Another Artist",
                    format: .MQA,
                    artworkUrl: nil
                )
            )
        ]

    }()

    func startPollingStatus(for device: ACDevice)
    {
        stopPollingStatus() // prevent duplicates

        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            NetworkServices.network.status(device: device) { result in
                DispatchQueue.main.async {

                    switch result {
                    case .success(let status):
                        if let errorStr = status.error {
                            self.appendLine("❌ Error: \(errorStr)")
                        } else {
                            if let logStr = status.log {
                                self.appendLine("Device Log: \(logStr)")
                            }
                            
                            self.appendLine("Playback state \(status.state) position: \(status.position?.valueS ?? "unknown")")
                        }
                        
                        DispatchQueue.main.async
                        {
                            let item = self.playlist.first { $0.id == status.id }
                            if let newActivePlaylist = item,  newActivePlaylist.id != self.activePlaylist?.id {
                                
                                self.appendLine("====== Playing \(newActivePlaylist.metadata.title) ==== ")
                                
                                self.activePlaylist = newActivePlaylist
                                self.seekSlider.maximumValue = newActivePlaylist.duration
                            }
                            if let pos = status.position?.valueF {
                                self.seekSlider.value = pos
                            }
                        }

                        
                    case .failure(let error):
                        self.appendLine("❌ Failed to get status: \(error)")
                    }
                }
            }
        }
    }

    
    private var volumeDebounceTimer: Timer?
    private var seekDebounceTimer: Timer?
    @IBAction func onVolumeLevel(_ sender: Any) {
        
        guard let slider = sender as? UISlider else { return }
        
        // Cancel previous timer
        volumeDebounceTimer?.invalidate()
        
        volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.appendLineTime("Initiate volume change to level: \(slider.value)")
            if let device = self.activeDevice {
                NetworkServices.network.api(device: device, action:.volume(value: slider.value)) { responce in
                    self.appendLineTime("Device volume level changed status: \(responce.isFailure ? "failed" : "success")")
                    if responce.isFailure {
                        self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                    }
                }
            }
        }
    }
    @IBAction func onSeekTo(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        
        // Cancel previous timer
        seekDebounceTimer?.invalidate()
        
        let seekTo = slider.value
        seekDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.appendLineTime("Initiate seek to position: \(seekTo)")
            if let device = self.activeDevice {
                NetworkServices.network.api(device: device, action:.seek(offset: Float64(seekTo))) { responce in
                    self.appendLineTime("Device seek level changed status: \(responce.isFailure ? "failed" : "success")")
                    if responce.isFailure {
                        self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                    }
                }
            }
        }
    }
    @IBAction func onNext(_ sender: Any) {
        appendLineTime("Initiate play next command")
        if let device = self.activeDevice {
            NetworkServices.network.api(device: device, action:.next) { responce in
                self.appendLineTime("Device next command: \(responce.isFailure ? "failed" : "success")")
                if responce.isFailure {
                    self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                }
            }
        }
    }
    @IBAction func onPrevious(_ sender: Any) {
        appendLineTime("Initiate play previous command")
        if let device = self.activeDevice {
            NetworkServices.network.api(device: device, action:.previous) { responce in
                self.appendLineTime("Device previus command: \(responce.isFailure ? "failed" : "success")")
                if responce.isFailure {
                    self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                }
            }
        }
    }
    @IBAction func onDisconnectAll(_ sender: Any) {
        appendLineTime("Initiate disconnection of all devices")
        for device in discoveredDevices {
            NetworkServices.network.disconnect(device: device) { responce in
                self.appendLineTime("Device disconnected \(responce.isFailure ? "failed" : "success")")
                if responce.isFailure {
                    self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                }
            }
            
        }
        if let device = activeDevice {
            NetworkServices.network.api(device: device, action: .stop) { r in
                // nothing
            }
        }
       
        self.activeDevice = nil
    }

    @IBAction func onMute(_ sender: Any) {
        appendLineTime("Initiate mute command")
        if let device = self.activeDevice {
            muteStatus.toggle()
            btnMute.setTitle( muteStatus ?  "UnMute" : "Mute", for:  .normal)
            NetworkServices.network.api(device: device, action:.mute(value: muteStatus)) { responce in
                self.appendLineTime("Device mute status changed: \(responce.isFailure ? "failed" : "success")")
                if responce.isFailure {
                    self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                }
            }
        }
    }
    @IBAction func onPause(_ sender: Any) {
        appendLineTime("Playback pause command \(pauseStatus)")
        if let device = self.activeDevice {
            pauseStatus.toggle()
            btnPause.setTitle( pauseStatus ?  "Resume" : "Pause", for:  .normal)
            NetworkServices.network.api(device: device, action:.pause(value: pauseStatus)) { responce in
                self.appendLineTime("Device pause status changed: \(responce.isFailure ? "failed" : "success")")
                if responce.isFailure {
                    self.appendLineTime("❌ Command error: \(responce.error?.localizedDescription ?? "ERROR")")
                }
            }
        }
    }
    @IBAction func onLoadAndPlay(_ sender: Any) {
        
        appendLineTime("Load playlist command")
        if let device = self.activeDevice {
            
            NetworkServices.network.api(device: device, action:.playlist(list:self.playlist)) { responce1 in
                self.appendLineTime("Playlist initiation status: \(responce1.isFailure ? "failed" : "success")")
                if responce1.isSuccess {
                    DispatchQueue.main.async{
                        self.startPollingStatus(for: device)
                    }
                    NetworkServices.network.api(device: device, action: .play(id: self.playlist.first?.id ?? "--")) { responce2 in
                        self.appendLineTime("Playback status: \(responce2.isFailure ? "failed" : "success")")
                    }
                } else {
                    self.appendLineTime("❌ Playback error: \(String(describing: responce1.error?.description))")
                }
            }
        }
    }
    @IBAction func onClear(_ sender: Any) {
        self.txtLogView.text = ""
    }
}

extension ViewController: ACConnectClientDelegate {
    func deviceFound(_ device: ACDevice) {
        appendLineTime("🎯 Device found: \(device.modelName) @ \(device.ip)")
        discoveredDevices.append(device)
        
        NetworkServices.network.connect(device: device) { responce1 in
            if responce1.isSuccess {
                self.appendLineTime("Connection initiated successfully with device:\n \(responce1.value!.description)")
                NetworkServices.network.capabilities(device: device) { capabilities in
                    self.appendLineTime("Capabilities received: \(capabilities.isFailure ? "❌ failed \(String(describing: capabilities.error?.description))" : "\n \(capabilities.value?.description ?? "--")")")
                    self.activeDevice = device
                }
            } else {
                self.appendLineTime("❌ error connecting to device: \(device.modelName) @ \(device.ip)")
            }
        }
       
    }
    
    func deviceRemoved(_ device: ACDevice) {
        self.appendLineTime("❌ Device removed: \(device.modelName) @ \(device.ip)")
        discoveredDevices.removeAll { $0 == device }
    }
}

extension ViewController {
    
    func appendLine(_ line: String) {
        print(line)
        DispatchQueue.main.async {
            let currentText = self.txtLogView.text ?? ""
            let newText = currentText.isEmpty ? line : "\(currentText)\n\(line)"
            self.txtLogView.text = newText

            // Scroll to bottom
            let bottom = NSMakeRange((self.txtLogView.text as NSString).length - 1, 1)
            self.txtLogView.scrollRangeToVisible(bottom)
        }
    }
    func appendLineTime(_ line: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        appendLine("[\(timestamp)] \(line)")
    }

}
