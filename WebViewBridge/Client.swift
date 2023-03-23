//
//  Client.swift
//  WebViewBridge
//
//  Created by neutronstarer on 2023/3/16.
//

import Foundation
import NPC

@objcMembers
public class Client: NSObject {
    public let id: String
    
    public let namespace: String
    
    public let info: Any?
    
    public private(set) weak var webView: BridgeWebView?
    
    public func on(_ method: String, handle: Handle?){
        npc.on(method, handle: handle)
    }

    public subscript(_ method: String) -> Handle? {
        get{
            return npc[method]
        }
        set{
            npc[method] = newValue
        }
    }
    
    public func emit(_ method: String, param: Any? = nil) {
        npc.emit(method, param: param)
    }

    @discardableResult
    public func deliver(_ method: String, param: Any? = nil, timeout: TimeInterval = 0, onReply: Reply? = nil, onNotify: Notify? = nil)->Cancel{
        return npc.deliver(method, param: param, timeout: timeout, onReply: onReply, onNotify: onNotify)
    }
    
    func connect(){
        npc.connect {[weak self] message in
            guard let self = self else {
                return
            }
            let id = self.id
            let namespace = self.namespace
            let m = [namespace: ["to": id, "typ": "transmit", "body": {
                var v = [String: Any]()
                v["typ"] = message.typ.rawValue
                v["id"] = message.id
                if let method = message.method {
                    v["method"] = method
                }
                if let param = message.param {
                    v["param"] = param
                }
                if let error = message.error {
                    v["error"] = error
                }
                return v
            }()]]
            self.send(m)
        }
        self.send([namespace: ["typ": "connect", "to": id]])
    }
    
    func disconnect(){
        npc.disconnect()
    }
    
    func receive(message: [String: Any]) {
        guard let typRawValue = message["typ"] as? Int, let typ = Message.Typ(rawValue: typRawValue), let id = message["id"] as? Int else {
            return
        }
        let m = Message(typ: typ, id: id, method: message["method"] as? String, param: message["param"], error: message["error"])
        npc.receive(m)
    }
    
    required init(webView: BridgeWebView?, namespace: String, id: String, info: Any?) {
        self.webView = webView
        self.namespace = namespace
        self.id = id
        self.info = info
        super.init()
    }

    private lazy var npc: NPC = {
        let v = NPC()
        return v
    }()
    
    private func send(_ message: [String: Any]){
        guard let data = try? JSONSerialization.data(withJSONObject: message), var s = String(data: data, encoding: .utf8)  else{
            return
        }
        // Need to be optimized
        s = s.replacingOccurrences(of: "\\", with: "\\\\")
        s = s.replacingOccurrences(of: "'", with: "\\'")
        s = s.replacingOccurrences(of: "\"", with: "\\\"")
        s = s.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        s = s.replacingOccurrences(of: "\\u{2029}", with: "\\u2029")
        let js = ";(function(){try{return window['webviewbridge/\(namespace)'].send('\(s)');}catch(e){return ''};})();"
        (webView as? InnerBridgeWebView)?.evaluate(js: js, completion: nil)
    }

}
