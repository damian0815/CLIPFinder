//
//  SearchResultsProvider.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 03.11.23.
//

import Foundation
import UniformTypeIdentifiers

struct FileInfo: Hashable {
    let url: URL
    let distance: Float
}
import Foundation


protocol SearchResultsProviderProtocol {
    
    var orderedResults: [FileInfo] { get async }
    var rootFolder: String { get async }
    func setRootFolder(_ folder: String) async
}

public func enumerateFolderContentsRecursive(_ rootURL: URL, types: Set<UTType>, partialResultsCallback: (([URL]) -> Void)? = nil) async -> [URL] {
    func getDirectoryContents(_ url: URL) -> [URL] {
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            return urls.filter {
                do {
                    guard let type = try $0.resourceValues(forKeys: [.contentTypeKey]).contentType else { return false }
                    return types.contains(where: { type.conforms(to: $0) })
                } catch {
                    return false
                }
            }
        } catch {
            print("error enumerating contents of \(url): \(error)")
            return []
        }
    }
    
    
    var result = [URL]()
    var queue = getDirectoryContents(rootURL)
    
    var lastPartialResultsTime = ContinuousClock.now
    let partialResultsInterval = ContinuousClock.Duration(secondsComponent: 1, attosecondsComponent: 0)

    
    
    while !queue.isEmpty {
        if Task.isCancelled {
            return []
        }
        let url = queue.removeFirst()
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory! {
                queue.append(contentsOf: getDirectoryContents(url))
            } else {
                result.append(url)
                // send partial results
                if let partialResultsCallback = partialResultsCallback, lastPartialResultsTime.duration(to: ContinuousClock.now) > partialResultsInterval {
                    partialResultsCallback(result)
                    lastPartialResultsTime = ContinuousClock.now
                }
            }
        } catch let error {
            Swift.print("couldn't get properties of \(url): \(error)")
        }
    }
    return result
}

actor BaseSearchResultsProvider: SearchResultsProviderProtocol {
    
    var orderedResults: [FileInfo] = []
    let newResultsCallback: ([FileInfo]) async -> Void
    private var enumerationTask: Task<Void, any Error>? = nil
    
    init(callback: @escaping ([FileInfo]) async -> Void) {
        self.newResultsCallback = callback
    }
    
    public private(set) var rootFolder: String = ""
    func setRootFolder(_ folder: String) async {
        self.rootFolder = folder
        self.updateResults()
    }
    
    private func updateResults() {
        if let existingTask = enumerationTask {
            existingTask.cancel()
        }
        
        self.enumerationTask = Task {
            let results = await enumerateFolderContentsRecursive(URL(filePath: self.rootFolder, directoryHint: .isDirectory), types: [UTType.image],
                                                   partialResultsCallback: { partialResults in
                //self.newResultsCallback(partialResults.map { FileInfo(path: $0.path(percentEncoded: false), distance: 0) })
            })
            await self.newResultsCallback(results.map { FileInfo(url: $0, distance: 0) })
        }
    }
    
}
