//
//  AppDelegate.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import Cocoa




@main
class AppDelegate: NSObject, NSApplicationDelegate {

    
    var viewController: ViewController { return NSApplication.shared.mainWindow!.contentViewController! as! ViewController }



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
    
    func application(_ application: NSApplication, open urls: [URL]) {
        self.viewController.setRootFolder(urls.first!)
    }

    @IBAction func openMenuItemSelected(_ sender: Any) {
        self.viewController.showOpenFolderDialog()
    }
    
}

