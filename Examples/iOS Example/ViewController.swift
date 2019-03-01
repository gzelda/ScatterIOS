//
//  ViewController.swift
//  iOS Example
//
//  Created by Yvo van Beek on 5/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {
    var server: TelegraphDemo!
    var serverSSL: TelegraphDemo!
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        server = TelegraphDemo()
        server.start()
        
        serverSSL = TelegraphDemo()
        serverSSL.startSSL()
        
        webView.delegate = self
        loadAddress()
    }
    
    
    func loadAddress() {
        // https://treasure.cchaingames.com/?refer=tpdappincome
        // https://betdice.one
        let myURL = URL(string:"http://192.168.2.100:8080")
        
        let myRequest = URLRequest(url: myURL!)
        webView.loadRequest(myRequest)
        print("Webpage Loaded Successfully")
    }


    public func webViewDidStartLoad(_ webView: UIWebView) {
        print("webViewDidStartLoad")
        //loadSpinner.isHidden = false
        //geekGunsLogo.isHidden = false
        //loadSpinner.startAnimating()
    }


    public func webViewDidFinishLoad(_ webView: UIWebView){
        print("webViewDidFinishLoad")
        //loadSpinner.stopAnimating()
        //loadSpinner.isHidden = true
        //geekGunsLogo.isHidden = true
    }


    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("didFailLoadWithError")
        //loadSpinner.stopAnimating()
        //loadSpinner.isHidden = true
        //geekGunsLogo.isHidden = true
        
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool{
        print("ABCd")
        return true
    }
}
