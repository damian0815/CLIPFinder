//
//  FileCollectionViewItem.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import Cocoa

class FileCollectionViewItem: NSCollectionViewItem {
    
    static let identifier = NSUserInterfaceItemIdentifier("FileCollectionViewItem")

    @IBOutlet weak var selectionHighlightBox: NSBox!
    
    override var isSelected: Bool {
        didSet {
            self.selectionHighlightBox.isHidden = !isSelected
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.selectionHighlightBox.isHidden = true
    }
    
    override func prepareForReuse() {
        self.selectionHighlightBox.isHidden = true
    }
    
    func populate(with file: FileInfo) {
        self.textField?.stringValue = file.url.lastPathComponent
        let iconSize = CGSize(width: Int(self.imageView!.frame.size.width), height: Int(self.imageView!.frame.size.height))
        self.imageView?.image = NSImage.init(previewOfFileAtPath: file.url.path(percentEncoded: false), of: iconSize, asIcon: false)

    }
    
    
    
}
