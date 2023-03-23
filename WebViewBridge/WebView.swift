//
//  WebView.swift
//  WebViewBridge macOS
//
//  Created by neutronstarer on 2023/3/15.
//

#if os(OSX)
import WebKit

extension WebView: InnerBridgeWebView {
    
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
            let v = stringByEvaluatingJavaScript(from: js)
            completion?(v)
        }else{
            DispatchQueue.main.async {
                let v = self.stringByEvaluatingJavaScript(from: js)
                completion?(v)
            }
        }
    }
    func initializeBridge() {
        
    }
}
#endif
