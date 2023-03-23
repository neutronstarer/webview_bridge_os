//
//  ViewController.swift
//  Example iOS
//
//  Created by neutronstarer on 2023/3/16.
//

import UIKit
import WebKit
import WebViewBridge

class WebView: WKWebView {
    deinit {
        debugPrint("WebView deinit")
    }
}


class ViewController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        let bridge = webView.bridge(of: "com.neutronstarer.webviewbridge")
        bridge["download"] = {client, param, reply, notify in
            let timer = DispatchSource.makeTimerSource()
            var i = 0
            timer.setEventHandler {[weak timer] in
                if i == 3 {
                    reply("did download to \(param!)", nil)
                    timer?.cancel()
                }else{
                    i+=1
                    notify("\(i)")
                }
            }
            timer.schedule(deadline: .now(), repeating: .seconds(1))
            timer.resume()
            return {
                timer.cancel()
            }
        }
        bridge["open"] = {[weak self] client, param, reply, notify in
            self?.navigationController?.pushViewController(ViewController(), animated: true)
            reply(nil,nil)
            return {}
        }
        webView.frame = view.bounds
        webView.navigationDelegate = self
        webView.load(URLRequest(url: URL(string: "http://192.168.2.2:8080")!))
        
//        webView.delegate = self
//        webView.loadRequest(URLRequest(url: URL(string: "http://192.168.2.2:8080")!))
        // Do any additional setup after loading the view.
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, webView.bridgePolicy(of: url) == .cancel {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if let url = request.url, webView.bridgePolicy(of: url) == .cancel {
            return false
        }
        return true
    }
    
    lazy var webView = WebView()
}

