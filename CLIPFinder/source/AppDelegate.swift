//
//  AppDelegate.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let auth = MPFullDiskAccessAuthorizer()
        if auth.authorizationStatus() != .authorized {
            auth.requestAuthorization(completion: { status in
                print("Auth status: \(status)")
            })
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

