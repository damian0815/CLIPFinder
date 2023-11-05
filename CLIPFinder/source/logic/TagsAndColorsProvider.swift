//
//  TagsAndColorsProvider.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 05.11.23.
//

import Foundation
import XAttr

struct Tag: Equatable, Hashable {
    let name: String
    let color: NSColor?
}

class TagsAndColorsProvider {
    
    public static var shared = TagsAndColorsProvider()
    private var colors: [NSColor] = []
    
    func getTags(for url: URL) -> [Tag] {
        do {
            //test($0)
            let tagsXattrName = "com.apple.metadata:_kMDItemUserTags"
            let tagsBinaryPropertyList = try url.extendedAttributeValue(forName: tagsXattrName)
            let tags:[String] = try PropertyListDecoder().decode([String].self, from: tagsBinaryPropertyList)
            return tags.map {
                let tagAndMaybeColor = $0.split(separator: "\n")
                if tagAndMaybeColor.count == 1 {
                    return Tag(name: $0, color: nil)
                }
                let colorIndex = Int(tagAndMaybeColor[1])!
                return Tag(name: String(tagAndMaybeColor[0]), color: self.colors[colorIndex])
            }
        } catch {
            //print("error gettings tags for \(url): \(error)")
            return []
        }
    }
    
    
    private init() {
        self.colors = NSWorkspace.shared.fileLabelColors
        NotificationCenter.default.addObserver(forName: NSWorkspace.didChangeFileLabelsNotification, object: nil, queue: nil) { note in
            self.colors = NSWorkspace.shared.fileLabelColors
        }
    }

    func makeTagDotsLayer(for url: URL, height: CGFloat) -> CAShapeLayer? {
        
        let tags = self.getTags(for: url)
        let dotColors = tags.compactMap { $0.color }
        if dotColors.isEmpty {
            return nil
        }

        let layer = CAShapeLayer()
        let inset = CGFloat(1)
        let dotDiameter = height - 2*inset
        let dotOverlap = 0.5
        layer.bounds = CGRect(x: 0, y: 0, width: 2*inset + (1 + CGFloat(dotColors.count-1) * dotOverlap) * dotDiameter, height: height)
        for (i,c) in dotColors.enumerated().reversed() {
            let startX = inset + CGFloat(i) * dotOverlap * dotDiameter
            let startY = inset
            let path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: dotDiameter, height: dotDiameter), transform: nil)
            let dotLayer = CAShapeLayer()
            dotLayer.backgroundColor = CGColor.clear
            dotLayer.path = path
            dotLayer.fillColor = c.cgColor
            //dotLayer.strokeColor = NSColor.gray.cgColor
            //dotLayer.lineWidth = 0.5
            dotLayer.frame = CGRect(x: startX, y: startY, width: dotDiameter, height: dotDiameter)
            layer.addSublayer(dotLayer)
        }
        return layer
        
    }
    
}
