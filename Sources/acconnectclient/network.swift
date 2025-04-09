//
//  network.swift
//  acconnectclient
//
//  Created by Andrija Milovanovic on 30.3.25..
//
import Foundation

public final class NetworkServices : NSObject
{
    private let session: URLSession
    private init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    private func setup() {
        //nothing for now
    }
    private static var session:URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 50.0
        sessionConfig.timeoutIntervalForResource = 50.0
        let session = URLSession(configuration: sessionConfig)
        return session
    }()
    public static var network: NetworkServices = {
        
        let net = NetworkServices(session:NetworkServices.session)
        net.setup()
        return net
    }()
}

    
public struct ACConnectError : Codable, Error
{
    public let error:String
    public let code:Int?
    
    public var description: String {
        return "\(error) - \(code ?? 0)"
    }
}


public typealias VoidResponse = Result< Empty, ACConnectError>
public typealias ConnectStatusResponse = Result<StatusReceive,ACConnectError>
public typealias ConnectResponse = Result<ConnectReceive, ACConnectError>
public typealias ConnectCapabilitiesResponse = Result<CapabilitiesReceive,ACConnectError>

extension NetworkServices
{
    public func capabilities(device:ACDevice, onComplete:@escaping (ConnectCapabilitiesResponse)->Void )
    {
        return ExecRequest(device: device, action: ConnectEndpoints.capabilities, onComplete:onComplete)
    }
    public func api(device:ACDevice, action:ConnectEndpoints, onComplete:@escaping (VoidResponse)->Void)
    {
        return ExecRequest(device: device, action:action, onComplete:onComplete)
    }
    public func connect(device:ACDevice, onComplete:@escaping (ConnectResponse)->Void)
    {
        return ExecRequest(device: device, action: ConnectEndpoints.connect, onComplete:onComplete)
    }
    public func disconnect(device:ACDevice, onComplete:@escaping (VoidResponse)->Void)
    {
        return ExecRequest(device: device, action: ConnectEndpoints.disconnect, onComplete:onComplete)
    }
    public func status(device:ACDevice, onComplete:@escaping (ConnectStatusResponse)->Void )
    {
        return ExecRequest(device: device, action: ConnectEndpoints.status, onComplete:onComplete)
    }
}
extension NetworkServices
{
    private func ExecRequest<T: Decodable>(
        device: ACDevice,
        action: ServerEndpoints,
        onComplete: @escaping (Result<T, ACConnectError>) -> Void
    ) {
        let baseUrl = device.ip.hasPrefix("http") ? device.ip : "http://\(device.ip)"
        let fullPath = device.path.isEmpty ? "\(baseUrl)\(action.path)" : "\(baseUrl)\(device.path)\(action.path)"
        
        ExecRequest(action: action, fullPath: fullPath, onComplete: onComplete)
    }
    
    
    private func ExecRequest<T: Decodable>(
            action: ServerEndpoints,
            fullPath: String,
            onComplete: @escaping (Result<T, ACConnectError>) -> Void
        ) {
           
            guard let url = URL(string: fullPath) else {
                onComplete(.failure( ACConnectError(error: "Invalid URL --> \(fullPath) ", code: 500)))
                return
            }
            print("--> URL: \(url)")
            
            var request = URLRequest(url: url)
            request.httpMethod = action.method.rawValue
            if let body = action.body {
                request.httpBody = body
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            session.dataTask(with: request) { data, response, error in
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    onComplete(.failure( ACConnectError(error: "Invalid response object", code: 500)))
                    return
                }
                
                let statusCode = httpResponse.statusCode
                
                if let error = error {
                    onComplete(.failure( ACConnectError(error: error.localizedDescription, code: statusCode)))
                    return
                }
                
                print("<-- URL: status: \(statusCode) \(url)")
                
                guard let data = data else {
                    onComplete(.failure( ACConnectError(error: "No data received", code: statusCode)))
                    return
                }
                
                guard (200..<300).contains(statusCode) else {
                    onComplete(.failure(self.errorData(data: data, statusCode: statusCode)))
                    return
                }
                
                if data.isEmpty {
                    guard let emptyResponseType = T.self as? EmptyResponse.Type,
                          let emptyValue = emptyResponseType.emptyValue() as? T else {
                        onComplete(.failure( ACConnectError(error: "No data received", code: statusCode)))
                        return
                    }
                    onComplete(.success(emptyValue))
                    return
                }
                
                var str = String(data: data, encoding: .utf8) ?? "NA"
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    onComplete(.success(decoded))
                } catch {
                    onComplete(.failure( ACConnectError(error: "Decoding error: \(error.localizedDescription) \n \(str)", code: statusCode)))
                }
            }.resume()
        }
    
    private func errorData(data:Data, statusCode:Int) -> ACConnectError
    {
        var err = try? ACConnectError.decode(data: data)
        if err == nil {
            let statusError = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            let messageError = String(data: data, encoding: .utf8) ?? ""
            err =  ACConnectError(error: statusError + " " + messageError, code: statusCode)
        }
        return err!
    }
}
