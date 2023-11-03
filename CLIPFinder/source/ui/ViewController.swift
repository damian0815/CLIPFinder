//
//  ViewController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import AppKit
import UniformTypeIdentifiers

class ViewController: NSViewController {

    @IBOutlet weak var filesCollectionView: NSCollectionView!
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var rootFolderTextField: NSTextField!
    
    var filesDataSource: NSCollectionViewDiffableDataSource<Int, FileInfo>? = nil
    
    var searchResultsProvider: SearchResultsProviderProtocol? = nil
    
    //let tagsAutocompleteProvider = TagsAutocompleteProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.filesCollectionView.register(
            NSNib(nibNamed: "FileCollectionViewItem", bundle: Bundle.main),
            forItemWithIdentifier: FileCollectionViewItem.identifier)
        
        // Do any additional setup after loading the view.
        
        self.filesDataSource = NSCollectionViewDiffableDataSource<Int, FileInfo>(collectionView: self.filesCollectionView, itemProvider: { cv, indexPath, fileInfo in
            let item = cv.makeItem(withIdentifier: FileCollectionViewItem.identifier, for: indexPath) as! FileCollectionViewItem
            item.populate(with: fileInfo)
            
            return item
        })
        self.filesDataSource!.apply(NSDiffableDataSourceSnapshot())
        
        //self.rootFolderTextField.delegate = self.rootFolderAutocompleteProvider
        let searchResultsProvider = BaseSearchResultsProvider { fileInfos in
            var snapshot = NSDiffableDataSourceSnapshot<Int, FileInfo>()
            snapshot.appendSections([0])
            snapshot.appendItems(fileInfos)
            await MainActor.run {
                self.filesDataSource!.apply(snapshot)
            }
        }
        self.searchResultsProvider = searchResultsProvider
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setRootFolder(_ url: URL) {
        self.rootFolderTextField.stringValue = url.path(percentEncoded: false)
        self.updateSearchResults()
    }
    
    @IBAction func rootFolderTextFieldDidChange(_ sender: Any) {
        self.updateSearchResults()
    }
    
    func updateSearchResults() {
        Task { @MainActor in
            await self.searchResultsProvider?.setRootFolder(self.rootFolderTextField.stringValue)
        }
    }
    

    @IBAction func openRootFolderButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.runModal()
        guard let url = openPanel.urls.first else { return }
        self.setRootFolder(url)
    }
    
    @IBAction func iconSizeSliderChanged(_ sender: Any) {
        let slider = sender as! NSSlider
        //let size = CGFloat(50 + log(slider.floatValue) * 300)
        let size = CGFloat(50 + slider.floatValue * 300)

        let layout = (self.filesCollectionView.collectionViewLayout as? NSCollectionViewFlowLayout) ?? NSCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        self.filesCollectionView.collectionViewLayout = layout
    }
}

