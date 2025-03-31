//
//  network.swift
//  acconnectclient
//
//  Created by Andrija Milovanovic on 30.3.25..
//
import Foundation

public struct ConnectPlaylist : Codable
{
    public let id:String
    public let url:URL
    public let type:ConnectPlayItemType
    public let duration:Float
    public let metadata:ConnectMetadata
    public init(id: String, url: URL, type: ConnectPlayItemType, duration: Float, metadata: ConnectMetadata) {
        self.id = id
        self.url = url
        self.type = type
        self.duration = duration
        self.metadata = metadata
    }
}
public enum ConnectPlayItemType : String, Codable
{
    case VIDEO
    case AUDIO
}
public enum ConnectPlayItemState: String, Codable
{
    case PLAYING
    case PAUSED
    case BUFFERING
    case END
    case ENDED
}

public struct ConnectMetadata : Codable {
    public let title:String
    public let albumName:String?
    public let artistName:String?
    public let format:ConnectFormatItem
    public let artworkUrl:URL?
    
    public init(title: String, albumName: String?, artistName: String?, format: ConnectFormatItem, artworkUrl: URL?) {
        self.title = title
        self.albumName = albumName
        self.artistName = artistName
        self.format = format
        self.artworkUrl = artworkUrl
    }
}
public enum ConnectFormatItem : String, Codable
{
    case AURO
    case MQA
    case DOLBY
    case SONY
    case OTHER
}
public struct StatusReceive: Codable
{
    public let id:String
    public let state:ConnectPlayItemState
    public let position:FloatOrString?
    public let error:String?
    public let log:String?
}
public struct ConnectReceive : Codable
{
    public var name:String = "NONE"
    public var version:String = "0"
    public var description: String {
        return """
                    name:\(name)
                    version:\(version)
                """
    }
}
public struct CapabilitiesReceive : Codable
{
    public let volume: Bool
    public let video: Bool
    public let stream: [String]
    public let format: [String]?
    public let device: [String]?
    public let channel: [String]?
    
    public var description: String {
        return """
                Volume:\(volume)
                Video:\(video)
                Stream:\(stream.map{$0}.joined(separator:","))
                Format:\(format?.map{$0}.joined(separator:",") ?? "--")
                Device:\(device?.map{$0}.joined(separator:",") ?? "--")
                Channel:\(channel?.map{$0}.joined(separator:",") ?? "--")
                """
    }
    
}
public struct Host : Codable
{
    let uuid:String
    let appVersion:String
    let appName:String
    let osVersion:String
    let platform:String
    let model:String
}
protocol ServerEndpoints {
    var path: String { get }
    var body: Data? { get }
    var method: NetworkConstants.HTTPMethod { get }
}

public enum ConnectEndpoints : ServerEndpoints
{
    case playlist(list:[ConnectPlaylist])
    case play(id:String)
    case pause(value:Bool?)
    case next
    case previous
    case seek(offset:Float64)
    case stop
    case capabilities
    case status
    case connect
    case disconnect
    case mute(value:Bool)
    case volume(value:Float)
    
    var path: String {
        switch self {
        case .playlist: return "/media/load/playlist"
        case .play:     return "/media/play"
        case .pause(let value):    return value == nil ? "/media/pause" :"/media/pause?value=\(value!)"
        case .next:     return "/media/next"
        case .previous: return "/media/previous"
        case .seek:     return "/media/seek"
        case .stop:     return "/media/stop"
        case .capabilities:     return "/device/capabilities"
        case .status:   return "/media/status"
        case .connect:  return "/device/connect"
        case .disconnect: return "/device/disconnect"
        case .mute:     return "/media/mute"
        case .volume:   return "/media/volume"
        }
    }
    var body: Data?
    {
        switch self {
        case .playlist(let list):   return list.encode()
        case .play(let id):         return ["id":id].encode()
        case .seek(let offset):     return ["position":offset].encode()
        case .mute(let mute):       return ["value":mute].encode()
        case .volume(let volume):   return ["value":volume].encode()
        case .connect:              return ConnectApplication().encode()
        default: return nil
        }
    }
    var method: NetworkConstants.HTTPMethod {
        switch self {
        case    .capabilities,
                .status:
            return .get
        default:
            return .post
        }
    }
    
}
