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
    
    private var tagDotsLayer: CALayer? = nil
    
    private var fileInfo: FileInfo?
    private var tags: [Tag] = []
    
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
        self.tags = []
        self.fileInfo = nil
        self.imageView?.image = nil
        self.tagDotsLayer?.removeFromSuperlayer()
        self.tagDotsLayer = nil
    }
    
    func populate(with file: FileInfo) {
        self.fileInfo = file
        
        self.tagDotsLayer = TagsAndColorsProvider.shared.makeTagDotsLayer(for: file.url, height: self.textField?.frame.height ?? 0)
        if let tagDotsLayer = self.tagDotsLayer {
            //let inset: CGFloat = 10
            let xOrigin = (self.textField?.frame.midX ?? 0) - tagDotsLayer.bounds.width/2
            let yOrigin = (self.textField?.frame.midY ?? 0) - tagDotsLayer.bounds.height/2
            tagDotsLayer.frame = NSRect(x: xOrigin, y: yOrigin, width: tagDotsLayer.bounds.width, height: tagDotsLayer.bounds.height)
            tagDotsLayer.opacity = 0.7
            //tagDotsLayer.borderColor = NSColor.black.cgColor
            //tagDotsLayer.borderWidth = 1
            self.view.layer!.addSublayer(tagDotsLayer)
        }
        
        self.textField?.stringValue = file.url.lastPathComponent
        self.tags = TagsAndColorsProvider.shared.getTags(for: file.url)
        self.enqueueSlowDataFetch()
    }
    
    func enqueueSlowDataFetch() {
        let fileInfo = self.fileInfo!
        let size = CGSize(width: Int(self.imageView!.frame.size.width), height: Int(self.imageView!.frame.size.height))

        Task {
            await ThumbnailFetcher.shared.enqueueThumbnailFetch(for: fileInfo.url,
                                                                size: size,
                                                                isCancelled: { self.fileInfo != fileInfo },
                                                                result: { image in
                Task { @MainActor in
                    self.imageView?.image = image
                }
            })
        }
    }
    
    
    
}
