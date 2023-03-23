//
//  WKWebView.swift
//  WebViewBridge
//
//  Created by neutronstarer on 2023/3/15.
//


import WebKit

extension WKWebView: InnerBridgeWebView {
    
    @objc
    public override func bridge(of namespace: String) -> WebViewBridge {
        return super.bridge(of: namespace)
    }
    
    @objc
    public override func bridgePolicy(of url: URL) -> BridgePolicy {
        return super.bridgePolicy(of: url)
    }
    
    func evaluate(js: String,completion: ((Any?) -> Void)?) {
        if Thread.isMainThread {
            evaluateJavaScript(js) { result, error in
                completion?(result)
            }
        }else{
            DispatchQueue.main.async {
                self.evaluateJavaScript(js) { result, error in
                    completion?(result)
                }
            }
        }
    }
    func initializeBridge() {
        configuration.userContentController.removeScriptMessageHandler(forName: "webviewbridge")
        configuration.userContentController.add(WebViewBridgeMessageHandler.shared, name: "webviewbridge")
    }
}

class WebViewBridgeMessageHandler: NSObject, WKScriptMessageHandler {
 
    static let shared = WebViewBridgeMessageHandler()

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage){
        if let data = (message.body as? String)?.data(using: .utf8), let m = try? JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>{
            m.forEach { (key: String, value: Any) in
                guard let value = value as? [String: Any] else {
                    return
                }
                let bridge = message.webView?.bridge(of: key, creatable: false)
                bridge?.receive(message: value)
            }
        }
    }
    
    private override init() {
        super.init()
    }
    
}
