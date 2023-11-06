//
//  ThumbnilFetcher.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 06.11.23.
//

import Foundation
import AsyncExtensions

actor ThumbnailFetcher {
    
    static var shared: ThumbnailFetcher = ThumbnailFetcher()
    
    struct FetchCommand {
        let url: URL
        let size: NSSize
        let isCancelled: () -> Bool
        let result: (NSImage?) -> Void
    }
    
    /// The producer side of the stream. Pass this to tasks that send commands to the database.
    let commandInput: AsyncStream<FetchCommand>.Continuation
    
    let processingTask: Task<Void, Never>
    
    init() {
        
        let (pipeInput, pipeOutput) = AsyncStream<FetchCommand>.pipe()
        self.commandInput = pipeInput
        
        self.processingTask = Task { @MainActor in
            for await command in pipeOutput {
                if command.isCancelled() {
                    continue
                }

                do {
                    print("making thumbnail with size \(command.size)")
                    let image = NSImage.init(previewOfFileAtPath: command.url.path(percentEncoded: false), of: command.size, asIcon: false)
                    print("made thumbnail with size \(command.size)")
                    command.result(image)
                } catch {
                    print("error making thumbnail with size \(command.size): \(error)")
                    command.result(nil)
                }
            }
            print("command queue done")
        }


    }
    
    func enqueueThumbnailFetch(for url: URL, size: NSSize, isCancelled: @escaping () -> Bool, result: @escaping (NSImage?) -> Void) {
        commandInput.yield(FetchCommand(url: url, size: size, isCancelled: isCancelled, result: result))
    }
    
}
