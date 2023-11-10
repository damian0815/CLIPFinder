//
//  TopLevelPredicateEditorRowTemplate.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 09.11.23.
//

import Cocoa

class TopLevelPredicate: NSCompoundPredicate {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(subpredicates: [NSPredicate] = []) {
        super.init(type: .and, subpredicates: subpredicates)
    }
    
    static func byAddingEmptyCompoundPredicate(to currentTopLevelPredicate: NSCompoundPredicate) -> TopLevelPredicate {
        let newSubpredicates = (currentTopLevelPredicate.subpredicates as! [NSPredicate]) + [NSCompoundPredicate(orPredicateWithSubpredicates: [])]
        return TopLevelPredicate(subpredicates: newSubpredicates)
    }
}

class TopLevelPredicateEditorRowTemplate: NSPredicateEditorRowTemplate {
    
    override func match(for predicate: NSPredicate) -> Double {
        if predicate is TopLevelPredicate {
            return 1
        } else {
            return 0
        }
    }
    
    
}
