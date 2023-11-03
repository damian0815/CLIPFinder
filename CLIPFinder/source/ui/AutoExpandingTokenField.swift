//
//  AutoExpandingTokenField.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 03.11.23.
//

import Foundation

class AutoExpandingTokenField: NSTokenField {
 
    override var intrinsicContentSize: NSSize {
        let size = self.sizeThatFits(NSSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        let slightlyLargerSize = NSSize(width: size.width, height: size.height + 5)
        return slightlyLargerSize
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        self.invalidateIntrinsicContentSize()
    }
        
}
