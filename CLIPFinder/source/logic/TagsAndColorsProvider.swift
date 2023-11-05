//
//  TagsAndColorsProvider.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 05.11.23.
//

import Foundation

struct Tag: Equatable, Hashable {
    let name: String
    let color: NSColor
}

class TagsAndColorsProvider {
    
    public static var shared = TagsAndColorsProvider()
    private static var tagsAndColors: [String:NSColor] = [:]
 
    func getTags(for url: URL) -> [Tag] {
        do {
            //test($0)
            let tagNames = try url.resourceValues(forKeys: [.tagNamesKey]).tagNames ?? []
            return tagNames.map { Tag(name: $0, color: Self.tagsAndColors[$0] ?? NSColor.gray) }
        } catch {
            print("error gettings tags for \(url): \(error)")
            return []
        }
    }
    
    
    private init() {
        
        if Self.tagsAndColors.isEmpty {
            Self.tagsAndColors = Self.getTagsAndColorsFromWorkspace()
            NotificationCenter.default.addObserver(forName: NSWorkspace.didChangeFileLabelsNotification, object: nil, queue: nil) { note in
                let workspace = note.object as! NSWorkspace
                Task { @MainActor in
                    Self.tagsAndColors = Self.getTagsAndColorsFromWorkspace(workspace)
                }
            }
        }
    }

    static func getTagsAndColorsFromWorkspace(_ workspace: NSWorkspace = NSWorkspace.shared) -> [String: NSColor] {
        let labels = NSWorkspace.shared.fileLabels
        let colors = NSWorkspace.shared.fileLabelColors
        let labelsAndColors = labels.enumerated().map { ($0.element, colors[$0.offset]) }
        return Dictionary(uniqueKeysWithValues: labelsAndColors)
    }
    
    func makeTagDotsLayer(for url: URL, height: CGFloat) -> CAShapeLayer {
        
        let tags = self.getTags(for: url)
        
        let dots = tags.filter { $0.color != NSColor.gray }
        
        
        let layer = CAShapeLayer()
        
        let dotDiameter = height - 2
        layer.bounds = CGRect(x: 0, y: 0, width: 1.0 + (CGFloat(dots.count) * 0.3) * dotDiameter, height: height)
        return layer
        
    }
    
}
