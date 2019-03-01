//
//  TelegraphDemo.swift
//  Telegraph Examples
//
//  Created by Yvo van Beek on 5/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Telegraph
import WebKit

public class TelegraphDemo: NSObject {
  var identity: CertificateIdentity?
  var caCertificate: Certificate?
  var tlsPolicy: TLSPolicy?

  var server: Server!
  var webSocketClient: WebSocketClient!
  var port:Int!
}


extension TelegraphDemo {
    public func startSSL() {
        // Comment out this line if you want HTTP instead of HTTPS
        loadCertificates()

        // Create and start the server
        setupSSLServer()
    }
    
    public func start() {
        // Create and start the server
        setupServer()
    }
}

extension TelegraphDemo {
  private func loadCertificates() {
    // Load the P12 identity package from the bundle
    if let identityURL = Bundle.main.url(forResource: "ssl", withExtension: "p12") {
      identity = CertificateIdentity(p12URL: identityURL, passphrase: "password")
        print(identity)
    }

    // Load the Certificate Authority certificate from the bundle
    if let caCertificateURL = Bundle.main.url(forResource: "symbian", withExtension: "der") {
      caCertificate = Certificate(derURL: caCertificateURL)
        print(caCertificateURL)
    }

    // We want to override the default SSL handshake. We aren't using a trusted root
    // certificate authority and the hostname doesn't match the common name of the certificate.
    //local.get-scatter.com
    if let caCertificate = caCertificate {
      tlsPolicy = TLSPolicy(commonName: "scatter", certificates: [caCertificate])
    }
  }

  private func setupSSLServer() {
    // Create the server instance
    if let identity = identity, let caCertificate = caCertificate {
      server = Server(identity: identity, caCertificates: [caCertificate])
    } else {
      server = Server()
    }
 
    // Set the delegates and a low web socket ping interval to demonstrate ping-pong
    server.delegate = self
    server.webSocketDelegate = self
    server.webSocketConfig.pingInterval = 10


    server.serveBundle(.main, "/")

    // Handle up to 4 requests simultaneously
    server.concurrency = 4

    // Start the server on localhost
    // Note: we'll skip error handling in the demo
    try! server.start(port: 50006)
    port = 50006
    // Log the url for easy access
    print("[SERVER]", "Server is running - url:", serverURL())
  }
    
    private func setupServer() {
        // Create the server instance
        if let identity = identity, let caCertificate = caCertificate {
            server = Server(identity: identity, caCertificates: [caCertificate])
        } else {
            server = Server()
        }
        
        // Set the delegates and a low web socket ping interval to demonstrate ping-pong
        server.delegate = self
        server.webSocketDelegate = self
        server.webSocketConfig.pingInterval = 10
        
        server.serveBundle(.main, "/")
        
        // Handle up to 4 requests simultaneously
        server.concurrency = 4
        
        // Start the server on localhost
        // Note: we'll skip error handling in the demo
        try! server.start(port: 50005)
        port = 50005
        // Log the url for easy access
        print("[SERVER]", "Server is running - url:", serverURL())
    }
}

// MARK: - Server route handlers

extension TelegraphDemo {
  /// Raised when the /hello endpoint is called.
  private func serverHandleHello(request: HTTPRequest) -> HTTPResponse {
    let name = request.params["name"] ?? "stranger"
    return HTTPResponse(content: "Hello \(name.capitalized)")
  }

  /// Raised when the /redirect endpoint is called.
  private func serverHandleRedirect(request: HTTPRequest) -> HTTPResponse {
    let response = HTTPResponse(.temporaryRedirect)
    response.headers.location = "https://www.google.com"
    return response
  }

  /// Raised when the /data endpoint is called.
  private func serverHandleData(request: HTTPRequest) -> HTTPResponse {
    // Decode the request body using the JSON decoder, fallback to "stranger" if the data is invalid
    let requestDict = try? JSONDecoder().decode([String: String].self, from: request.body)
    let name = requestDict?["name"] ?? "stranger"

    // Send a JSON response containing the name of our visitor
    let responseDict = ["welcome": name]
    let jsonData = try! JSONEncoder().encode(responseDict)
    return HTTPResponse(body: jsonData)
  }
}

// MARK: - ServerDelegate implementation

extension TelegraphDemo: ServerDelegate {
  // Raised when the server gets disconnected.
  public func serverDidStop(_ server: Server, error: Error?) {
    print("[SERVER]", "Server stopped:", error?.localizedDescription ?? "no details")
  }
}

// MARK: - ServerWebSocketDelegate implementation

extension TelegraphDemo: ServerWebSocketDelegate {
  /// Raised when a web socket client connects to the server.
  public func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
    let name = handshake.headers["X-Name"] ?? "stranger"
    print("[SERVER]", "WebSocket connected - name:", name)

    //webSocket.send(text: "Welcome client \(name)")
    //webSocket.send(data: Data(bytes: [0x00, 0x01, 0x02, 0x03, 0x04, 0x05]))
  }

  /// Raised when a web socket client disconnects from the server.
  public func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
    print("[SERVER]", "WebSocket disconnected:", error?.localizedDescription ?? "no details")
  }
    
func getJSONStringFromDictionary(dictionary:NSDictionary) -> String {
    if (!JSONSerialization.isValidJSONObject(dictionary)) {
        print("无法解析出JSONString")
        return ""
    }
    let data : NSData! = try! JSONSerialization.data(withJSONObject: dictionary, options: []) as NSData
    let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
    return JSONString! as String
    
}
  /// Raised when the server receives a web socket message.
  public func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
    if(message.opcode == .textFrame){
//        print("[SERVER]", "WebSocket message received:", message)
        print("messageIn: ",message.payload)
        if case let WebSocketPayload.text(a) = message.payload {
            print("String:",a)
            /*scatter协议规则就是：
             网页给我们发过来的消息格式为："42/scatter,[json数据]" 的字符串
             我们第一步解析42/scatter是否正确
             接着解析后面的json数据是想要登陆还是交易
             */
            //获取协议字符串
            let proto_l = a.index(a.startIndex, offsetBy: 0)
            let proto_r = a.index(a.startIndex, offsetBy: 10)
            let protoGet = a[proto_l..<proto_r];
            print("protoString:",protoGet)
            
            //设置标准协议字符串
            let protoStd = "42/scatter";
            
            print("protoString:",a[proto_l..<proto_r])
            if (protoStd == protoGet){
                //获取剩余json数据
                let json_l = a.index(a.startIndex, offsetBy: 11)
                let jsonStr = a[json_l..<a.endIndex]
                
                print("jsonString:",jsonStr);
                let jsonData:Data = jsonStr.data(using: .utf8)!
                
                let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                let a = array as? NSArray
                
                let protoElement = a?[0];
                let dataElement = a?[1];
                let s = protoElement as?String;
                print(s);
                if (s == "pair"){
                    //print(dataElement!);
                    print("in pair")
                    webSocket.send(text:"42/scatter,[\"paired\",true]");
                   
                }
                else if (s == "api"){
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    var dict = dataElement as?[String:Any]
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    // 所有Web端发过来的信息都在这里 记住 dict ******！！！！！！！！！！！！
                    
                    
                    
                    let dataDict = dict?["data"]as?[String:Any]
                    
                    let typeStr = dataDict?["type"]as?String
                    let id = dataDict?["id"]as!String
                    print("typeStr:",typeStr)
                    print("id:",id);
                    //var MiddleResp = String(format: "{\"id\":%ls,\"result\":true}", arguments:[id])
                    //print(MiddleResp);
                    var left = "42/scatter,[\"api\",";
                    var right = "]";
//                    var DIC:[String:String] = [:]
//                    DIC["id"] = id;
//                    DIC["result"] = true;
                    
                    

                    
                    if (typeStr == "requestAddNetwork"){
                        print("in requestAddNetwork")

                        let DIC = ["id":id,"result":true] as [String : Any]
                        let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                        
                        let respData = left + jsonStr + right;
                        
                        webSocket.send(text:respData);
                        //{"id":id,"result":true}
                    }
                    else if (typeStr == "forgetIdentity"){
                        print("in forgetIdentity")
                        var result = true;
                        let DIC = ["id":id,"result":result] as [String : Any]
                        let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                        
                        let respData = left + jsonStr + right;
                        
                        webSocket.send(text:respData);
                    }
                    else if (typeStr == "getOrRequestIdentity"){
                        print("in getOrRequestIdentity")
                        var path="http://3.17.163.147:3000/eos/scatter/getOrRequestIdentity";
                        var result = "{\"accounts\":[{\"authority\":\"active\",\"blockchain\":\"eos\",\"name\":\"gtygavintest\",\"publicKey\":\"EOS8ivzcSu6Co6hJXaTfPjGyXUX2jnrK5VKrsQ9DXhKcBPF9TZj8p\"}],\"hash\":\"aljdfhbvadkfjnvapdifuh\",\"kyc\":false,\"name\":\"MyIdentity\",\"publicKey\":\"EOS8PadkjfhbvladjfhbvRenxofzjHmNminKPLCQzcVaGRh9PnPNpt4W4YmJa\"}"
                        let DIC = ["id":id,"result":result] as [String : Any]
                        let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                        
                        let respData = left + jsonStr + right;
                        print(respData);
                        webSocket.send(text:respData);
                        /*
                         1.取出web端传回的所有dict ******！！！！！！！！！！！！
                         2.得到的回包为ResponseData
                         ResponseDataExample为:
                         {
                             "code": 1,
                             "status": 0,
                             "message": "请求成功",
                             "data": {
                                 "result": {
                                     "accounts": [
                                         {
                                         "authority": "active",
                                         "blockchain": "eos",
                                         "name": "gtygavintest",
                                         "publicKey": "EOS8ivzcSu6Co6hJXaTfPjGyXUX2jnrK5VKrsQ9DXhKcBPF9TZj8p"
                                         }
                                    ],
                                     "hash": "aljdfhbvadkfjnvapdifuh",
                                     "publicKey": "EOS8PadkjfhbvladjfhbvRenxofzjHmNminKPLCQzcVaGRh9PnPNpt4W4YmJa",
                                     "name": "MyIdentity",
                                     "kyc": false
                                }
                             }
                         }
                         3.判断一下code与status，取出ResponseData中data字段->result字段 的内容，命名为ResponseDataResult
                         4.将k-v对 "id":id 字段放入字典中，并将ResponseDataResult转换成字符串result放入字典中
                             ex:
                                let DIC = ["id":id,"result":result] as [String : Any]
                                let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                         5.拼接
                            ex:
                                let respData = left + jsonStr + right;
                         6.发送
                            ex:
                                webSocket.send(text:respData);
                         
                        */
                        
//                        var result = responseBody.result;
//
//                        let DIC = ["id":id,"result":result] as [String : Any]
//                        let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
//
//                        let respData = left + jsonStr + right;
//
//                        webSocket.send(text:respData);
                        //"UID=testUID"
                    }
                    else if (typeStr == "identityFromPermissions"){
                        print("in identityFromPermissions")
                        var path="http://3.17.163.147:3000/eos/scatter/identityFromPermissions";
                        let result = "{\"accounts\":[{\"authority\":\"active\",\"blockchain\":\"eos\",\"name\":\"gtygavintest\",\"publicKey\":\"EOS8ivzcSu6Co6hJXaTfPjGyXUX2jnrK5VKrsQ9DXhKcBPF9TZj8p\"}"
                        
                        let DIC = ["id":id,"result":result] as [String : Any]
                        let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                        
                        let respData = left + jsonStr + right;
                        print(respData);
                        webSocket.send(text:respData);
                        /*
                         1.发送post请求到path上 post body为{"UID":"testUID"}
                         2.得到的回包为ResponseData
                         ResponseDataExample为:
                         {
                             "code": 1,
                             "status": 0,
                             "message": "请求成功",
                             "data": {
                                 "result": {
                                     "accounts": [
                                         {
                                             "authority": "active",
                                             "blockchain": "eos",
                                             "name": "gtygavintest",
                                             "publicKey": "EOS8ivzcSu6Co6hJXaTfPjGyXUX2jnrK5VKrsQ9DXhKcBPF9TZj8p"
                                         }
                                    ]
                                 }
                             }
                         }
                         3.判断一下code与status，取出ResponseData中data字段->result字段 的内容，命名为ResponseDataResult
                         4.将k-v对 "id":id 字段放入字典中，并将ResponseDataResult转换成字符串result放入字典中
                         ex:
                         let DIC = ["id":id,"result":result] as [String : Any]
                         let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                         5.拼接
                         ex:
                         let respData = left + jsonStr + right;
                         6.发送
                         ex:
                         webSocket.send(text:respData);
                         
                         */
                    }
                    else if (typeStr == "requestSignature"){
                        print("in requestSignature")
                        var path_originData = "http://3.17.163.147:3000/eos/scatter/getOriginData";
                        var path_signature="http://3.17.163.147:3000/eos/scatter/requestSignature";
                        /*
                         
                         1.取出dict（web端传过来的数据都在这里）中data字段->payload字段->transaction字段 的内容，命名为txData
                         2.发送post请求到path_originData上 post body为{"data":txData(第一步获取到的数据)}
                         3.得到的回包为ResponseData1
                         ResponseData1Example为:
                         {
                             "code": 1,
                             "status": 0,
                             "message": "请求成功",
                             "data": {
                                 "from": "zjugtyzjugty",
                                 "to": "mark11111111",
                                 "quantity": "0.0001 EOS",
                                 "memo": "scatter 转账测试"
                             }
                         }
                         4.判断一下code与status，取出ResponseData1中data字段 的内容，并使用支付弹窗显示出来，提供给用户授权
                         
                         5.如果用户点击确认授权，取出dict（web端传过来的数据都在这里）中data字段->payload字段->buf字段 的内容，命名为buf
                         6.发送post请求到path_signature上 post body为{"UID":"testUID","buf":buf(第5步获取的数据)}
                         7.得到的回包为ResponseData2
                         ResponseData2Example为:
                         {
                             "code": 1,
                             "status": 0,
                             "message": "请求成功",
                             "data": {
                                 "result": {
                                     "signatures": [
                                     "SIG_K1_KmHrhccTcbMdfGcN3H9mk2Jkz4Ui3zkFEUqya4Crhdak8szu72EdZKvdJs2gjNbbgfnTVVnuoxCUBmUW9uUebjrCeJyYYu"
                                     ],
                                     "returnedFields": {}
                                 }
                             }
                         }
                         8.判断一下code与status，取出ResponseData2中data字段->result字段 的内容，命名为ResponseDataResult
                         9.将k-v对 "id":id 字段放入字典中，并将ResponseDataResult转换成字符串result放入字典中
                             ex:
                             let DIC = ["id":id,"result":result] as [String : Any]
                             let jsonStr = getJSONStringFromDictionary(dictionary: DIC as NSDictionary)
                         10.拼接
                             ex:
                             let respData = left + jsonStr + right;
                         11.发送
                             ex:
                             webSocket.send(text:respData);
                        */
                         
                         
 
                    }

                }

            }

        }

        print("port!: ",port)
    }
  }

  /// Raised when the server sends a web socket message.
  public func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
    if(message.opcode == .textFrame){
        print("[SERVER]", "WebSocket message sent:", message)
    }
  }
}

// MARK: - URLSessionDelegate implementation

extension TelegraphDemo: URLSessionDelegate {
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // Use our custom TLS policy to verify if the server should be trusted
    let credential = tlsPolicy!.evaluateSession(trust: challenge.protectionSpace.serverTrust)
    completionHandler(credential == nil ? .cancelAuthenticationChallenge : .useCredential, credential)
  }
}


// MARK: Request helpers

extension TelegraphDemo {
  /// Generates a server url, we'll assume the server has been started.
 
  private func serverURL(path: String = "") -> URL {
    var components = URLComponents()
    components.scheme = server.isSecure ? "https" : "http"
    components.host = "localhost"
    components.port = Int(server.port)
    components.path = path
    return components.url!
  }
 
}

