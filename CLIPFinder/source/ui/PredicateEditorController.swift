//
//  PredicateEditorController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 11.11.23.
//

import AppKit

protocol PredicateEditorControllerDelegate {
    var undoManager: UndoManager? { get }
    func predicateEditorRulesDidChange(_ controller: PredicateEditorController)
}

class PredicateEditorController: NSObject, NSRuleEditorDelegate {
 
    let predicateEditor: NSPredicateEditor
    let addPredicateButton: NSButton
    
    var topLevelPredicate: NSPredicate? { self.predicateEditor.predicate }
    var lastKnownPredicate: NSPredicate? = nil
    var topLevelPredicateObservation: NSKeyValueObservation?
    
    var delegate: PredicateEditorControllerDelegate? = nil

    init(predicateEditor: NSPredicateEditor, addPredicateButton: NSButton) {
        self.predicateEditor = predicateEditor
        self.addPredicateButton = addPredicateButton
        
        super.init()

        self.lastKnownPredicate = self.predicateEditor.objectValue as? NSPredicate
        self.predicateEditor.delegate = self
    }
    
    func registerPredicateEditUndo(oldPredicate: NSPredicate?) {
        self.delegate?.undoManager?.registerUndo(withTarget: self.predicateEditor, handler: { predicateEditor in
            predicateEditor.objectValue = oldPredicate
            self.lastKnownPredicate = oldPredicate?.copy() as? NSPredicate
        })
    }
    
    // MARK: NSRuleEditorDelegate

    func ruleEditorRowsDidChange(_ notification: Notification) {
        
        let newPredicate = self.topLevelPredicate
        if newPredicate != self.lastKnownPredicate {
            //print("storing undo to \(self.lastKnownPredicate?.predicateFormat), userInfo: \(notification.userInfo)")
            registerPredicateEditUndo(oldPredicate: self.lastKnownPredicate?.copy() as? NSPredicate)
        }
        self.lastKnownPredicate = newPredicate?.copy() as? NSPredicate
        if newPredicate == nil {
            self.addPredicateButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add Search Predicates")
        } else {
            self.addPredicateButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove Search Predicates")
        }
        
        let totalRowHeight = CGFloat(self.predicateEditor.numberOfRows) * self.predicateEditor.rowHeight
        
        let frame = self.predicateEditor.frame
        self.predicateEditor.frame = CGRect(origin: frame.origin, size: NSSize(width: frame.width, height: totalRowHeight))
        self.delegate?.predicateEditorRulesDidChange(self)
    }
    
    func ruleEditor(_ editor: NSRuleEditor, numberOfChildrenForCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Int {
        // not called with NSPredicateEditor
        return 0
    }
    
    func ruleEditor(_ editor: NSRuleEditor, child index: Int, forCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Any {
        // not called with NSPredicateEditor
        return 0
    }
    
    func ruleEditor(_ editor: NSRuleEditor, displayValueForCriterion criterion: Any, inRow row: Int) -> Any {
        // not called with NSPredicateEditor
        return 0
    }
    
    
    func addPredicateButtonPressed(_ sender: Any) {
        if self.topLevelPredicate == nil {
            self.predicateEditor.addRow(self)
            //self.predicateEditor.objectValue = NSPredicate(format: "tag CONTAINS \"\"", argumentArray: nil)
            self.lastKnownPredicate = self.predicateEditor.objectValue as? NSPredicate
        } else {
            self.predicateEditor.objectValue = nil
            self.lastKnownPredicate = nil
        }
    }

    
}
