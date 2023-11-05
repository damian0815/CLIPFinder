//
//  TagsTokenFieldController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 04.11.23.
//

import Foundation

class TagsTokenFieldController: NSObject, NSTokenFieldDelegate {
    
    let tokenField: NSTokenField
    
    private var tagsPerUrl: [URL:[Tag]] = [:]
    
    struct TagInfo {
        let tag: Tag
        let isCommon: Bool
    }
    
    enum TagSort {
        case Alphabetical
        case ByFrequency
        case Original
    }
    var sortOrder: TagSort {
        didSet { self.updateTagsInternal() }
    }
    
    init(tagsTokenField: NSTokenField) {
        self.tokenField = tagsTokenField
        self.sortOrder = .Alphabetical
    }
    
    func updateTags(forSelectedFiles selectedFiles: [FileInfo]) {
        
        let urls = selectedFiles.map { $0.url }
        
        self.tagsPerUrl = Dictionary(uniqueKeysWithValues: urls.map { ($0, TagsAndColorsProvider.shared.getTags(for: $0))
        })
        self.updateTagsInternal()
        
    }
    
    func updateTagsInternal() {
        let uniqueTags = tagsPerUrl.values.reduce([Tag]()) { allTags, thisTags in
            let newTags = thisTags.filter { !allTags.contains($0) }
            return allTags + newTags
        }
        let commonTags = uniqueTags.filter { uniqueTag in
            tagsPerUrl.values.allSatisfy { $0.contains(uniqueTag) }
        }
        let tagInfos = uniqueTags.map { TagInfo(tag: $0, isCommon: commonTags.contains($0)) }
        let sortedTagInfos = Self.sortTagInfos(tagInfos, sortOrder: self.sortOrder, tagsPerUrl: self.tagsPerUrl)
        self.tokenField.objectValue = sortedTagInfos
    }

    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        let tagInfo = representedObject as! TagInfo
        return tagInfo.tag.name
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        let tagInfo = representedObject as! TagInfo
        return tagInfo.isCommon ? .rounded : .plainSquared
    }
 
    func test(_ fileURL: URL) {
        
        // Create an instance of MDItem for the file or folder you want to get tags for.
        let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, fileURL as CFURL)
        
        // Use the kMDItemUserTags attribute to retrieve the Finder tags.
        if let tags = MDItemCopyAttribute(mdItem, kMDItemUserTags) as? [String] {
            print("Tags: \(tags)")
        } else {
            print("No tags found.")
        }
    }

    private static func sortTagInfos(_ tagInfos: [TagInfo], sortOrder: TagSort, tagsPerUrl: [URL: [Tag]]) -> [TagInfo] {
        
        switch sortOrder {
        case .Original:
            return tagInfos
        case .Alphabetical:
            return tagInfos.sorted { $0.tag.name < $1.tag.name }
        case .ByFrequency:
            let counts = Dictionary(uniqueKeysWithValues: tagInfos.map { tagInfo in
                let uniqueTag = tagInfo.tag
                return (uniqueTag, tagsPerUrl.filter { $0.value.contains(uniqueTag) } .count)
            })
            return tagInfos.sorted { counts[$0.tag]! > counts[$1.tag]! }
        }
        
    }
        
}
