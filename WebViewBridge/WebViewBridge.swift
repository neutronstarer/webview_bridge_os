//
//  WebViewBridge.swift
//  WebViewBridge
//
//  Created by neutronstarer on 2023/3/15.
//

import WebKit
import NPC

public typealias BridgeHandle = (_ client: Client, _ param: Any?, _ reply: @escaping Reply, _ notify: @escaping Notify) -> Cancel?

@objcMembers
public class WebViewBridge: NSObject {
    
    public func on(_ method: String, _ handle: BridgeHandle?){
        self[method] = handle
    }
    
    public subscript(_ method: String) -> BridgeHandle? {
        get{
            var handle: BridgeHandle?
            queue.sync {
                handle = handlers[method]
            }
            return handle
        }
        set{
            queue.sync {
                handlers[method] = newValue
                clientById.forEach { (key: String, value: Client) in
                    guard let newValue = newValue else {
                        value[method] = nil
                        return
                    }
                    value[method] = {[weak value](_ param: Any?, _ reply: @escaping Reply, _ notify: @escaping Notify) -> Cancel? in
                        guard let value = value else {
                            return {}
                        }
                        return newValue(value, param, reply, notify)
                    }
                }
            }
        }
    }
    
    public var clients: [String: Client]{
        var x: [String: Client]!
        queue.sync {
            x = clientById
        }
        return x
    }
    
    deinit {
        queue.sync {
            clientById.forEach { (key: String, value: Client) in
                value.disconnect()
            }
        }
    }
    
    required init(_ namespace: String, _ webView: InnerBridgeWebView) {
        self.namespace = namespace
        self.webView = webView
        super.init()
        webView.initializeWith(bridge: self)
    }
    
    func load(){
        webView?.evaluate(js:loadJS, completion: nil)
    }
    
    func query(){
        webView?.evaluate(js: ";(function(){try{return window['webviewbridge/\(namespace)'].query();}catch(e){return '[]'};})();", completion: {[weak self] res in
            guard let self = self, let data = (res as? String)?.data(using: .utf8), let messages = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return
            }
            messages.forEach { message in
                guard let m = message[self.namespace] as? [String: Any] else {
                    return
                }
                self.queue.async {
                    self.receive(message: m)
                }
            }
        })
    }
    
    func receive(message: [String: Any]){
        self.queue.async {[weak self] in
            guard let self = self else {
                return
            }
            let namespace = self.namespace
            guard let from = message["from"] as? String else {
                return
            }
            let typ = message["typ"] as? String
            switch typ {
            case "transmit":
                guard let client = self.clientById[from], let body = message["body"] as? [String: Any] else {
                    return
                }
                client.receive(message: body)
                break
            case "connect":
                let client = Client(webView: self.webView, namespace: namespace, id: from, info: message["body"] as? [String: Any])
                client.connect()
                self.handlers.forEach { (key: String, value: @escaping BridgeHandle) in
                    client[key] = {[weak client] (_ param: Any?, _ reply: @escaping Reply, _ notify: @escaping Notify) -> Cancel? in
                        guard let client = client else {
                            return {}
                        }
                        return value(client, param, reply, notify)
                    }
                }
                self.clientById[from] = client
                break
            case "disconnect":
                self.clientById[from]?.disconnect()
                self.clientById[from] = nil
                break
            default:
                
                break
            }
        }
    }
    private let namespace: String
    private let queue = DispatchQueue(label: "com.neutronstarer.webviewbridge")
    private weak var webView: InnerBridgeWebView?
    private lazy var handlers = [String: BridgeHandle]()
    private lazy var clientById = [String: Client]()
    private lazy var loadJS: String = {
#if DEBUG
        let path = Bundle(for: WebViewBridge.self).path(forResource: "webview_bridge.umd.development", ofType: "js")
#else
        let path = Bundle(for: WebViewBridge.self).path(forResource: "webview_bridge.umd.production.min", ofType: "js")
#endif
        var js = try! String(contentsOfFile: path!)
        js = js.replacingOccurrences(of: "<namespace>", with: namespace)
        return js
    }()
}

