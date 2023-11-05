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
    }
    
    func populate(with file: FileInfo) {
        self.fileInfo = file
        
        let fileName = file.url.lastPathComponent
        let tagsImage = TagsAndColorsProvider.shared.makeTagDotsLayer(for: file.url, height: self.textField!.bounds.height)
        //self.textField?.attributedStringValue = AttributedString(NSAttributedString(attachment: tagsImage))

        /*NSImage * pic = [[NSImage alloc] initWithContentsOfFile:@"/Users/Anne/Desktop/Sample.png"];
        NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:pic];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell: attachmentCell ];
        NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
        [[textView textStorage] appendAttributedString:attributedString];*/
        
        self.textField?.stringValue = file.url.lastPathComponent
        
        self.tags = TagsAndColorsProvider.shared.getTags(for: file.url)
        
        self.enqueueSlowDataFetch()
    }
    
    func enqueueSlowDataFetch() {
        let fileInfo = self.fileInfo!
        Task {
            if fileInfo != self.fileInfo {
                // reused
                return
            }
            let iconSize = CGSize(width: Int(self.imageView!.frame.size.width), height: Int(self.imageView!.frame.size.height))
            self.imageView?.image = NSImage.init(previewOfFileAtPath: fileInfo.url.path(percentEncoded: false), of: iconSize, asIcon: false)
            
        }
    }
    
    
    
}
