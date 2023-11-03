//
//  FileCollectionViewItem.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import Cocoa

class FileCollectionViewItem: NSCollectionViewItem {
    
    static let identifier = NSUserInterfaceItemIdentifier("FileCollectionViewItem")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func populate(with file: FileInfo) {
        self.textField?.stringValue = file.url.lastPathComponent
        self.imageView?.image = NSImage.init(previewOfFileAtPath: file.url.path(percentEncoded: false), of: self.imageView!.frame.size, asIcon: false)

    }
    
}
