//
//  FoldersAutocompleteProviders.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import Foundation
import AppKit

class TagsAutcompleteProvider: NSObject, NSTextFieldDelegate {
    
    private var isAutocompleting: Bool = false
    
    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        guard let input = textView.textStorage?.string else {
            return []
        }
        print("complete me: input='\(input)', words \(words), charRange \(charRange), index \(index)")
        do {
        } catch {
            print("error autocompleting \(input): \(error)")
        }
        return []
    }

    func controlTextDidChange(_ obj: Notification) {
        print("did change: \(obj)")
        let fieldEditor: NSTextView = obj.userInfo?["NSFieldEditor"] as! NSTextView
        if !self.isAutocompleting {
            self.isAutocompleting = true
            fieldEditor.complete(self)
            self.isAutocompleting = false
        }
    }
    
}
