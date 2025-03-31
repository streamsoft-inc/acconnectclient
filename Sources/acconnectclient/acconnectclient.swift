// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Network

public struct ACDevice: Hashable {
    public let ip: String
    public let manufacturer: String
    public let modelName: String
    public let capabilities: String
    public let path: String
    public let hostName:String
}

public protocol ACConnectClientDelegate: AnyObject {
    func deviceFound(_ device: ACDevice)
    func deviceRemoved(_ device: ACDevice)
}

public final class ACConnectClient: NSObject {
    @MainActor public static let shared = ACConnectClient()
    
    private var netServiceBrowsers: [NetServiceBrowser] = []
    private var discoveredServices: Set<NetService> = []
    private var resolvedDevices: [NetService: ACDevice] = [:]
    private let serviceTypes = ["_artist_connection._tcp.", "_acconnect_streaming._tcp."]
    
    public weak var delegate: ACConnectClientDelegate?
    
    private override init() {
        super.init()
    }
    
    public func startScanning() {
        stopScanning()
        for type in serviceTypes {
            let browser = NetServiceBrowser()
            browser.delegate = self
            browser.searchForServices(ofType: type, inDomain: "")
            netServiceBrowsers.append(browser)
        }
    }
    
    public func stopScanning() {
        for browser in netServiceBrowsers {
            browser.stop()
        }
        netServiceBrowsers.removeAll()
        discoveredServices.removeAll()
        resolvedDevices.removeAll()
    }
    
    public func connect(to device: ACDevice) {
        // You can implement this part later (e.g., HTTP/WebSocket connection)
        print("Connecting to \(device.ip)...")
    }
}

// MARK: - NetServiceBrowserDelegate

extension ACConnectClient: NetServiceBrowserDelegate {
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        discoveredServices.insert(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let device = resolvedDevices[service] {
            delegate?.deviceRemoved(device)
            resolvedDevices.removeValue(forKey: service)
        }
        discoveredServices.remove(service)
    }
}

// MARK: - NetServiceDelegate

extension ACConnectClient: NetServiceDelegate {
    public func netServiceDidResolveAddress(_ sender: NetService) {

        guard let addresses = sender.addresses else { return }

        var ipAddress:String = "", manufacturer:String = "", modelName:String = "", capabilities: String = "", path: String = ""
        if let data = sender.txtRecordData()
        {
            let dict = NetService.dictionary(fromTXTRecord: data)
            
            manufacturer    =  String(data: dict["manufacturer"] ?? Data(), encoding: String.Encoding.utf8) ?? ""
            modelName       =  String(data: dict["modelName"] ?? Data(), encoding: String.Encoding.utf8) ?? ""
            capabilities    =  String(data: dict["capabilities"] ?? Data(), encoding: String.Encoding.utf8) ?? ""
            path            =  String(data: dict["path"] ?? Data(), encoding: String.Encoding.utf8) ?? ""
        }
        
        if let (ip,port) = resolveIP(addresses: addresses, port: sender.port)
        {
            ipAddress = "http://\(ip):\(port)"
        }
        
        let device = ACDevice(
            ip: ipAddress,
            manufacturer: manufacturer,
            modelName: modelName,
            capabilities: capabilities,
            path: path,
            hostName: sender.hostName ?? ""
        )

        resolvedDevices[sender] = device
        delegate?.deviceFound(device)
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Failed to resolve service: \(sender), error: \(errorDict)")
    }
    private func resolveIP(addresses: [Data], port:Int) -> (ip:String,port:String)?
    {
        var ipv4:(String,String)? = nil
        var ipv6:(String,String)? = nil
        
        for addr in addresses
        {
            let data = addr as NSData

            var inetAddress = sockaddr_in()
            data.getBytes(&inetAddress, length:MemoryLayout<sockaddr_in>.size)
            if inetAddress.sin_family == __uint8_t(AF_INET)
            {
                if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .ascii)
                {
                    if !ip.hasPrefix("169.254") {
                        // IPv4
                        let _ = _OSSwapInt16(inetAddress.sin_port)
                        var port = String(port)
                        if port.isEmpty {
                            port = "80"
                        }
                        ipv4 = ( ip, port )
                    }
                }
            }
            else if inetAddress.sin_family == __uint8_t(AF_INET6)
            {
                
                var inetAddress6 = sockaddr_in6()
                data.getBytes(&inetAddress6, length:MemoryLayout<sockaddr_in6>.size)
                let ipStringBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                var addr = inetAddress6.sin6_addr

                if let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &addr, ipStringBuffer, __uint32_t(INET6_ADDRSTRLEN))
                {
                    if let ip = String(cString: ipString, encoding: .ascii)
                    {
                        if !ip.hasPrefix("fe80::ffff:ffff"), !ip.hasPrefix("fdff:ffff:ffff:ffff")
                        {
                            let _ = _OSSwapInt16(inetAddress.sin_port)
                            var port = String(port)
                            if port.isEmpty {
                                port = "80"
                            }
                            ipv6 = ( ip, port )
                        }
                    }
                }

                ipStringBuffer.deallocate()
            }

        }
        
        return ipv4 ?? ipv6
    }
}
