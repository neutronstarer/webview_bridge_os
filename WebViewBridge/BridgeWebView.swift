//
//  BridgeWebView.swift
//  WebViewBridge
//
//  Created by neutronstarer on 2023/3/15.
//

import Foundation

@objc
public enum BridgePolicy: Int {
    case cancel = 0
    case allow = 1
}

@objc
public protocol BridgeWebView {
    @objc
    func bridge(of name: String)-> WebViewBridge
    @objc
    func bridgePolicy(of url: URL) -> BridgePolicy
}

protocol InnerBridgeWebView: BridgeWebView {
    func evaluate(js: String, completion: ((Any?) -> Void)?)
    func initializeBridge()->Void
}

extension NSObject {
    
    @objc
    func bridge(of name: String) -> WebViewBridge {
        return bridge(of: name, creatable: true)!
    }
    
    @objc
    func bridgePolicy(of url: URL) -> BridgePolicy {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = comps.host, host == "webviewbridge" else {
            return .allow
        }
        guard let namespace = comps.queryItems?.first(where: { item in
            return item.name == "namespace"
        })?.value else {
            return .cancel
        }
        guard let bridge = bridge(of: namespace, creatable: false) else {
            return .cancel
        }
        guard let action = comps.queryItems?.first(where: { item in
            return item.name == "action"
        })?.value else {
            return .cancel
        }
        switch action {
        case "load":
            bridge.load()
        case "query":
            bridge.query()
        default:
            break
        }
        return .cancel
    }
        
    func bridge(of namespace: String, creatable: Bool)->WebViewBridge? {
        objc_sync_enter(self)
        defer{
            objc_sync_exit(self)
        }
        var bridgeByNamespace: NSMutableDictionary!
        if let v = objc_getAssociatedObject(self, &AssociatedKeys.bridges) as? NSMutableDictionary {
            bridgeByNamespace = v
        }else{
            bridgeByNamespace = NSMutableDictionary()
            objc_setAssociatedObject(self, &AssociatedKeys.bridges, bridgeByNamespace, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if let bridge = bridgeByNamespace[namespace] as? WebViewBridge {
            return bridge
        }
        if creatable == false {
            return nil
        }
        let bridge = WebViewBridge(namespace, self as! InnerBridgeWebView)
        bridgeByNamespace[namespace]=bridge
        return bridge
    }
}

private struct AssociatedKeys {
    static var bridges = "bridgesKey"
}
