//
//  constants.swift
//  acconnectclient
//
//  Created by Andrija Milovanovic on 30.3.25..
//
import Foundation
import UIKit

struct NetworkConstants
{
    public enum HTTPMethod : String
    {
        case options
        case get
        case head
        case post
        case put
        case patch
        case delete
        case trace
        case connect
    }
    enum HTTPHeaderField: String
    {
        case authentication = "Authorization"
        case contentType    = "Content-Type"
        case acceptType     = "Accept"
        case acceptEncoding = "Accept-Encoding"
        
    }
    
    enum ContentType: String
    {
        case json       = "application/json"
        case form       = "application/x-www-form-urlencoded"
        static var multipart: String {
            "multipart/form-data; boundary=\(NetworkConstants.App.Boundary)"
        }
    }
    enum App: String
    {
        case Boundary = "----com.streamsoftinc.artistconnectionios"
    }
    
}

struct ConnectApplication : Codable
{
    var name:String = "AC Sample App"
    var version:String = Constant.AppData.ACConnectProtocolVersion
    var appVersion:String = Constant.AppData.ACConnectAppVersion
}

struct Constant
{
    struct AppData
    {
        
        static var host:Host
        {
            return Host(uuid: Constant.AppData.HostId,
                        appVersion:  Constant.AppData.VersionStr,
                        appName: Constant.AppData.AppName,
                        osVersion: Constant.AppData.SystemVersion,
                        platform: Constant.AppData.Platform,
                        model: Constant.AppData.DeviceType)
        }
        
        static var AppName:String {
            return "AC Sample App"
        }
        
        static var HostId:String {
            return UIDevice.current.identifierForVendor!.uuidString
        }
        static var VersionStr:String {
            return  "\(Constant.AppData.Version) (\(Constant.AppData.Build))"
        }
        static var ACConnectProtocolVersion:String {
            return "1.0.3"
        }
        static var ACConnectAppVersion:String {
            return  "\(Constant.AppData.Version).(\(Constant.AppData.Build))"
        }
        
        static var Version:String {
            return  Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        }
        static var Build:String {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        }
        
        static var DeviceType :String {
            return "\(UIDevice.current.model) \(UIDevice.current.systemVersion)"
        }
        static var Language:String {
            return String(Locale.current.identifier.split(separator: "_").first ?? "")
        }
        static var Country:String {
            if let regionCode = Locale.current.regionCode, let language = Locale.current.languageCode {
                return "\(regionCode)/\(language)"
            }
            return ""
        }
        
        static var Platform:String {
            return "iOS"
        }
        static var SystemVersion:String {
            return UIDevice.current.systemVersion
        }
        
        static var DeviceId:String {
            if let uuid = UIDevice.current.identifierForVendor?.uuidString {
                return uuid.hashed() ?? ""
            }
            return ""
        }
    }
}
